use strict;
use Test::More;

my @modules = qw(
    Data::Decode
    Data::Decode::Chain
    Data::Decode::Encode::Guess
    Data::Decode::Encode::Guess::JP
    Data::Decode::Encode::HTTP::Response
);

plan (tests => scalar @modules);
use_ok($_) for @modules;