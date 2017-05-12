#!/usr/bin/perl
use strict;
use warnings;
use stl;

print ">>>$0>>>>:\n";
my $l1 = list(qw(first second third fourth fifth));
for_each($l1->begin(), $l1->end(), ptr_fun('::myprint'));
print "Size:", $l1->size(), "\n";
print "\$l1->begin:", $l1->begin()->p_element()->data(), "\n";
print "\$l1->end:", $l1->end()->p_element()->data(), "\n";
print "\$l1->rbegin:", $l1->rbegin()->p_element()->data(), "\n";
print "\$l1->rend:", $l1->rend()->p_element()->data(), "\n";
print "\$l1->front:", $l1->front()->data(), "\n";
print "\$l1->back:", $l1->back()->data(), "\n";
$l1->reverse();
print '$l1->reverse();', "\n";
for_each($l1->begin(), $l1->end(), ptr_fun('::myprint'));
print "\$l1->front:", $l1->front()->data(), "\n";
print "\$l1->back:", $l1->back()->data(), "\n";
print '$l1 container is ', $l1->empty() ? 'empty' : 'not empty', "\n";

print 'my $i = $l1->begin();', "\n";
print '$l1->insert($i, $l1->factory("tenth"));', "\n";
print '$i++;', "\n";
print '$i++;', "\n";
print '$l1->insert($i, $l1->factory("eleventh"));', "\n";
print '$i->last();', "\n";
print '$l1->insert($i, $l1->factory(\'twelfth\'));', "\n";
my $i = $l1->begin();
$l1->insert($i, $l1->factory('tenth'));
$i++;
$i++;
$l1->insert($i, $l1->factory('eleventh'));
$i->last();
$l1->insert($i, $l1->factory('twelfth'));
for_each($l1->begin(), $l1->end(), ptr_fun('::myprint'));

print '$l1->clear();', "\n";
$l1->clear();
print "Size:", $l1->size(), "\n";
print '$l1 container is ', $l1->empty() ? 'empty' : 'not empty', "\n";

sub myprint { print "Data:", @_, "\n"; }
