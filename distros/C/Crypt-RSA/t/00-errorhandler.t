#!/usr/bin/perl -sw
##
## 00-errorhandler.t -- Test for the base class and error handling
##                      methods therein.
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 00-errorhandler.t,v 1.2 2001/04/06 18:33:31 vipul Exp $

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Crypt::RSA::Errorhandler; 

print "1..6\n";

my $i = 0;
my $plaintext = "data";
my @plaintext = qw(1 3 4 5);
my %plaintext = qw(a 1 b 2);
my $rsa = new Crypt::RSA::Errorhandler; 

$rsa->error ("Message too short", \$plaintext);
print $rsa->errstr eq "Message too short\n" ? "ok" : "not ok"; print " ", ++$i, "\n";
print $plaintext eq "" ? "ok" : "not ok"; print " ", ++$i, "\n";

$rsa->error ("Out of range", \@plaintext);
print $rsa->errstr eq "Out of range\n" ? "ok" : "not ok"; print " ", ++$i, "\n";
print @plaintext ? "not ok" : "ok"; print " ", ++$i, "\n";

$rsa->error ("Bad values", \%plaintext);
print $rsa->errstr eq "Bad values\n" ? "ok" : "not ok"; print " ", ++$i, "\n";
print %plaintext ? "not ok" : "ok"; print " ", ++$i, "\n";

