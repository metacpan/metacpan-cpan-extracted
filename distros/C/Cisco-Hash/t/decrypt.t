#!/usr/bin/perl -T
##
##
##
## Copyright (c) 2008, Lord Infernale.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: decrypt.t,v 0.1 2008/01/10 14:54:00 infernale Exp $

use warnings;
use strict;

use Cisco::Hash qw(decrypt);

my $e = 'cisco';
my $d = decrypt('1511021F0725');

print "1..1\n";

print $d =~ /^$e$/ ? "ok 1" : "not ok 1"; print "\n";