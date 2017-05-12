#!/usr/bin/perl -T
##
##
##
## Copyright (c) 2008, Lord Infernale.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: encrypt.t,v 0.1 2008/01/10 14:48:00 infernale Exp $

use warnings;
use strict;

use Cisco::Hash qw(encrypt);

my $d = '1511021F0725';
my $e = encrypt('cisco', 15);

print "1..1\n";

print $e =~ /^$d$/ ? "ok 1" : "not ok 1"; print "\n";