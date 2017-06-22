#!perl
# -*-cperl-*-
#
# 01-hashcash.t - Test HashCash Mint and Client
# Copyright (c) 2001-2017 Ashish Gulhati <crypt-hashcash at hash.neo.tc>

use Test::More tests => 46;

use Crypt::HashCash::Mint;
use Crypt::HashCash::Client;

my @denoms = (1,10);

for (qw(ECDSA RSA)) {
  my $mint = new Crypt::HashCash::Mint (Create => 1, Clobber => 1, SpentDB => ':memory:');
  $mint->sigscheme($_); $mint->keysize(1024);
  $mint->{DENOMS} = \@denoms;
  ok($mint->keygen(Mint => 'Test Mint'), "Generate $_ mint keys");
  ok($mint->loadkeys, "Load saved $_ mint keys");

  my $client = new Crypt::HashCash::Client;
  $client->{DENOMS} = \@denoms;
  $client->sigscheme($_);
  ok($client->mintkeys($mint->pkeys), "Load $_ Mint Keys in Client");

  ok(my $init = $mint->init, "Initialize for $_ with denomination 1");
  ok(my $init2 = $mint->init, "Initialize for $_ with denomination 10");
  ok(my $request = $client->request_coin(Denomination => 1, Init => $init), "Request a coin of denomination 1");
  ok(my $request2 = $client->request_coin(Denomination => 10, Init => $init2), "Request a coin of denomination 10");
  ok(my $blindcoin = $mint->mint_coin($request), 'Mint a coin of denomination 1');
  ok(my $blindcoin2 = $mint->mint_coin($request2), 'Mint a coin of denomination 10');
  ok(my $coin = $client->unblind_coin($blindcoin), 'Unblind coin of denomination 1');
  ok(my $coinstr = $coin->as_string, 'Serialize coin of denomination 1');
  ok($coin = Crypt::HashCash::Coin->from_string($coinstr), 'Deserialize coin of denomination 1');
  ok(my $coin2 = $client->unblind_coin($blindcoin2), 'Unblind coin of denomination 10');
  ok(my $coin2str = $coin2->as_string, 'Serialize coin of denomination 10');
  ok($coin2 = Crypt::HashCash::Coin->from_string($coin2str), 'Deserialize coin of denomination 10');

  ok($mint->spend_coin($coin), 'Spend coin of denomination 1');
  ok($mint->spend_coin($coin2), 'Spend coin of denomination 10');

  # Try to double spend the coin
  ok(!($mint->spend_coin($coin)), 'Block double spend of denomination 1');
  ok(!($mint->spend_coin($coin2)), 'Block double spend of denomination 10');

  ok($mint->unspend_coin($coin), 'Unspend coin of denomination 1');
  ok($mint->unspend_coin($coin2), 'Unspend coin of denomination 10');

  ok($mint->spend_coin($coin), 'Spend coin of denomination 1 again');
  ok($mint->spend_coin($coin2), 'Spend coin of denomination 10 again');
}

exit;
