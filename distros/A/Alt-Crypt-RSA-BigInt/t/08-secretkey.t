#!/usr/bin/env perl
use strict;
use warnings;

## 08-secretkey.t
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

use Test::More;
use Crypt::RSA::Key::Private;
use Math::BigInt try => 'GMP, Pari';

plan tests => 9;

my $keyfile = "./rsa-secret-key";
END { unlink "$keyfile" if -e $keyfile; }
my $n = Math::BigInt->new('90323071930747658587680108508312228275784837926947082008548691733142705211489057935389756600126815968792421058507821141460115569139868202311230475972964057619586895938810033730091286963807334963647271206191891975955352543611579505094807268518669728893837266971976327030260763032999438640559854194396431791831');
my $d = Math::BigInt->new('67127971444083894698111525475904660003183729815338076558133285445567873761935968153242120858787811852723994880704646906893782886401506943100433385617516203000465715740516516951676123755998421450101326454304488576875788190219482423178600060734811018449586201620558124277217738976109970655234934905138718729177');
my $cipherreg = qr/^Blowfish/;

my $key = new Crypt::RSA::Key::Private ( Password => 'a day so foul and fair' );
$key->n ($n);
$key->d ($d);

$key->hide();

like($key->n, $cipherreg, "n is encrypted");
like($key->d, $cipherreg, "d is encrypted");

$key->reveal ( Password => 'a day so foul and fair' );

is($key->n, $n, "n is back again");
is($key->d, $d, "d is back again");

$key->write(Filename => $keyfile);
$key->DESTROY();

ok( ! $key->n, "n is destroyed" );

my $pkey = new Crypt::RSA::Key::Private (Filename => $keyfile);
like($pkey->n, $cipherreg, "n from file is encrypted");
like($pkey->d, $cipherreg, "d from file is encrypted");

$pkey->reveal ( Password => 'a day so foul and fair' );

is($pkey->n, $n, "n is back again");
is($pkey->d, $d, "d is back again");
