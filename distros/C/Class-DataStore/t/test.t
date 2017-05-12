#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 36;

use_ok( 'Class::DataStore' );

# basic operations
my $data = { one => 1, two => 2 };

my $store = Class::DataStore->new( $data );

is( $store->get( 'one' ), 1 );
is( $store->get( 'two' ), 2 );

is( $store->set( 'three', 3 ), 3 );
is( $store->get( 'three' ), 3 );

is( $store->one, 1 );
is( $store->two, 2 );
is( $store->three, 3 );

is( $store->four( 4 ), 4 );
is( $store->four, 4 );

is( $store->get( 'three' ), 3 );
is( $store->get( 'four' ), 4 );

is( $store->four( 'four' ), 'four' );
is( $store->four, 'four' );

# clear
is( $store->clear, 4 );

is( $store->one, undef );
is( $store->one( 1 ), 1 );
is( $store->one, 1 );

# exists
is( $store->exists( 'one' ), 1 );
is( $store->exists( 'onetwo' ), 0 );

# wantarray and get
my @array = qw( 1 2 3 );
$store->set( array => \@array );
my @returned = $store->get( 'array' );
is_deeply( \@returned, \@array );
my $returned = $store->get( 'array' );
is( ref $returned, 'ARRAY' );
is( @$returned[0], 1 );

@returned = $store->array;
is_deeply( \@returned, \@array );

@array = qw( 1 );
@returned = $store->get( 'one' );
is_deeply( \@returned, \@array );

my %hash = ( a => 1, b => 2 );
$store->set( hash => \%hash );
$returned = $store->get( 'hash' );
is( ref $returned, 'HASH' );
is( $returned->{a}, 1 );

my %returned = $store->get( 'hash' );
is( $returned{a}, 1 );

@returned = $store->get( 'hash' );
is( $returned[0], 'a' );
is( $returned[1], 1 );

# set and false/undef values
$store->five( undef );
is( $store->exists( 'five' ), 1 );
is( $store->get( 'five' ), undef );
is( $store->five, undef );

$store->set( 'six', '' );
is( $store->exists( 'six' ), 1 );
is( $store->get( 'six' ), '' );
is( $store->six, '' );




