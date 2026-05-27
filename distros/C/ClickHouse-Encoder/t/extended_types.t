use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;
use TestCH qw(skip_header read_varint);

# Bool ----------------------------------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','Bool']]);
    my $bin = $enc->encode([[1],[0],[''],[undef],['true']]);
    my $off = skip_header($bin);
    is(unpack('H*', substr($bin, $off, 5)), '0100000001',
       'Bool encodes truthy/falsy correctly');
}

# UUID ----------------------------------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','UUID']]);
    my $bin = $enc->encode([['550e8400-e29b-41d4-a716-446655440000']]);
    my $off = skip_header($bin);
    # First half  bytes 55 0e 84 00 e2 9b 41 d4 reversed -> d4 41 9b e2 00 84 0e 55
    # Second half bytes a7 16 44 66 55 44 00 00 reversed -> 00 00 44 55 66 44 16 a7
    is(unpack('H*', substr($bin, $off, 16)),
       'd4419be200840e5500004455664416a7',
       'UUID 16 bytes with each half reversed');
}
{
    # Round-trip a 16-byte raw input
    my $enc = ClickHouse::Encoder->new(columns => [['v','UUID']]);
    my $bytes16 = "\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10";
    my $bin = $enc->encode([[$bytes16]]);
    my $off = skip_header($bin);
    is(length(substr($bin, $off)), 16, 'UUID raw 16-byte input encodes 16 bytes');
}
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','UUID']]);
    eval { $enc->encode([['not-a-uuid']]) };
    like($@, qr/UUID requires/, 'invalid UUID length croaks');

    eval { $enc->encode([['ZZZZZZZZ-ZZZZ-ZZZZ-ZZZZ-ZZZZZZZZZZZZ']]) };
    like($@, qr/Invalid UUID hex/, 'non-hex UUID croaks');
}

# IPv4 ----------------------------------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','IPv4']]);
    my $bin = $enc->encode([['1.2.3.4'], ['255.255.255.255'], ['0.0.0.0']]);
    my $off = skip_header($bin);
    is(unpack('H*', substr($bin, $off,    4)), '04030201', 'IPv4 1.2.3.4 LE');
    is(unpack('H*', substr($bin, $off+4,  4)), 'ffffffff', 'IPv4 broadcast');
    is(unpack('H*', substr($bin, $off+8,  4)), '00000000', 'IPv4 zero');
}
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','IPv4']]);
    eval { $enc->encode([['256.0.0.0']]) };
    like($@, qr/Invalid IPv4/, 'IPv4 out-of-range octet croaks');
    eval { $enc->encode([['not.an.ip']]) };
    like($@, qr/Invalid IPv4/, 'IPv4 garbage croaks');
}

# IPv6 ----------------------------------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','IPv6']]);
    my $bin = $enc->encode([
        ['::1'],
        ['2001:db8::1'],
        ['fe80::1'],
    ]);
    my $off = skip_header($bin);
    is(unpack('H*', substr($bin, $off,     16)),
       '00000000000000000000000000000001', 'IPv6 ::1 network order');
    is(unpack('H*', substr($bin, $off+16,  16)),
       '20010db8000000000000000000000001', 'IPv6 2001:db8::1');
    is(unpack('H*', substr($bin, $off+32,  16)),
       'fe800000000000000000000000000001', 'IPv6 fe80::1');
}
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','IPv6']]);
    eval { $enc->encode([['not::valid::ip']]) };
    like($@, qr/Invalid IPv6/, 'IPv6 garbage croaks');
}

# Map ------------------------------------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['m','Map(String, UInt32)']]);
    my $bin = $enc->encode([
        [{a=>1, b=>2}],          # hashref
        [[]],                    # empty
        [[['x',10],['y',20]]],  # arrayref of pairs
    ]);
    ok(defined $bin, 'Map(String, UInt32) encodes hashref+arrayref+empty');
}
{
    my $enc = ClickHouse::Encoder->new(columns => [['m','Map(String, UInt32)']]);
    eval { $enc->encode([['scalar']]) };
    like($@, qr/hashref or arrayref/, 'Map with scalar croaks');
}

