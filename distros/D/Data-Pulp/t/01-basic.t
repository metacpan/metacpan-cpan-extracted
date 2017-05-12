#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Data::Pulp;
use Data::Pulp::Pulper;

my ($pulper);

$pulper = Data::Pulp::Pulper->parse( 
    case => 'apple' => then => sub {
        'APPLE';
    },
    case => banana =>
    case => cherry => then => sub {
        'CHERRY';
    },
    empty => sub {
        'empty';
    },
    nil => sub {
        'nil';
    },
    case => sub { m/xyzzy/ } => then => sub {
        'Nothing happens.',
    },
    default => sub {
        'default',
    },
);

is( $pulper->pulp( 'apple' ), 'APPLE' );
is( $pulper->pulp( 'banana' ), 'CHERRY' );
is( $pulper->pulp( 'cherry' ), 'CHERRY' );
is( $pulper->pulp( '' ), 'empty' );
is( $pulper->pulp( undef ), 'nil' );
is( $pulper->pulp( 'xyzzy' ), 'Nothing happens.' );
is( $pulper->pulp( 'xyyxyzzyx' ), 'Nothing happens.' );
is( $pulper->pulp( 'grape' ), 'default' );
