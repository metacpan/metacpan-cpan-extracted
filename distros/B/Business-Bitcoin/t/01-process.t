#!perl -T
# -*-cperl-*-
#
# 01-process.t - Test a Bitcoin Payment
# Copyright (c) 2016-2017 Ashish Gulhati <biz-btc at hash dot neomailbox.ch>

use Test::More tests => 9;
use Business::Bitcoin;

$ENV{PATH} = '';

ok (my $bizbtc = new Business::Bitcoin (XPUB => 'xpub6895k9BPNhE9sTBUj9nNJpDtHqEiQXZq9K2p399jvaa4fbDYckqvDb8ZzWkiwbG7KNzLLGgKCAPTy2MbFTNE3aU3SCXAB5rRm7eTtwWQkRH',
					DB => ':memory:', Create => 1, Clobber => 1), 'Business::Bitcoin object created');

# Using an address with a known amount for testing.

ok (my $req = $bizbtc->request(Amount => 4200, Confirmations => 0, Reference => 0), 'Business::Bitcoin::Request created');
ok ($req->address eq '1HU8TWVbKbPZEQtiU3Z3jTc3tT7nitJmG4', 'Request address check');

# Verify payment at 0 confirmations

ok($req->verify(), 'Payment verified at 0 confirmations');

# Try again with 5 confirmations required

$req->confirmations(5);
ok($req->verify(), 'Payment verified at 5 confirmations');

# One more request

ok (my $req2 = $bizbtc->request(Amount => 4200, Confirmations => 0), 'Business::Bitcoin::Request 2 created');
ok ($req2->address eq '1LdM8nNEmnb6h6wLXhNXBs3hjYa5qJoB5X', 'Request 2 address check');

# Find and load a request by Address

my $req3 = $bizbtc->findreq(Address => $req->address);
ok($req3->created == $req->created, 'Find a request by Address');

# Find and load a request by Reference ID

my $req4 = $bizbtc->findreq(Reference => $req->reference);
ok($req4->address eq $req->address, 'Find a request by Reference ID');