# Geo types -----------------------------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [
        ['p',  'Point'],
        ['ls', 'LineString'],
        ['mp', 'MultiPolygon'],
    ]);
    my $bin = $enc->encode([[
        [1.5, 2.5],
        [[0,0],[1,1],[2,0]],
        [[[[0,0],[1,0],[1,1],[0,0]]]],
    ]]);
    ok(defined $bin && length $bin > 0, 'Point/LineString/MultiPolygon encode');
}

# LowCardinality(String) ----------------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','LowCardinality(String)']]);
    my $bin = $enc->encode([['a'],['b'],['a'],['c'],['a']]);

    my $off = skip_header($bin);
    # version: UInt64 LE = 1
    is(unpack('Q<', substr($bin, $off, 8)), 1, 'LC version = 1');
    # flags: HasAdditionalKeys (1<<9) | UInt8 idx (0) = 0x200
    is(unpack('Q<', substr($bin, $off+8, 8)), 0x200, 'LC flags = HasAdditionalKeys|UInt8');
    # dict count: 4 (default + 3 distinct: a, b, c)
    is(unpack('Q<', substr($bin, $off+16, 8)), 4, 'LC dict count = 4');
}
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','LowCardinality(Nullable(String))']]);
    my $bin = $enc->encode([['x'],[undef],['y'],[undef],['x']]);
    ok(defined $bin && length $bin > 0, 'LC(Nullable(String)) encodes (nulls -> dict[0])');
}
{
    # Regression: LC(Nullable(String)) must distinguish "" from null.
    # In a Nullable LC column, dict slot 0 is the null sentinel, so ""
    # must get its own dict entry, not be aliased to slot 0.
    my $enc = ClickHouse::Encoder->new(columns => [['v','LowCardinality(Nullable(String))']]);
    my $bin = $enc->encode([[''], [undef], ['']]);
    my $off = skip_header($bin);
    # version + flags + dict_count = 24 bytes; index_bytes=1 (UInt8)
    my $dict_count = unpack('Q<', substr($bin, $off+16, 8));
    ok($dict_count >= 2, "dict has slot 0 (null) and a separate '' entry (count=$dict_count)");
    # The smoking gun is dict_count > 1: the empty string got its own
    # slot rather than colliding with slot 0 (the null sentinel).
    is($dict_count, 2, "expected dict count = 2 (null sentinel + '')");
}
{
    eval { ClickHouse::Encoder->new(columns => [['v','LowCardinality(Int32)']]) };
    like($@, qr/LowCardinality.*supports/i,
         'LowCardinality non-string inner rejected');
}
{
    # Regression: LowCardinality(FixedString(N)) dedup must canonicalize to
    # the N-byte wire form -- both over-length inputs that share an N-byte
    # prefix and under-length inputs that pad to the same bytes must collapse
    # into one dict slot.
    my $enc = ClickHouse::Encoder->new(columns => [['v','LowCardinality(FixedString(2))']]);
    my $bin = $enc->encode([
        ['abXX'], ['abYY'], ['abZZ'],   # truncate to "ab"
        ['cdEF'],                        # truncate to "cd"
        ['a'], ["a\0"],                  # both pad/encode to "a\0"
    ]);
    my $off = skip_header($bin);
    my $dict_count = unpack('Q<', substr($bin, $off+16, 8));
    is($dict_count, 4,
       "LC(FixedString(2)) dedups by canonical N bytes (default + 'ab' + 'cd' + 'a\\0')");
}

# Nested rejection -----------------------------------------------------------
{
    eval { ClickHouse::Encoder->new(columns => [['n','Nested(a UInt32, b String)']]) };
    like($@, qr/Nested.*not supported|flat columns/,
         'Nested rejected with helpful hint');
}

