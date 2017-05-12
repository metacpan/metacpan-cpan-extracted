#!/usr/bin/perl
use strict;
use warnings;
use stl;

print ">>>$0>>>>:\n";
my $v = list();
$v->push_back($v->factory(data => 'first'));
$v->push_back($v->factory(data => 'second'));
$v->push_back($v->factory(data => 'third'));
$v->push_back($v->factory(data => 'fourth'));
$v->push_back($v->factory(data => 'fifth'));
for_each($v->begin(), $v->end(), ptr_fun('::myprint'));
print "find_if(\$v->begin(), \$v->end(), bind1st(equal_to(), 'second'));\n";
print "Element 'second' was ", find_if($v->begin(), $v->end(), bind1st(equal_to(), 'second')) ? 'found' : 'not found', "\n";

sub myprint { print "Data:", @_, "\n"; }
