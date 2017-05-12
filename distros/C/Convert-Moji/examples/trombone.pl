#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Convert::Moji 'make_regex';
my $x = 'mad, bad, and dangerous to know';
my %foo2bar = (mad => 'max', dangerous => 'trombone');
my $regex = make_regex (keys %foo2bar);
$x =~ s/($regex)/$foo2bar{$1}/g;
print "$x\n";
