#!/usr/bin/env perl
# Decoder fuzz: feed random bytes / structurally-corrupted Native
# buffers to decode_block and assert the process never segfaults.
# The only acceptable outcomes are: clean decode or a Perl-level
# croak. ASAN-clean too (pair with xt/asan.t for tighter coverage).
#
# Skipped unless RELEASE_TESTING=1. Tweak FUZZ_DECODER_ITERS to scale.

use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

plan skip_all => 'set RELEASE_TESTING=1 to run decoder fuzz'
    unless $ENV{RELEASE_TESTING};

# Bound address space so a pathological decode allocation gets killed
# rather than driving the host into swap. RLIMIT_AS counts ALL virtual
# memory including the perl interpreter, shared libraries, and Perl's
# own arena slabs - a freshly-loaded perl already uses 100-300 MiB of
# VA on Linux. Set a generous cap (2 GiB); any legitimate decoder
# allocation stays well under it. The cap is what catches a pathological
# `Newx(N, ...)` for a corrupted N before it drives the host into swap.
my $cap_ok = eval {
    require BSD::Resource;
    BSD::Resource::setrlimit(
        BSD::Resource::RLIMIT_AS(),
        2 * 1024 * 1024 * 1024,
        2 * 1024 * 1024 * 1024);
    1;
};
plan skip_all => 'BSD::Resource not available; skipping unbounded fuzz'
    unless $cap_ok;

