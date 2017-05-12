#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use_ok('Data::RandomPerson::Names::Female');

################################################################################
# Create a reference to the object
################################################################################

my $f = Data::RandomPerson::Names::Female->new();

is( ref($f), 'Data::RandomPerson::Names::Female' );

can_ok( $f, qw/new get size/ );

################################################################################
# How big is the list
################################################################################

is( $f->size(), 3944 );

################################################################################
# Should be able to pick 100 unique names in 500 tries
################################################################################

my %results;
my $counter = 0;

for ( 1 .. 500 ) {
    my $name = $f->get();

    unless ( $results{$name} ) {
        $results{$name}++;
        $counter++;
    }
}

ok( $counter >= 100 );

# vim: syntax=perl :
