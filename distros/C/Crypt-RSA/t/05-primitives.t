#!/usr/bin/perl -s
##
## testvectors_kg.t
##
## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 05-primitives.t,v 1.2 2001/04/06 18:33:31 vipul Exp $

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Crypt::RSA::Key;
use Crypt::RSA::Primitives;

print "1..5\n"; 
my $i = 0;

my $rsa      = new Crypt::RSA::Primitives; 
my $keychain = new Crypt::RSA::Key;

my ($pubkey, $prikey) = $keychain->generate( q => 2551, p => 2357, e => 3674911, Password => 'xx' );
die $keychain->errstr if $keychain->errstr;

print $prikey->d   == 422191  ? "ok" : "not ok"; print " ", ++$i, "\n";
print $prikey->phi == 6007800 ? "ok" : "not ok"; print " ", ++$i, "\n";
print $pubkey->n   == 6012707 ? "ok" : "not ok"; print " ", ++$i, "\n";

my $c = $rsa->core_encrypt ( Key => $pubkey, Plaintext => 5_234_673 );
print $c == 3_650_502 ? "ok" : "not ok"; print " ", ++$i, "\n";

my $d = $rsa->core_decrypt ( Key => $prikey, Cyphertext => $c );
print $d == 5_234_673 ? "ok" : "not ok"; print " ", ++$i, "\n";

