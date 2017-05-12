#!/usr/bin/env perl
use strict;
use warnings;

## 09-publickey.t
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

use Test::More;
use Crypt::RSA::Key::Public;
use Math::BigInt try => 'GMP, Pari';

plan tests => 8;
my $keyfile = "./rsa-public-key";
END { unlink "$keyfile" if -e $keyfile; }
my $n = Math::BigInt->new('90323071930747658587680108508312228275784837926947082008548691733142705211489057935389756600126815968792421058507821141460115569139868202311230475972964057619586895938810033730091286963807334963647271206191891975955352543611579505094807268518669728893837266971976327030260763032999438640559854194396431791831');
my $e = Math::BigInt->new('65537');

my $key = new Crypt::RSA::Key::Public();
$key->n ($n);
$key->e ($e);
$key->Identity ('mail@vipul.net');

is($key->n, $n, "n is set correctly");
is($key->e, $e, "n is set correctly");
is($key->Identity, 'mail@vipul.net', "Identity is set correctly");

$key->write(Filename => $keyfile);

my $pkey = new Crypt::RSA::Key::Public (Filename => $keyfile);
is($pkey->n, $n, "Read n from file correctly");
is($pkey->e, $e, "Read e from file correctly");
is($pkey->Identity, 'mail@vipul.net', "Read Identity from file correctly");

# string and hex assignments
my $key2 = new Crypt::RSA::Key::Public; 
$key2->e ("0x10e9");
$key2->n ("1023");
is($key2->n, 1023, "n set correctly from string");
is($key2->e, 4329, "e set correctly from hex string");
