#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Data::Pulp;

my $pulper = pulper
    case { $_ eq 'apple' } then { 'APPLE' }
    case { $_ eq 'banana' }
    case { $_ eq 'cherry' } then { 'CHERRY' }
    case { ref eq 'SCALAR' } then { 'SCALAR' }
    empty { 'empty' }
    nil { 'nil' }
    case { m/xyzzy/ } then { 'Nothing happens.' }
    default { 'default' }
;

# if_value
# if_type
# if_object

my $set = $pulper->prepare( [ qw/apple banana cherry/, '', undef, qw/xyzzy xyyxyzzyx grape/, \"" ] );

is( $set->next, 'APPLE' );
is( $set->next, 'CHERRY' );
is( $set->next, 'CHERRY' );
is( $set->next, 'empty' );
is( $set->next, 'nil' );
is( $set->next, 'Nothing happens.' );
is( $set->next, 'Nothing happens.' );
is( $set->next, 'default' );
is( $set->next, 'SCALAR' );
ok( ! $set->next );

cmp_deeply( [ $set->all ], [qw/ APPLE CHERRY CHERRY empty nil /, 'Nothing happens.', 'Nothing happens.', 'default', 'SCALAR' ] );

is( $pulper->prepare( 'apple' )->get, 'APPLE' );
