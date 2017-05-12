#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

use_ok('Data::RandomPerson::Choice');

################################################################################
# Create a reference to the object
################################################################################

my $c = Data::RandomPerson::Choice->new();

is( ref($c), 'Data::RandomPerson::Choice' );

can_ok( $c, qw/new add pick add_list size/ );

################################################################################
# Throw an error
################################################################################

eval { $c->pick(); };

like( $@, qr/^No data has been added to the list at / );

################################################################################
# Put something in and get it back
################################################################################

$c->add('this');

is( $c->pick(), 'this' );
is( $c->size(), 1 );

################################################################################
# Both choices should be picked
################################################################################

my %results;

$c->add('that');

is( $c->size(), 2 );

$results{ $c->pick() }++ for ( 1 .. 1000 );

ok( $results{this} > 0 );
ok( $results{that} > 0 );

$c->add_list( qw/a b c d e f/ );
is( $c->size(), 8 );

# vim: syntax=perl :
