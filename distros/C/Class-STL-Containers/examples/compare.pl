#!/usr/bin/perl
use strict;
use warnings;
use lib './lib';
use stl;

print ">>>$0>>>>:\n";
my $d1 = deque();
print "Deque-1:\n";
$d1->push_back($d1->factory(data => 'first'));
$d1->push_back($d1->factory(data => 'second'));
$d1->push_back($d1->factory(data => 'third'));
$d1->push_back($d1->factory(data => 'fourth'));
$d1->push_back($d1->factory(data => 'fifth'));
for_each($d1->begin(), $d1->end(), ptr_fun('::myprint'));

my $d2 = deque($d1);
print "Deque-2:\n";
for_each($d2->begin(), $d2->end(), ptr_fun('::myprint'));

print "Deques d1 and d2 are ", ($d1->eq($d2) ? " equal" : " not equal"). "\n";
$d2->push($d2->factory(data => 'sixth'));
print '$d2->push($d2->factory(data => "sixth"));', "\n";
print "Deques d1 and d2 are ", ($d1->eq($d2) ? " equal" : " not equal"). "\n";

sub myprint { print "Data:", @_, "\n"; }
