#!/usr/bin/perl
use strict;

use lib '../lib';
use Acme::CPANAuthors;

my $a = Acme::CPANAuthors->new('Norwegian');

print  'Norwegian CPAN authors: ', $a->count, "\n";
printf "%-20s %s\n", $_, $a->name($_) for $a->id;
