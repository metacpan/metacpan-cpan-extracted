#!perl

use strict;
use warnings;

package Utils::Tester;

use Moo;
with 'Business::GoCardless::Utils';

package main;

use Test::Most;
use Digest::SHA ();

use Business::GoCardless::Utils;

my $Utils = Utils::Tester->new;

my $body   = '{"events":[]}';
my $forged = Digest::SHA::hmac_sha256_hex( $body,'' );

ok( ! $Utils->signature_valid( $body,undef,$forged ),'! signature_valid with an undef secret' );
ok(
    ! $Utils->signature_valid( $body,[ 'new secret',undef ],$forged ),
    '! signature_valid with an undef secret in the list'
);
ok(
    $Utils->signature_valid(
        $body,[ 'new secret',undef ],Digest::SHA::hmac_sha256_hex( $body,'new secret' )
    ),
    '... which still accepts the other secret'
);

my $params = { action => 'paid' };
$params->{signature} = $Utils->sign_params( $params,'' );

ok( ! $Utils->signature_valid( $params,'' ),'! v1 signature_valid with an empty secret' );

done_testing();
