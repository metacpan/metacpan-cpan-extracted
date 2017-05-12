#!/usr/bin/perl -s
##
## random_octet.t 
##
## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 03-random_octet.t,v 1.2 2001/04/17 19:53:23 vipul Exp $

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Crypt::RSA; 
use Crypt::Random qw(makerandom_octet);

print "1..6\n";  my $i = 0;

for my $len (qw/10 512 1024/) { 
    my $ro = makerandom_octet ( Length => $len );
    print $ro ne "" ? "ok" : "not ok"; print " ", ++$i, "\n";
    print length($ro) == $len ? "ok" : "not ok"; print " ", ++$i, "\n";
}