# encode_into ----------------------------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['x','UInt32']]);
    my $buf = '';
    $enc->encode_into(\$buf, [[1]]);
    my $len1 = length $buf;
    $enc->encode_into(\$buf, [[2],[3]]);
    cmp_ok(length($buf), '>', $len1, 'encode_into appends to existing scalar');

    eval { $enc->encode_into('not a ref', [[1]]) };
    like($@, qr/scalar reference/, 'encode_into rejects non-ref target');
}

# stream / streamer ----------------------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['x','UInt32'],['y','String']]);
    my @rows = map { [$_, "u$_"] } 1..25;
    my @sizes;
    $enc->stream(
        sub { shift @rows },
        sub { push @sizes, length(shift) },
        batch_size => 10,
    );
    is(scalar @sizes, 3, 'stream emits 3 chunks for 25 rows / batch 10');
    cmp_ok($sizes[0], '>', 50, 'first chunk has substantial size');
}
{
    my $enc = ClickHouse::Encoder->new(columns => [['x','UInt32']]);
    my $bytes = 0;
    my $st = $enc->streamer(sub { $bytes += length($_[0]) }, batch_size => 7);
    $st->push_row([$_]) for 1..20;
    $st->finish;
    cmp_ok($bytes, '>', 0, 'streamer push_row + finish writes bytes');
}
# (encoder-dropped-while-streamer-alive and writer-croak-recovery cases
#  are exhaustively covered in t/streamer-edge.t.)

# Decimal256 ----------------------------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','Decimal256(2)']]);
    my $bin = $enc->encode([['12345.67'], ['-99999.99']]);
    my $off = skip_header($bin);
    is(unpack('Q<', substr($bin, $off,    8)), 1234567,
       'Decimal256(2) lo limb for 12345.67');
    is(unpack('Q<', substr($bin, $off+8,  8)), 0, 'Decimal256 limb 1');
    is(unpack('Q<', substr($bin, $off+16, 8)), 0, 'Decimal256 limb 2');
    is(unpack('Q<', substr($bin, $off+24, 8)), 0, 'Decimal256 limb 3');
    # negative -9999999 -> two's complement 256-bit
    my $lo_neg = unpack('Q<', substr($bin, $off+32, 8));
    isnt($lo_neg, 0, 'Decimal256 negative has non-zero lo limb');
    is(unpack('Q<', substr($bin, $off+56, 8)), 0xFFFFFFFFFFFFFFFF,
       'Decimal256 negative high limb is all 1s (sign extension)');
}

# Variant -------------------------------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', 'Variant(Array(UInt8), String, UInt64)']],
    );
    my $bin = $enc->encode([
        [[0, [1, 2, 3]]],   # variant 0: Array(UInt8)
        [[1, 'hello']],     # variant 1: String
        [[2, 12345]],       # variant 2: UInt64
        [undef],            # null
    ]);
    ok(defined $bin && length $bin > 0, 'Variant encodes mixed types + null');

    # Wire layout: 1 col header + UInt64 mode (8) + 4 disc bytes + sub-cols
    my $off = skip_header($bin);
    is(unpack('Q<', substr($bin, $off, 8)), 0, 'Variant mode = 0');
    is(ord(substr($bin, $off+8,  1)), 0,   'discriminator row 0 -> Array');
    is(ord(substr($bin, $off+9,  1)), 1,   'discriminator row 1 -> String');
    is(ord(substr($bin, $off+10, 1)), 2,   'discriminator row 2 -> UInt64');
    is(ord(substr($bin, $off+11, 1)), 255, 'discriminator row 3 -> null');
}
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','Variant(String, UInt32)']]);
    eval { $enc->encode([[[5, 'oob']]]) };
    like($@, qr/out of range/, 'Variant index out of range croaks');

    eval { $enc->encode([['scalar']]) };
    like($@, qr/Variant value/, 'Variant non-arrayref croaks');

    eval { $enc->encode([[[0]]]) };
    like($@, qr/2-element/, 'Variant 1-element pair croaks');
}

