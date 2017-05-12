#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use_ok('Data::RandomPerson::Names::Last');

################################################################################
# Create a reference to the object
################################################################################

my $l = Data::RandomPerson::Names::Last->new();

is( ref($l), 'Data::RandomPerson::Names::Last' );

can_ok( $l, qw/new get size/ );

################################################################################
# How big is the list
################################################################################

is( $l->size(), 88799 );

################################################################################
# Should be able to pick 100 unique names in 500 tries
################################################################################

my %results;
my $counter = 0;

for ( 1 .. 500 ) {
    my $name = $l->get();

    unless ( $results{$name} ) {
        $results{$name}++;
        $counter++;
    }
}

ok( $counter >= 100 );

# vim: syntax=perl :
