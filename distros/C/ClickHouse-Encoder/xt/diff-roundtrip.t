#!/usr/bin/env perl
# For every doc/json-research/*.bin fixture, decode then re-encode
# and byte-diff against the original. Catches decode/re-encode
# asymmetry that pure round-trip tests miss (encode-then-decode
# cancels out symmetric bugs in both directions; decoding a fixture
# captured FROM CH and then re-encoding to bytes the same fixture
# is the only way to prove both sides agree with the server).
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

plan skip_all => 'set RELEASE_TESTING=1 to run diff-roundtrip tests'
    unless $ENV{RELEASE_TESTING};

my @fixtures = sort glob('doc/json-research/*.bin');
plan skip_all => 'no doc/json-research/*.bin fixtures found'
    unless @fixtures;

for my $path (@fixtures) {
    my ($name) = $path =~ m{([^/]+)\.bin\z};
    open my $fh, '<:raw', $path or do {
        fail("open $path: $!");
        next;
    };
    local $/;
    my $original = <$fh>;
    close $fh;

    # Decode the fixture; not every fixture is a self-contained block
    # (some are partial wire snippets used in doc/wire-format research).
    # Skip cleanly if decode itself fails - the round-trip claim only
    # makes sense for fixtures the decoder can read.
    my $blk = eval { ClickHouse::Encoder->decode_block($original) };
    if ($@ || !defined $blk) {
      SKIP: { skip "fixture $name not a complete block: $@", 1; }
        next;
    }

    # Rebuild an encoder from the block's column shape and re-encode
    # the row data. for_native_bytes uses decode_block under the hood
    # so we know the columns roundtrip; this confirms the bytes do too.
    my $enc = ClickHouse::Encoder->for_native_bytes($original);

    # Reconstruct rows from the column-major block. JSON/Dynamic
    # columns store hashref/arrayref values that round-trip via the
    # standard row-major encode path.
    my @rows;
    for my $r (0 .. $blk->{nrows} - 1) {
        push @rows, [ map $_->{values}[$r], @{ $blk->{columns} } ];
    }
    my $reencoded = $enc->encode(\@rows);

    my $ok = ($reencoded eq $original);
    ok($ok, "byte-exact decode/re-encode round-trip: $name");
    unless ($ok) {
        diag(sprintf("size: original=%d, reencoded=%d",
                     length($original), length($reencoded)));
        # Show first diverging byte pair for forensic context.
        my $min = length($original) < length($reencoded)
                ? length($original) : length($reencoded);
        for my $i (0 .. $min - 1) {
            next if substr($original, $i, 1) eq substr($reencoded, $i, 1);
            diag(sprintf("first diff at byte %d: 0x%02x vs 0x%02x",
                         $i, ord(substr($original, $i, 1)),
                             ord(substr($reencoded, $i, 1))));
            last;
        }
    }
}

done_testing();
