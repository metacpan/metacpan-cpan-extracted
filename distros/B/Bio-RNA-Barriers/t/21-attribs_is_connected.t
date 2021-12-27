#!perl -T
use 5.012;
use strict;
use warnings;

use Test::More;
use Test::NoWarnings;            # produces one additional test!
use File::Spec::Functions;

my $test_count = 12;
plan tests => $test_count + 1;            # +1 for Test::NoWarnings

use Bio::RNA::Barriers;

my $barfile = catfile qw(t data disconnected.bar);

open my $barfh, '<', $barfile
    or BAIL_OUT "failed to open test data file '$barfile'";

my $bar_results = Bio::RNA::Barriers::Results->new($barfh);

my %is_connected = (
    1  => 1,     2 => 0,     3 => 0,     4 => 0,
    5  => 0,     6 => 1,     7 => 1,     8 => 0,
    9  => 0,    10 => 1,    11 => 1,    12 => 1,
);

foreach my $i (1..$bar_results->min_count) {
    cmp_ok $bar_results->get_min($i)->is_connected,
           '==',
           $is_connected{$i},
           "connectedness of min $i",
           ;
}

