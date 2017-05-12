#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw(strftime);
use Test::More;
use Business::OnlinePayment;

my $login = $ENV{BOP_TEST_LOGIN};
my $password = $ENV{BOP_TEST_PASSWORD};
if (!$login) {
  plan skip_all => "no test credentials provided; set BOP_TEST_LOGIN and BOP_TEST_PASSWORD to test communication with the gateway.",
  1;
  exit(0);
}

plan tests => 2;

###
# Purchase
###
my %content = (
  login    => $login,
  password => $password,
  type           => "CC",
  description    => "Business::OnlinePayment::FirstDataGlobalGateway test",
  card_number    => '4111111111111111',
  cvv2           => '123',
  expiration     => '12/20',
  amount         => '1.00',
  first_name     => 'Tofu',
  last_name      => 'Beast',
  address        => '1234 Soybean Ln.',
  city           => 'Soyville',
  state          => 'CA', #where else?
  zip            => '94804',
);

my $tx = new Business::OnlinePayment( 'FirstDataGlobalGateway' );

$tx->content( %content,
              action => 'Normal Authorization' );

$tx->test_transaction(1);

$tx->submit;

is( $tx->is_success, 1, 'purchase' )
  or diag('Gateway error: '. $tx->error_message);

###
# Refund
###
my $auth = $tx->authorization;
$tx = new Business::OnlinePayment( 'FirstDataGlobalGateway' );
$tx->content( %content,
              action => 'Credit',
              authorization => $auth );
$tx->test_transaction(1);

$tx->submit;

is( $tx->is_success, 1, 'refund' )
  or diag('Gateway error: '. $tx->error_message);

1;
