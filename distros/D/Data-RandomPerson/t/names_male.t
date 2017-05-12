#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use_ok('Data::RandomPerson::Names::Male');

################################################################################
# Create a reference to the object
################################################################################

my $m = Data::RandomPerson::Names::Male->new();

is( ref($m), 'Data::RandomPerson::Names::Male' );

can_ok( $m, qw/new get size/ );

################################################################################
# How big is the list
################################################################################

is( $m->size(), 1219 );

################################################################################
# Should be able to pick 100 unique names in 500 tries
################################################################################

my %results;
my $counter = 0;

for ( 1 .. 500 ) {
    my $name = $m->get();

    unless ( $results{$name} ) {
        $results{$name}++;
        $counter++;
    }
}

ok( $counter >= 100 );

# vim: syntax=perl :
