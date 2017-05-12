#!/usr/bin/perl -s
##
## 08-secretkey.t
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id$

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Crypt::RSA::Key::Private;
use Math::Pari qw(PARI);
use Data::Dumper;

print "1..9\n";
my $i = 0;
my $keyfile = "./rsa-secret-key";
my $n = PARI('90323071930747658587680108508312228275784837926947082008548691733142705211489057935389756600126815968792421058507821141460115569139868202311230475972964057619586895938810033730091286963807334963647271206191891975955352543611579505094807268518669728893837266971976327030260763032999438640559854194396431791831');
my $d = PARI('67127971444083894698111525475904660003183729815338076558133285445567873761935968153242120858787811852723994880704646906893782886401506943100433385617516203000465715740516516951676123755998421450101326454304488576875788190219482423178600060734811018449586201620558124277217738976109970655234934905138718729177');

my $key = new Crypt::RSA::Key::Private ( Password => 'a day so foul and fair' );
$key->n ($n);
$key->d ($d);

$key->hide();

print $key->n =~ m/^Blowfish/ ? "ok" : "not ok"; print " ", ++$i, "\n";
print $key->d =~ m/^Blowfish/ ? "ok" : "not ok"; print " ", ++$i, "\n";

$key->reveal ( Password => 'a day so foul and fair' );

print $key->n == $n ? "ok" : "not ok"; print " ", ++$i, "\n";
print $key->d == $d ? "ok" : "not ok"; print " ", ++$i, "\n";

$key->write(Filename => $keyfile);
$key->DESTROY();

print !($key->n) ? "ok" : "not ok"; print " ", ++$i, "\n";

my $pkey = new Crypt::RSA::Key::Private (Filename => $keyfile);
print $pkey->n =~ m/^Blowfish/ ? "ok" : "not ok"; print " ", ++$i, "\n";
print $pkey->d =~ m/^Blowfish/ ? "ok" : "not ok"; print " ", ++$i, "\n";

$pkey->reveal ( Password => 'a day so foul and fair' );

print $pkey->n == $n ? "ok" : "not ok"; print " ", ++$i, "\n";
print $pkey->d == $d ? "ok" : "not ok"; print " ", ++$i, "\n";

unlink $keyfile;


