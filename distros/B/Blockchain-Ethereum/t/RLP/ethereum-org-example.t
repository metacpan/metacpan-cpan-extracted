#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Blockchain::Ethereum::RLP;

subtest "ethereum org example encode" => sub {
    my $rlp = Blockchain::Ethereum::RLP->new();

    my $dog   = unpack "H*", "dog";
    my $cat   = unpack "H*", "cat";
    my $lorem = unpack "H*", "Lorem ipsum dolor sit amet, consectetur adipisicing elit";

    my $encoded  = $rlp->encode($dog);
    my $expected = "83$dog";
    is(unpack("H*", $encoded), $expected, "correct encoding for dog");

    my $decoded = $rlp->decode($encoded);
    is_deeply $decoded, '0x' . $dog, "correct decoding for dog";

    my $cat_dog = [$cat, $dog];
    $encoded  = $rlp->encode($cat_dog);
    $expected = "c883@{[$cat]}83$dog";
    is(unpack("H*", $encoded), $expected, "correct encoding for cat dog");

    $decoded = $rlp->decode($encoded);
    is_deeply $decoded, ['0x' . $cat, '0x' . $dog], "correct decoding for cat dog";

    $encoded  = $rlp->encode('');
    $expected = "80";
    is(unpack("H*", $encoded), $expected, "correct encoding for empty string");

    $decoded = $rlp->decode($encoded);
    is_deeply $decoded, '0x', "correct decoding for empty string";

    $encoded  = $rlp->encode([]);
    $expected = "c0";
    is(unpack("H*", $encoded), $expected, "correct encoding for empty array reference");

    $decoded = $rlp->decode($encoded);
    is_deeply $decoded, [], "correct decoding for empty array reference";

    $encoded  = $rlp->encode('0');
    $expected = '80';
    is(unpack("H*", $encoded), $expected, "correct encoding for empty = integer 0");

    $decoded = $rlp->decode($encoded);
    is_deeply $decoded, '0x', "correct decoding for empty array empty = integer 0";

    $encoded = $rlp->encode('0x0');
    # 0 is set as null
    $expected = '80';
    is(unpack("H*", $encoded), $expected, "correct encoding for hexadecimal integer 0");

    $decoded = $rlp->decode($encoded);
    is_deeply $decoded, '0x', "correct decoding for hexadecimal integer 0";

    $encoded  = $rlp->encode(sprintf("0x%x", 15));
    $expected = '0f';
    is(unpack("H*", $encoded), $expected, "correct encoding for hexadecimal integer 15");

    $decoded = $rlp->decode($encoded);
    is_deeply $decoded, sprintf("0x%x", 15), "correct decoding for hexadecimal integer 15";

    $encoded  = $rlp->encode(sprintf("0x%x", 1024));
    $expected = '820400';
    is(unpack("H*", $encoded), $expected, "correct encoding for hexadecimal integer 1024");

    $decoded = $rlp->decode($encoded);
    is_deeply $decoded, sprintf("0x%x", 1024), "correct decoding for hexadecimal integer 1024";

    $encoded  = $rlp->encode([[], [[]], [[], [[]]]]);
    $expected = "c7c0c1c0c3c0c1c0";
    is(unpack("H*", $encoded), $expected, "correct encoding for set theoretical representation of three");

    $decoded = $rlp->decode($encoded);
    is_deeply $decoded, [[], [[]], [[], [[]]]], "correct decoding for set theoretical representation of three";

    $encoded  = $rlp->encode($lorem);
    $expected = "b838$lorem";
    is(unpack("H*", $encoded), $expected, "correct encoding for lorem");

    $decoded = $rlp->decode($encoded);
    is_deeply $decoded, '0x' . $lorem, "correct decoding for lorem";
};

done_testing;
