#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Data::Pulp;
use Data::Pulp::Pulper;

my ($pulper, $set);

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

$set = Data::Pulp::Set->new( 
    pulper => $pulper,
    source => [ qw/apple banana cherry/, '', undef, qw/xyzzy xyyxyzzyx grape/ ],
);

is( $set->next, 'APPLE' );
is( $set->next, 'CHERRY' );
is( $set->next, 'CHERRY' );
is( $set->next, 'empty' );
is( $set->next, 'nil' );
is( $set->next, 'Nothing happens.' );
is( $set->next, 'Nothing happens.' );
is( $set->next, 'default' );
ok( ! $set->next );

cmp_deeply( [ $set->all ], [qw/ APPLE CHERRY CHERRY empty nil /, 'Nothing happens.', 'Nothing happens.', 'default' ] );