# encode_columns ------------------------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [
        ['id',   'UInt32'],
        ['name', 'String'],
        ['tags', 'Array(String)'],
    ]);
    my $cols = {
        id   => [1, 2, 3],
        name => ['a', 'b', 'c'],
        tags => [['x','y'], [], ['z']],
    };
    my $rows = [
        [1, 'a', ['x','y']],
        [2, 'b', []],
        [3, 'c', ['z']],
    ];
    is($enc->encode_columns($cols), $enc->encode($rows),
       'encode_columns produces same bytes as encode');
}
{
    my $enc = ClickHouse::Encoder->new(columns => [['a','UInt32'],['b','UInt32']]);
    eval { $enc->encode_columns({a => [1,2], b => [1]}) };
    like($@, qr/has 1 rows.*expected 2|has 2 rows.*expected 1/,
         'encode_columns rejects ragged columns');
    eval { $enc->encode_columns({a => [1,2]}) };
    like($@, qr/missing column 'b'/, 'encode_columns rejects missing column');
}

# encode_to_handle -----------------------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','UInt32']]);
    my $expected = $enc->encode([[1],[2],[3]]);

    my $captured = '';
    open my $fh, '>', \$captured;
    binmode $fh;
    $enc->encode_to_handle($fh, [[1],[2],[3]]);
    close $fh;
    is($captured, $expected, 'encode_to_handle writes identical bytes to filehandle');
}

# Named Tuple ---------------------------------------------------------------
{
    my $a = ClickHouse::Encoder->new(columns => [['v','Tuple(a Int32, b String)']]);
    my $b = ClickHouse::Encoder->new(columns => [['v','Tuple(Int32, String)']]);
    my $rows = [[[42, 'hi']]];
    my $ba = $a->encode($rows);
    my $bb = $b->encode($rows);
    is(substr($ba, -7), substr($bb, -7),
       'Named Tuple data section matches positional');

    # Named Tuple accepts a hashref keyed by element names.
    my $hash_rows = [[{ a => 42, b => 'hi' }]];
    my $bh = $a->encode($hash_rows);
    is($ba, $bh, 'Named Tuple: hashref input encodes identically to arrayref');

    # Hashref against unnamed tuple croaks.
    eval { $b->encode([[{ a => 1, b => 'x' }]]) };
    like($@, qr/unnamed/, 'Hashref against unnamed Tuple croaks');

    # Missing key in hashref is treated as undef (column-level coercion).
    eval { $a->encode([[{ a => 99 }]]) };
    is($@, '', 'Named Tuple: missing hash key tolerated (becomes undef)');
}

# DateTime ISO 8601 with timezone offset -----------------------------------
{
    my $e = ClickHouse::Encoder->new(columns => [['v','DateTime']]);
    my $epoch = unpack('V', substr($e->encode([['2024-06-15 12:30:45']]), -4));

    is(unpack('V', substr($e->encode([['2024-06-15T12:30:45Z']]), -4)),
       $epoch, 'ISO 8601 Z (UTC) parses identical to plain');
    is(unpack('V', substr($e->encode([['2024-06-15T12:30:45+02:00']]), -4)),
       $epoch - 2*3600, 'ISO 8601 +02:00 offset applied');
    is(unpack('V', substr($e->encode([['2024-06-15T12:30:45-05:30']]), -4)),
       $epoch + 5*3600 + 30*60, 'ISO 8601 -05:30 offset applied');
    is(unpack('V', substr($e->encode([['2024-06-15T12:30:45+0200']]), -4)),
       $epoch - 2*3600, 'ISO 8601 compact +0200 offset applied');

    my $d64 = ClickHouse::Encoder->new(columns => [['v','DateTime64(3)']]);
    is(unpack('q<', substr($d64->encode([['2024-06-15T12:30:45.123+02:00']]), -8)),
       ($epoch - 2*3600) * 1000 + 123,
       'DateTime64(3) ISO 8601 with offset and fractional seconds');
}

