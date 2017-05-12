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
my %content = (
  login    => $login,
  password => $password,
  action         => "Normal Authorization",
  type           => "CC",
  description    => "Business::OnlinePayment::FirstDataGlobalGateway test",
  card_number    => '4111111111111111',
  cvv2           => '123',
  expiration     => '12/20',
  amount         => '5521.00', # trigger error 521
  first_name     => 'Tofu',
  last_name      => 'Beast',
  address        => '1234 Soybean Ln.',
  city           => 'Soyville',
  state          => 'CA', #where else?
  zip            => '54545',
);

my $tx = new Business::OnlinePayment( 'FirstDataGlobalGateway' );

$tx->content( %content );

$tx->test_transaction(1);

$tx->submit;

is( $tx->is_success, 0, 'declined purchase')
  or diag('Test transaction should have failed, but succeeded');
is( $tx->failure_status, 'nsf', 'failure status' )
  or diag('Failure status reported as '.$tx->failure_status);

1;
