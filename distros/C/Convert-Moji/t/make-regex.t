#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Convert::Moji qw/make_regex/;
use Test::More tests => 1;
my %foo2bar = (mad => 'max', dangerous => 'trombone');
my $x = 'mad, bad, and dangerous to know';
my $regex = make_regex (keys %foo2bar);
$x =~ s/($regex)/$foo2bar{$1}/g;
ok ($x eq 'max, bad, and trombone to know');
