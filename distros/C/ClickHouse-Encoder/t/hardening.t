#!/usr/bin/env perl
# Regression tests for the decoder/encoder hardening fixes: bugs that were
# reachable from wire data (a malicious or merely corrupt ClickHouse
# response) or that silently wrote wrong data to the server.
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;
use ClickHouse::Encoder;

sub varint { my $v = shift; my $o=''; while ($v >= 0x80) { $o .= chr(($v & 0x7f)|0x80); $v >>= 7 } $o . chr($v) }
sub lenpfx { my $s = shift; varint(length $s) . $s }
sub u64    { pack 'V2', $_[0] & 0xFFFFFFFF, ($_[0] >> 32) & 0xFFFFFFFF }

# ---- 1. Oversized variant type list in a Dynamic prefix ---------------
# wire_slots was ntypes+1 from the wire, used to index a 9-entry stack
# array; nothing rejected duplicate type names.
{
    for my $ntypes (10, 60, 200) {
        my $col = u64(1) . varint(0) . varint($ntypes)
                . (lenpfx('Bool') x $ntypes) . u64(0)
                . chr(0) . ("\0" x 32);
        my $blk = varint(1) . varint(1) . lenpfx('d') . lenpfx('Dynamic') . $col;
        eval { ClickHouse::Encoder->decode_block($blk) };
        like($@, qr/variant types declared but only \d+ are distinct/,
             "Dynamic prefix with $ntypes duplicate type names is rejected");
    }
}

# Same shape through the JSON path (a separate copy of the loop).
{
    my $ntypes = 60;
    my $col = u64(0) . varint(0) . varint(1) . lenpfx('a')
            . u64(1) . varint(0) . varint($ntypes)
            . (lenpfx('Bool') x $ntypes) . u64(0)
            . chr(0) . ("\0" x 32);
    my $blk = varint(1) . varint(1) . lenpfx('j') . lenpfx('JSON') . $col;
    eval { ClickHouse::Encoder->decode_block($blk) };
    like($@, qr/declares \d+ variant types but only \d+ are distinct/,
         'JSON path with duplicate variant type names is rejected');
}

# A well-formed multi-kind Dynamic column still round-trips - the fix must
# not reject legitimate prefixes with several distinct types.
{
    my $enc = ClickHouse::Encoder->new(columns => [['d', 'Dynamic']]);
    my $bytes = $enc->encode([[1], ['x'], [[1, 2]], [undef], [1.5]]);
    my $blk = ClickHouse::Encoder->decode_block($bytes);
    is($blk->{nrows}, 5, 'multi-kind Dynamic column still round-trips');
    is($blk->{columns}[0]{values}[1], 'x', 'Dynamic string value survives');
}

# ---- 2. Type nesting depth --------------------------------------------
{
    my $deep = sub { my $d = shift; ('Array(' x $d) . 'Int32' . (')' x $d) };

    ok(eval { ClickHouse::Encoder->new(columns => [['c', $deep->(50)]]); 1 },
       'nesting well inside the limit is accepted');

    eval { ClickHouse::Encoder->new(columns => [['c', $deep->(200)]]) };
    like($@, qr/Type nesting too deep/, 'over-deep type from new() croaks');

    # The one that mattered: the type string comes off the wire.
    my $blk = varint(1) . varint(0) . lenpfx('c') . lenpfx($deep->(20_000));
    eval { ClickHouse::Encoder->decode_block($blk) };
    like($@, qr/Type nesting too deep/,
         'over-deep type from a Native block croaks instead of segfaulting');
}

