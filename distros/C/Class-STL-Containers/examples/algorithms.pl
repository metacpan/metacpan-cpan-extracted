#!/usr/bin/perl
use strict;
use warnings;
use stl;

print ">>>$0>>>>:\n";
my $v = list(element_type => 'MyElem', qw(first second third fourth fifth));
for_each($v->begin(), $v->end(), ptr_fun('::myprint'));

print 'for_each($v->begin(), $v->end(), ptr_fun(\'uc\'));', "\n";
for_each($v->begin(), $v->end(), ptr_fun('uc'));
for_each($v->begin(), $v->end(), ptr_fun('::myprint'));

print 'for_each($v->begin(), $v->end(), "something");', "\n";
for_each($v->begin(), $v->end(), mem_fun('something'));

print "Static Foreach with unary-function-object:\n";
for_each($v->begin(), $v->end(), ptr_fun('::myprint'));

my $v2 = list(element_type => 'MyElem', qw(red blue green yellow white));
my $t1 = tree($v);
my $t2 = tree($v2);
my $tree = tree();
print "\$tree->size()=", $tree->size(), "\n";
$tree->push_back($tree->factory($t1));
$tree->push_back($tree->factory($t2));

print "Tree Foreach:\n";
for_each($tree->begin(), $tree->end(), ptr_fun('::myprint'));

print "Tree Find_If 'yellow':",
	find_if($tree->begin(), $tree->end(), bind1st(equal_to(), 'yellow'))
	? '...Found' : '...Not found!', "\n";

print "Tree Count_If(/e/i):",
	count_if($tree->begin(), $tree->end(), bind2nd(matches_ic(), 'e')),
	"\n";

print "Tree Remove_If(/l/i):\n";
remove_if($tree->begin(), $tree->end(), bind2nd(matches_ic(), 'l'));
for_each($tree->begin(), $tree->end(), ptr_fun('::myprint'));

print "Tree Find_If 'yellow':",
	find_if($tree->begin(), $tree->end(), bind1st(equal_to(), 'yellow'))
	? '...Found' : '...Not found!', "\n";

sub myprint { print "Data:", @_, "\n"; }
# ----------------------------------------------------------------------------------------------------
{
	package MyElem;
	use base qw(Class::STL::Element);
	sub something
	{
		my $self = shift;
		print "Something:", $self->data(), "\n";
	}
}
# ----------------------------------------------------------------------------------------------------
