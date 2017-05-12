#!/usr/bin/perl

use strict;
use warnings;

print "1..1\n";
my $r = `script/perluse.sh -v`;

print defined $r && $r =~ /^perluse [0-9.]+$/ ? '' : 'not ';
print "ok 1\n";
