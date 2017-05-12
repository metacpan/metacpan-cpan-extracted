#!/usr/bin/env perl

use strict;
use lib::abs '../lib';
use Acme::CPANAuthors;

my $authors = Acme::CPANAuthors->new('AnyEvent');

print  'AnyEvent CPAN authors: ', $authors->count, "\n\n";
printf "%-20s %s\n", $_, $authors->name($_) for $authors->id;

print "\nAlso:\n";
print "Marc have distros: ", 0+$authors->distributions("MLEHMANN"),"\n";
print "Robin have avatar: ", $authors->avatar_url("ELMEX"),"\n";
print "Mons' kwalitee is: ", $authors->kwalitee("MONS")->{info}{CPANTS_Game_Kwalitee},"\n";
print "And MYYAGAWA name: ", $authors->name("MIYAGAWA"),"\n";

