#!/usr/bin/env perl
use warnings;
use strict;

use Test::Most;
use Data::Dumper;
use Time::HiRes qw(time);

use Data::Tumbler;

my $width = 4;
my $depth = 8;
my $expected = $width ** $depth; # 4^8=65536  4^9=262144

my @output;

my $tumbler = Data::Tumbler->new(
    consumer  => sub {
        my ($names, $values, $payload) = @_;
        push @output, [ $names, $values, $payload ];
    },
);

my $provider = sub {
    my %variants = map { $_ => $_ } 1..$width;
    return %variants;
};

my $start_time = time();
$tumbler->tumble(
    [   
        ($provider) x $depth
    ],
    [],
    [],
    { payload => '99 red ballons' },
);
my $dur = time() - $start_time;

is scalar @output, $expected,
    "should generate $expected results ($width ^ $depth)";

note "Generated $expected results (width $width, depth $depth) in $dur seconds";

done_testing;
