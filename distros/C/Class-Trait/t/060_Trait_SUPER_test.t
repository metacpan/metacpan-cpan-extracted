#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;

BEGIN {
    unshift @INC => ( 't/test_lib', '/test_lib' );
}

use Read;
use SyncRead;

can_ok( "Read", 'new' );
my $reader = Read->new();

isa_ok( $reader, 'Read' );

can_ok( "SyncRead", 'new' );
my $sync_reader = SyncRead->new();

isa_ok( $sync_reader, 'SyncRead' );
isa_ok( $sync_reader, 'Read' );

ok( $sync_reader->does('TSyncRead'), '... sync reader is a TSyncRead' );

# these should be the same
is( $reader->read(), $sync_reader->read(),
    '... these should be the same results' );

# now lets extract the actul trait and examine it

my $trait;
{
    no strict 'refs';

    # get the trait out
    $trait = ${"SyncRead::TRAITS"};
}

# check to see it is what we want it to be
isa_ok( $trait, 'Class::Trait::Config' );

# now examine the trait itself
is( $trait->name, 'TSyncRead', '... get the traits name' );

ok( eq_array( $trait->sub_traits, [] ), '... this should be empty' );
ok( eq_hash( $trait->conflicts, {} ), '... this should be empty' );
ok( eq_hash( $trait->overloads, {} ), '... this should be empty' );

ok( eq_hash( $trait->requirements, { read => 1 } ),
    '... this should not be empty' );

ok( eq_set( [ keys %{ $trait->methods } ], [ 'lock', 'unlock', 'read' ] ),
    '... this should not be empty' );

