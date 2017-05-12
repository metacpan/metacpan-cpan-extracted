#!/usr/bin/perl -s
##
## 12-versioning.t
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 12-versioning.t,v 1.1 2001/04/06 18:33:31 vipul Exp $

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Crypt::RSA::ES::OAEP;
use Data::Dumper;

print "1..2\n";
my $i = 0;

my $oaep = eval { new Crypt::RSA::ES::OAEP ( Version => '75.8' ) };
print $@ ? "ok" : "not ok"; print " ", ++$i, "\n";

my $oaep2 = new Crypt::RSA::ES::OAEP ( Version => '1.14' );
print $$oaep2{P} eq "Crypt::RSA" ? "ok" : "not ok"; print " ", ++$i, "\n";

