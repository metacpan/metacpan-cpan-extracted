#!perl

use strict;
use warnings;

package Utils::Tester;

use Moo;
with 'Business::GoCardless::Utils';

package main;

use Test::Most;

use Business::GoCardless::Utils;

my $Utils = Utils::Tester->new;

# 1000 leaves that each flatten with a 1100 byte key: about 1.1 MB
my $params = { ( 'a' x 1100 ) => [ ( 0 ) x 1000 ] };
$params->{signature} = $Utils->sign_params( $params,'secret' );

ok(
    ! $Utils->signature_valid( $params,'secret' ),
    '! signature_valid for params that flatten to more than 1 MiB'
);

{
    local $Business::GoCardless::Utils::max_legacy_params_size = 0;
    ok( $Utils->signature_valid( $params,'secret' ),'... unless the limit is disabled' );
}

# empty containers flatten to nothing, but their keys are still built
my $empty = { ( 'a' x 1100 ) => [ ( {} ) x 1000 ] };
$empty->{signature} = $Utils->sign_params( $empty,'secret' );

ok(
    ! $Utils->signature_valid( $empty,'secret' ),
    '! signature_valid for params whose keys alone come to more than 1 MiB'
);

done_testing();
