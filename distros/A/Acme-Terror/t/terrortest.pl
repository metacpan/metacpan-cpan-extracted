#!/usr/bin/perl

use Acme::Terror;
my $t = Acme::Terror->new();

my $level = $t->fetch;

print "Current terror alert level is: $level\n";
