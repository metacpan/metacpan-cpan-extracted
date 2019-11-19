#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Deep;

use Data::Dumper;

use_ok('CBOR::Free');

use CBOR::Free::Decoder;

my $plain_array = [];
my $plain_hash = {};

my $string = undef;
my $string_r = \$string;

my $out;

$out = CBOR::Free::encode(
    [ $plain_array, $plain_hash, $plain_array, $plain_hash, $string_r, $string_r ],
    preserve_references => 1,
    scalar_references => 1,
);


my $dec = CBOR::Free::Decoder->new();
$dec->preserve_references();
my $rt = $dec->decode($out);

cmp_deeply(
    $rt,
    [
        [],
        {},
        shallow( $rt->[0] ),
        shallow( $rt->[1] ),
        \undef,
        shallow( $rt->[4] ),
    ],
    'references are preserved',
);

done_testing;