# SimpleAggregateFunction --------------------------------------------------
{
    my $a = ClickHouse::Encoder->new(columns => [['v','SimpleAggregateFunction(sum, UInt64)']]);
    my $b = ClickHouse::Encoder->new(columns => [['v','UInt64']]);
    my $rows = [[42], [12345]];
    is(substr($a->encode($rows), -16), substr($b->encode($rows), -16),
       'SimpleAggregateFunction is wire-equivalent to inner type');
}

# Streamer::buffered_count / is_empty ---------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','UInt8']]);
    my $st  = $enc->streamer(sub {}, batch_size => 100);
    is($st->buffered_count, 0, 'buffered_count starts at 0');
    ok($st->is_empty,           'is_empty true at start');
    $st->push_row([$_]) for 1..7;
    is($st->buffered_count, 7, 'buffered_count tracks pushed rows');
    ok(!$st->is_empty,          'is_empty false with rows buffered');
    $st->reset;
    is($st->buffered_count, 0, 'buffered_count after reset');
    ok($st->is_empty,           'is_empty after reset');
}

# Streamer::reset ----------------------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['v','UInt8']]);
    my $bytes = 0;
    my $st = $enc->streamer(sub { $bytes += length($_[0]) }, batch_size => 100);
    $st->push_row([$_]) for 1..5;
    $st->reset;
    $st->finish;
    is($bytes, 0, 'reset() discards buffered rows; finish flushes nothing');

    $st->push_row([$_]) for 1..3;
    $st->finish;
    cmp_ok($bytes, '>', 0, 'streamer is reusable after reset()');
}

# BFloat16 (CH 24.x) -------------------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'BFloat16']]);
    my $bin = $enc->encode([[1.0], [0.5], [-1.0], ['NaN' + 0]]);
    my $tail = substr($bin, length($bin) - 8);
    is(unpack('H4', substr($tail, 0, 2)), '803f',  'BFloat16: 1.0 = 803f');
    is(unpack('H4', substr($tail, 2, 2)), '003f',  'BFloat16: 0.5 = 003f');
    is(unpack('H4', substr($tail, 4, 2)), '80bf',  'BFloat16: -1.0 = 80bf');
    like(unpack('H4', substr($tail, 6, 2)), qr/^c0[7f]f$/i,
         'BFloat16: NaN has quiet bit (sign-agnostic)');

    my $enc2 = ClickHouse::Encoder->new(columns => [['v', 'Nullable(BFloat16)']]);
    my $bin2 = $enc2->encode([[1.0], [undef]]);
    is(substr($bin2, length($bin2) - 2), "\x00\x00",
       'Nullable(BFloat16): null encodes as two zero bytes');
}

# validate_rows ------------------------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'UInt32']]);
    my $errs = $enc->validate_rows([[1], [2], 'oops', [3]]);
    is(scalar @$errs, 1, 'validate_rows: only the bare string is invalid');
    is($errs->[0]{row}, 2, 'validate_rows: identifies row 2');
    like($errs->[0]{error}, qr/arrayref/i, 'validate_rows: descriptive error');

    is_deeply($enc->validate_rows([[1], [2]]), [],
       'validate_rows: clean batch returns empty list');
}