# ---- 3. No leak on the decode error path ------------------------------
SKIP: {
    skip 'RSS check needs Linux /proc', 1 unless -r '/proc/self/status';
    # Under ASAN this measures the quarantine (freed blocks held back
    # rather than reused), which climbs to its cap and plateaus.
    # LeakSanitizer is the right tool there.
    skip 'RSS growth measures the ASAN quarantine, not a leak', 1
        if ($ENV{LD_PRELOAD} // '') =~ /libasan|libclang_rt\.asan/
        || ($ENV{ASAN_OPTIONS} // '') ne '';
    my $rss = sub {
        open my $fh, '<', '/proc/self/status' or return 0;
        while (<$fh>) { return $1 if /^VmRSS:\s+(\d+)/ }
        return 0;
    };
    # 199 well-formed String values then the buffer ends, so decode_column
    # holds the column AV, 199 SVs and a TypeInfo when it croaks.
    my $good = join '', map { lenpfx("value-$_-padding-padding") } 1 .. 199;
    my $blk  = varint(1) . varint(200) . lenpfx('s') . lenpfx('String') . $good;
    eval { ClickHouse::Encoder->decode_block($blk) };
    like($@, qr/buffer truncated/, 'truncated block croaks as expected');

    eval { ClickHouse::Encoder->decode_block($blk) } for 1 .. 5_000;  # warm up
    my $before = $rss->();
    eval { ClickHouse::Encoder->decode_block($blk) } for 1 .. 20_000;
    my $growth = $rss->() - $before;
    # Allow a few MB of arena noise; a per-iteration leak blows past it.
    cmp_ok($growth, '<', 8 * 1024,
           "no leak over 20k caught decode failures (RSS grew ${growth} kB)")
        or diag("leaked roughly " . int($growth * 1024 / 20_000) . " bytes per failure");
}

# ---- 4. Out-of-range values croak instead of wrapping -----------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['d', 'Date']]);
    # Boundaries stay valid.
    ok(eval { $enc->encode([['1970-01-01'], ['2149-06-06']]); 1 },
       'Date range endpoints still encode');
    for my $bad ('1969-12-31', '2200-01-01', 70_000, -1) {
        eval { $enc->encode([[$bad]]) };
        like($@, qr/Date out of range/, "Date '$bad' croaks (was silently wrapping)");
    }

    my $d32 = ClickHouse::Encoder->new(columns => [['d', 'Date32']]);
    ok(eval { $d32->encode([['1969-12-31'], ['2200-01-01']]); 1 },
       'Date32 still accepts dates outside the Date range');
    eval { $d32->encode([[2**40]]) };
    like($@, qr/Date32 out of range/, 'Date32 beyond Int32 croaks');
}

{
    my $enc = ClickHouse::Encoder->new(columns => [['t', 'DateTime64(9)']]);
    ok(eval { $enc->encode([['2262-04-11 23:47:16']]); 1 },
       'DateTime64(9) accepts the last representable second');
    for my $bad ('2263-01-01 00:00:00', '9999-12-31 23:59:59') {
        eval { $enc->encode([[$bad]]) };
        like($@, qr/DateTime64\(9\) out of range/,
             "DateTime64(9) '$bad' croaks (was wrapping negative)");
    }
    # Lower precision still reaches far-future dates.
    my $p3 = ClickHouse::Encoder->new(columns => [['t', 'DateTime64(3)']]);
    ok(eval { $p3->encode([['9999-12-31 23:59:59']]); 1 },
       'DateTime64(3) still handles year 9999');
}

{
    eval { ClickHouse::Encoder->new(
        columns => [['e', "Enum8('a' = 18446744073709551617)"]]) };
    like($@, qr/out of range for Enum8/,
         'Enum value that overflowed a C long is rejected');
    ok(eval { ClickHouse::Encoder->new(
        columns => [['e', "Enum8('a' = 1, 'b' = -128, 'c' = 127)"]]); 1 },
       'Enum8 boundary values still accepted');

    eval { ClickHouse::Encoder->new(columns => [['f', 'FixedString(99999999999)']]) };
    like($@, qr/FixedString/, 'FixedString length that overflowed atoi is rejected');
}

# ---- 4b. JSON object nesting depth ------------------------------------
# flatten_json_hash recurses once per level. Wire data reaches it too: a
# path name with N dotted segments decodes to an N-deep hash, so
# re-encoding a hostile block recursed just as far and blew the C stack.
{
    my $enc = ClickHouse::Encoder->new(columns => [['j', 'JSON']]);
    my $deep = sub { my $h = 'leaf'; $h = { n => $h } for 1 .. $_[0]; $h };

    ok(eval { $enc->encode([[ $deep->(400) ]]); 1 },
       'JSON nesting inside the limit encodes');
    eval { $enc->encode([[ $deep->(100_000) ]]) };
    like($@, qr/nesting deeper than/,
         'over-deep JSON object croaks instead of segfaulting');

    # The wire route: one path of N dotted segments -> N-deep hash.
    my $path = join '.', ('a') x 100_000;
    my $col = u64(0) . varint(0) . varint(1) . lenpfx($path)
            . u64(1) . varint(0) . varint(1) . lenpfx('Int64') . u64(0)
            . chr(0) . u64(7) . u64(0);
    my $blk = varint(1) . varint(1) . lenpfx('j') . lenpfx('JSON') . $col;
    my $decoded = eval { ClickHouse::Encoder->decode_block($blk) };
    ok($decoded, 'deeply dotted JSON path decodes');
    eval { $enc->encode([[ $decoded->{columns}[0]{values}[0] ]]) };
    like($@, qr/nesting deeper than/,
         're-encoding a hostile block croaks instead of segfaulting');
}

# ---- 5. Corrupt block header ------------------------------------------
{
    my $blk = varint(0) . varint(1_000_000);
    eval { ClickHouse::Encoder->decode_block($blk) };
    like($@, qr/exceeds remaining buffer/,
         'a row count with no bytes behind it is rejected');

    # A zero-column schema is degenerate but legal, and do_encode writes
    # its row count independently - the decoder must still read back what
    # this encoder emits rather than rejecting ncols==0 outright.
    my $empty = ClickHouse::Encoder->new(columns => [])->encode([]);
    my $back  = eval { ClickHouse::Encoder->decode_block($empty) };
    is($@, '', 'zero-column block from our own encoder still decodes')
        or diag($@);
    is($back->{ncols}, 0, 'zero-column block reports ncols=0');
}

# ---- 6. Endpoint host validation --------------------------------------
{
    for my $bad ('evil.com@internal.db', 'host:8123', 'a/b', "x\ny", '') {
        eval { ClickHouse::Encoder::_check_endpoint({ host => $bad }) };
        like($@, qr/host must not contain/, "host '$bad' rejected");
    }
    for my $good ('localhost', '10.0.0.1', 'db.example.com', '[::1]',
                  '[2001:db8::1]') {
        ok(eval { ClickHouse::Encoder::_check_endpoint({ host => $good }); 1 },
           "host '$good' accepted");
    }
    my ($url) = ClickHouse::Encoder::_http_url_headers('select 1', host => '[::1]');
    like($url, qr{\Qhttp://[::1]:8123/\E}, 'IPv6 literal keeps its brackets in the URL');
}

# ---- 7. decompress_native_block size cap ------------------------------
{
    my $payload = 'x' x 4;
    # tag 0x02 (stored), compressed_size = 9 + 4, uncompressed_size = 4 GiB - 1
    my $hdr   = pack('C V V', 0x02, 9 + length($payload), 0xFFFFFFFF);
    my $framed = ("\0" x 16) . $hdr . $payload;
    eval { ClickHouse::Encoder->decompress_native_block(
        $framed, hasher => undef) };
    like($@, qr/exceeds max_size/,
         'block claiming a 4 GiB uncompressed size is rejected');

    # Round-trip through the real framing still works.
    my $enc = ClickHouse::Encoder->new(columns => [['i', 'Int32']]);
    my $bytes = $enc->encode([[1], [2]]);
    my $comp  = ClickHouse::Encoder->compress_native_block($bytes, mode => 'none');
    is(ClickHouse::Encoder->decompress_native_block($comp), $bytes,
       'normal compressed block still round-trips');
}

done_testing();
