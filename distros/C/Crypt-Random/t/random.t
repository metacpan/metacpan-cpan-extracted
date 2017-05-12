#!/usr/bin/perl -sw
##
##
##
## Copyright (c) 1999, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: random.t,v 1.3 2001/06/22 03:26:03 vipul Exp $

use lib 'lib';
use lib '../lib';
use Crypt::Random qw(makerandom makerandom_itv);

print "1..1\n";

$r = makerandom ( Size => 512, Verbosity => 1, Strength => 0 );
$y = makerandom ( Size => 512, Verbosity => 1, Strength => 0 );
print "$r, $y\n";
print $r == $y ? "not ok 1" : "ok 1";
print "\n";


