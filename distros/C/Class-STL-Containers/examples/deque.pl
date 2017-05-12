#!/usr/bin/perl
use strict;
use warnings;
use stl;

print ">>>$0>>>>:\n";
my $d = deque();
$d->push_back($d->factory(data => 'first'));
$d->push_back($d->factory(data => 'second'));
$d->push_back($d->factory(data => 'third'));
$d->push_back($d->factory(data => 'fourth'));
$d->push_back($d->factory(data => 'fifth'));
for_each($d->begin(), $d->end(), ptr_fun('::myprint'));
print '$d->push_front($d->factory(data => \'seventh\'));', "\n";
$d->push_front($d->factory(data => 'seventh'));
for_each($d->begin(), $d->end(), ptr_fun('::myprint'));
$d->pop_front();
print '$d->pop_front();', "\n";
for_each($d->begin(), $d->end(), ptr_fun('::myprint'));
$d->pop_back();
print '$d->pop_back();', "\n";
for_each($d->begin(), $d->end(), ptr_fun('::myprint'));

sub myprint { print "Data:", @_, "\n"; }