# compressed_writer --------------------------------------------------------
{
    my @captured;
    my $w = ClickHouse::Encoder->compressed_writer(
        'gzip', sub { push @captured, $_[0] });
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'UInt32']]);
    my $st = $enc->streamer($w, batch_size => 1000);
    $st->push_row([$_]) for 1..5;
    $st->finish;
    is(scalar @captured, 1, 'compressed_writer: one block flushed');
    is(unpack('H4', substr($captured[0], 0, 2)), '1f8b',
       'compressed_writer: gzip magic bytes 1f 8b');

    my $raw_writer = sub { 1 };
    is(ClickHouse::Encoder->compressed_writer('raw', $raw_writer), $raw_writer,
       'compressed_writer raw: passthrough');
    is(ClickHouse::Encoder->compressed_writer(undef, $raw_writer), $raw_writer,
       'compressed_writer undef: passthrough');

    eval { ClickHouse::Encoder->compressed_writer('lzma', $raw_writer) };
    like($@, qr/Unknown compress mode/, 'compressed_writer rejects unknown modes');
    eval { ClickHouse::Encoder->compressed_writer('', $raw_writer) };
    like($@, qr/Unknown compress mode/, 'compressed_writer rejects empty mode');
}

# flatten_nested -----------------------------------------------------------
{
    my $cols = ClickHouse::Encoder->flatten_nested([
        ['events', 'Nested(t DateTime, kind String, n Nullable(UInt32))'],
        ['ts',     'DateTime'],
    ]);
    is_deeply($cols, [
        ['events.t',    'Array(DateTime)'],
        ['events.kind', 'Array(String)'],
        ['events.n',    'Array(Nullable(UInt32))'],
        ['ts',          'DateTime'],
    ], 'flatten_nested expands Nested columns to flat name.field Array(T) form');

    # Encoder accepts the flattened columns.
    my $enc = ClickHouse::Encoder->new(columns => $cols);
    is(scalar @{$enc->columns}, 4, 'flatten_nested: 4 flat columns from 2 input');

    # Pass-through for non-Nested columns.
    my $plain = ClickHouse::Encoder->flatten_nested([['v','UInt32']]);
    is_deeply($plain, [['v','UInt32']], 'flatten_nested: non-Nested unchanged');

    # Malformed Nested element croaks.
    eval { ClickHouse::Encoder->flatten_nested([['e','Nested(no_type_here)']]) };
    like($@, qr/'no_type_here' is not 'name Type'/,
         'flatten_nested: malformed Nested element croaks');
}

# encode_to_command --------------------------------------------------------
SKIP: {
    skip 'no /bin/cat to pipe through', 5 unless -x '/bin/cat';
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'UInt32']]);
    my $tmp = '/tmp/ch-encoder-cmd-test.bin';
    unlink $tmp;
    eval { $enc->encode_to_command(['/bin/sh', '-c', "cat > $tmp"], [[1],[2],[3]]) };
    is($@, '', 'encode_to_command: returns cleanly on success');
    ok(-s $tmp > 0, 'encode_to_command: pipe target received bytes');
    is(do { local $/; open my $fh, '<', $tmp; binmode $fh; <$fh> },
       $enc->encode([[1],[2],[3]]),
       'encode_to_command: piped bytes match in-memory encode');
    unlink $tmp;

    eval { $enc->encode_to_command(['/bin/false'], [[1]]) };
    like($@, qr/exit/, 'encode_to_command: non-zero child exit croaks');

    eval { $enc->encode_to_command('not-an-arrayref', [[1]]) };
    like($@, qr/cmd must be arrayref/, 'encode_to_command: cmd must be arrayref');

    eval { $enc->encode_to_command([], [[1]]) };
    like($@, qr/cmd must be non-empty/,
         'encode_to_command: empty cmd arrayref croaks (no uninit warning)');

    # SIGPIPE-on-early-child-exit must produce a trappable diagnostic,
    # not silently kill the parent with exit 141.
    my @big = map [$_], 1..200_000;
    eval { $enc->encode_to_command(['/bin/true'], \@big) };
    like($@, qr/short write|Broken pipe|exit/,
         'encode_to_command: early child exit produces eval-catchable error');
}

# flatten_nested: Nested() with whitespace-only body must croak, not
# silently drop the column.
{
    eval { ClickHouse::Encoder->flatten_nested([['e', 'Nested(   )']]) };
    like($@, qr/has no elements/,
         'flatten_nested: empty Nested() body croaks');
}

done_testing();
