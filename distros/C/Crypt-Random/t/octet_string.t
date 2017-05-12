#!/usr/bin/perl -sw
##
##
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: octet_string.t,v 1.1.1.1 2001/06/21 15:34:49 vipul Exp $

use lib "../lib";
use Crypt::Random qw(makerandom_octet);

print "1..2\n";

my $skip;

for (0..32, 65..255) { 
     $skip .= chr($_)
 }
 
my $string = makerandom_octet ( Length => 200, Strength => 0, Skip => $skip );
print length($string) == 200 ? "ok 1" : "not ok 1"; print "\n";

my $q_skip = quotemeta $skip;
print $string !~ qr/[$q_skip]/ ? "ok 2" : "not ok 2"; print "\n";
 
