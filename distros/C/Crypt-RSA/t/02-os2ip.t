#!/usr/bin/perl -sw
##
##
##
## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 02-os2ip.t,v 1.1 2001/02/19 20:22:21 vipul Exp $

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Crypt::RSA::DataFormat qw(i2osp os2ip);
use Math::Pari qw(PARI);

print "1..6\n";

my $i = 0;
my $string = "abcdefghijklmnopqrstuvwxyz-0123456789-abcdefghijklmnopqrstuvwxyz-abcdefghijklmnopqrstuvwxyz-0123456789";
$number = PARI ("166236188672784693770242514753420034912412776787232632921068824014646347893937590064771712921923774969379936913356439094695954550320707099033382274920372913421785829711983357001510792400267452442816935867829132703234881800415259286201953001355321");

my $n = os2ip ($string);
print $n == $number ? "ok" : "not ok"; print " ", ++$i, "\n";
my $str = i2osp ($n);
print $str eq $string ? "ok" : "not ok"; print " ", ++$i, "\n";
my $str2 = i2osp ($number);
print $str2 eq $string ? "ok" : "not ok"; print " ", ++$i, "\n";

$string = "abcd";
$number = 1_633_837_924;
$n = os2ip ($string);
print $n == $number ? "ok" : "not ok"; print " ", ++$i, "\n";
$str = i2osp ($n);
print $str eq $string ? "ok" : "not ok"; print " ", ++$i, "\n";
$str2 = i2osp ($number);
print $str2 eq $string ? "ok" : "not ok"; print " ", ++$i, "\n";

