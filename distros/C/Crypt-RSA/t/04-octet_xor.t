#!/usr/bin/perl -sw
##
## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 04-octet_xor.t,v 1.1 2001/02/19 20:22:21 vipul Exp $

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Crypt::RSA::DataFormat qw(octet_xor);
use Data::Dumper;

print "1..2\n"; 

my $i = 0; 
my $a = "abcdefghijklmnopqrstuvwxyz"; 
my $b = "ABCDEFGHIJ";
my $d = octet_xor ($a, $b); 
my $e = octet_xor ($d, $b); 
my $f = octet_xor ($d, $a);
$f =~ s/^\0+//;

print $e eq $a ? "ok" : "not ok"; print " ", ++$i, "\n";

# if octet_xor has endianness issues, this should break. 
print $f eq $b ? "ok" : "not ok"; print " ", ++$i, "\n";

