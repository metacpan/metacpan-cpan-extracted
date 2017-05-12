#!/usr/bin/perl -sw
##
## 01-i2osp.t -- Test for ::DataFormat::i2osp() 
##
## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 01-i2osp.t,v 1.2 2001/04/17 19:53:23 vipul Exp $

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Crypt::RSA::DataFormat qw(i2osp os2ip);
use Crypt::RSA::Debug qw(debug);
use Math::Pari qw(PARI);

print "1..2\n"; 

my $i = 0; 
my $number = 4; 
my $str = i2osp ($number,4);
my $n = os2ip ($str);
print $n == $number ? "ok" : "not ok"; print " ", ++$i, "\n";

$number = '123485709238475934857903284752987598237450923847592384759032487592384752465346539847658327456823746587342658736587324658736453548634986439032342237489750398756037408972134678645678364987346128974682376487456987436487964879326487964378569287346529'; 
$str = i2osp($number,102);
$n = os2ip ($str);
print $n == $number ? "ok" : "not ok"; print " ", ++$i, "\n";