srand($ENV{FUZZ_DECODER_SEED} // 19937);

# 150 is the empirical safe ceiling under RLIMIT_AS=2 GiB with the
# default seed: enough iterations to exercise each seed shape several
# times without the cumulative Perl arena footprint plus a worst-case
# bounded allocation tripping the cap. Bump FUZZ_DECODER_ITERS in CI
# when adding more aggressive fuzz patterns.
my $iters = $ENV{FUZZ_DECODER_ITERS} // 150;

# Build a known-good seed block for each interesting type, then
# mutate. Both fully-random and surgically-perturbed inputs exercise
# different decoder paths.
my @seeds;

# Generate seed buffers we can corrupt later.
for my $type (
    'Int32', 'String', 'Array(Int64)', 'Nullable(String)',
    'Tuple(Int32, String)', 'Map(String, Int32)',
    'LowCardinality(String)', 'Variant(Int32, String)',
    'JSON', 'Dynamic',
) {
    my $enc = eval { ClickHouse::Encoder->new(columns => [['c', $type]]) };
    next unless $enc;
    my @rows;
    if ($type eq 'JSON') {
        @rows = ([{a => 1, b => "x"}], [{tags => [1,2,3]}], [undef]);
    } elsif ($type eq 'Dynamic') {
        @rows = ([1], ["x"], [[1,2]], [undef]);
    } elsif ($type =~ /^Variant/) {
        @rows = ([[0, 42]], [[1, "hi"]], [undef]);
    } elsif ($type =~ /Map/) {
        @rows = ([{a=>1,b=>2}], [{}]);
    } elsif ($type =~ /Tuple/) {
        @rows = ([[1,"x"]], [[2,"y"]]);
    } elsif ($type =~ /Array/) {
        @rows = ([[1,2,3]], [[]]);
    } elsif ($type eq 'Nullable(String)') {
        @rows = (['x'], [undef], ['y']);
    } else {
        @rows = ([1], [2], [3]);
    }
    my $bytes = eval { $enc->encode(\@rows) };
    push @seeds, $bytes if defined $bytes && length $bytes;
}

ok(@seeds, 'have ' . scalar(@seeds) . ' seed buffers');

my $crashed = 0;
my $survived = 0;

# Per-iteration size cap: skip fuzz buffers whose first varints would
# claim more memory than makes sense. Cheap pre-screen so we never
# even invoke decode_block on obvious OOM bait. Decoder hardening
# catches the rest; this is belt-and-suspenders.
sub _looks_safe {
    my $b = shift;
    return 0 if length($b) < 2;
    my @bytes = unpack 'C*', substr($b, 0, 20);
    my ($v, $shift) = (0, 0);
    for my $byte (@bytes) {
        $v |= ($byte & 0x7f) << $shift;
        return $v < 1024 * 1024 if !($byte & 0x80);
        $shift += 7;
        return 0 if $shift >= 64;
    }
    return 0;
}

for my $i (1 .. $iters) {
    my $bytes;
    if ($i % 3 == 0) {
        # Fully random bytes
        my $n = int(rand 200) + 1;
        $bytes = join '', map chr(int rand 256), 1..$n;
    } else {
        # Pick a seed, flip a few bytes / chop the end / inject zeros.
        my $seed = $seeds[int rand @seeds];
        $bytes = $seed;
        my $mode = int rand 4;
        if    ($mode == 0) {
            # Chop the buffer to a random prefix.
            $bytes = substr($bytes, 0, int rand length($bytes));
        }
        elsif ($mode == 1) {
            # Flip ~5% of bytes.
            my $n = int(length($bytes) * 0.05) + 1;
            for (1..$n) {
                my $pos = int rand length($bytes);
                substr($bytes, $pos, 1, chr(int rand 256));
            }
        }
        elsif ($mode == 2) {
            # Insert junk bytes mid-buffer.
            my $pos = int rand length($bytes);
            my $junk = join '', map chr(int rand 256), 1..int(rand 16)+1;
            substr($bytes, $pos, 0, $junk);
        }
        else {
            # Append trailing garbage.
            $bytes .= join '', map chr(int rand 256), 1..int(rand 32);
        }
    }
    next unless _looks_safe($bytes);
    # Wrap in a fresh sub call so the decoder's return value and any
    # mortal SVs created during decode are reclaimed before the next
    # iteration. Without this, mortals can pile up across hundreds
    # of iterations until the test process's heap is exhausted.
    eval { _try_decode($bytes); 1 };
    # "Out of memory" / "Killed" from RLIMIT_AS aborts the test process
    # and never returns to this branch - but catching the symbolic text
    # in $@ surfaces a real allocation gap if the eval somehow recovered
    # without the process dying.
    if ($@ && $@ =~ /Segmentation|stack overflow|Out of memory|Killed/i) {
        $crashed++;
        diag "CRASH at iter $i: $@";
    } else {
        $survived++;
    }
}

sub _try_decode {
    ClickHouse::Encoder->decode_block($_[0]);
    return;
}

is($crashed, 0, "$iters fuzz iterations: 0 crashes ($survived survived)");

# ---- structured adversarial blocks ------------------------------------
# Byte-mutating a valid seed cannot reach these shapes: a mutated wire
# count only matters if the bytes after it still parse, so a bumped
# "ntypes" lands on a garbage type name and is rejected before the count
# is used, and no mutation of a shallow seed yields a deeply nested type
# expression. Both hid real bugs from this file's mutation loop, so
# construct them deliberately.
{
    my $vi = sub { my $v = shift; my $o=''; while ($v >= 0x80) { $o .= chr(($v & 0x7f)|0x80); $v >>= 7 } $o . chr($v) };
    my $ls = sub { $vi->(length $_[0]) . $_[0] };
    my $u64 = sub { pack 'V2', $_[0] & 0xFFFFFFFF, ($_[0] >> 32) & 0xFFFFFFFF };

    my @adversarial;

    # Dynamic / JSON prefixes claiming far more variant types than there
    # are distinct kinds (the wire count indexed a 9-entry stack array).
    for my $n (2, 9, 10, 64, 300) {
        for my $name (qw(Bool Int64 String Array(Int64))) {
            push @adversarial, [
                "Dynamic prefix, $n x $name",
                $vi->(1) . $vi->(1) . $ls->('d') . $ls->('Dynamic')
                . $u64->(1) . $vi->(0) . $vi->($n)
                . ($ls->($name) x $n) . $u64->(0)
                . chr(int rand 256) . ("\0" x 64) ];
        }
        push @adversarial, [
            "JSON path prefix, $n x Bool",
            $vi->(1) . $vi->(1) . $ls->('j') . $ls->('JSON')
            . $u64->(0) . $vi->(0) . $vi->(1) . $ls->('a')
            . $u64->(1) . $vi->(0) . $vi->($n)
            . ($ls->('Bool') x $n) . $u64->(0)
            . chr(int rand 256) . ("\0" x 64) ];
    }

    # Deeply nested type expressions read off the wire.
    for my $depth (10, 100, 101, 5_000, 50_000) {
        for my $shape (['Array(', ')', 'Int32'],
                       ['Nullable(', ')', 'Int32'],
                       ['Tuple(', ')', 'Int32'],
                       ['Map(String, ', ')', 'Int32'],
                       ['LowCardinality(', ')', 'String']) {
            my ($open, $close, $leaf) = @$shape;
            push @adversarial, [
                "nested $open x $depth",
                $vi->(1) . $vi->(0) . $ls->('c')
                . $ls->(($open x $depth) . $leaf . ($close x $depth)) ];
        }
    }

    # Degenerate / contradictory block headers.
    push @adversarial,
        ['ncols=0 nrows=huge',   $vi->(0) . $vi->(1_000_000)],
        ['ncols=huge nrows=0',   $vi->(1_000_000) . $vi->(0)],
        ['ncols=1 nrows=huge',   $vi->(1) . $vi->(2**40) . $ls->('c') . $ls->('Int32')],
        ['LowCardinality dict_n huge',
            $vi->(1) . $vi->(1) . $ls->('c') . $ls->('LowCardinality(String)')
            . $u64->(1) . $u64->(1 << 9) . $u64->(2**40)],
        ['Variant disc out of range',
            $vi->(1) . $vi->(1) . $ls->('c') . $ls->('Variant(Int32, String)')
            . $u64->(0) . chr(200) . ("\0" x 32)],
        ['Array offset with bit 63 set',
            $vi->(1) . $vi->(1) . $ls->('c') . $ls->('Array(Int32)')
            . pack('V2', 0, 0x80000000) . ("\0" x 32)];

    my $adv_crashed = 0;
    for my $case (@adversarial) {
        my ($label, $bytes) = @$case;
        # Only a clean decode or a croak is acceptable; a segfault takes
        # the process down and never reaches the check below.
        eval { _try_decode($bytes); 1 };
        if ($@ && $@ =~ /Segmentation|stack overflow|Out of memory|Killed/i) {
            $adv_crashed++;
            diag "CRASH on adversarial case '$label': $@";
        }
    }
    is($adv_crashed, 0,
       scalar(@adversarial) . ' structured adversarial blocks: 0 crashes');
}

# ---- decode failures must not leak ------------------------------------
# decode_column holds the column AV, its SVs and a TypeInfo before it can
# know the buffer is short, and the streaming decoders drive that croak on
# every chunk boundary - so a leak here hits ordinary use, not just
# hostile input.
SKIP: {
    skip 'RSS check needs Linux /proc', 1 unless -r '/proc/self/status';
    # See t/hardening.t: under ASAN this measures the quarantine, not us.
    skip 'RSS growth measures the ASAN quarantine, not a leak', 1
        if ($ENV{LD_PRELOAD} // '') =~ /libasan|libclang_rt\.asan/
        || ($ENV{ASAN_OPTIONS} // '') ne '';
    my $rss = sub {
        open my $fh, '<', '/proc/self/status' or return 0;
        while (<$fh>) { return $1 if /^VmRSS:\s+(\d+)/ }
        return 0;
    };
    # Truncate each seed just short of complete, so the decoder gets deep
    # into the column before running out of bytes.
    my @truncated = map { substr($_, 0, length($_) - 1) } @seeds;
    for my $b (@truncated) { eval { _try_decode($b) } for 1 .. 200 }  # warm up
    my $before = $rss->();
    for my $b (@truncated) { eval { _try_decode($b) } for 1 .. 2_000 }
    my $growth = $rss->() - $before;
    cmp_ok($growth, '<', 8 * 1024,
           'no leak across ' . (2_000 * @truncated)
         . " caught decode failures (RSS grew ${growth} kB)");
}

done_testing();
