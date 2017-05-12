#!/usr/bin/perl
use strict;
use warnings;
use stl;

print ">>>$0>>>>:\n";
my $v = list(element_type => 'MyElem');
$v->push_back($v->factory(data => 'first'));
$v->push_back($v->factory(data => 'second'));
$v->push_back($v->factory(data => 'third'));
$v->push_back($v->factory(data => 'fourth'));
$v->push_back($v->factory(data => 'fifth'));
for_each($v->begin(), $v->end(), ptr_fun('::myprint'));
print 'for_each($v->begin(), $v->end(), ptr_fun(\'uc\'));', "\n";
for_each($v->begin(), $v->end(), ptr_fun('uc'));
for_each($v->begin(), $v->end(), ptr_fun('::myprint'));
print 'for_each($v->begin(), $v->end(), "something");', "\n";
for_each($v->begin(), $v->end(), mem_fun('something'));

print "for_each with mem_fun():\n";
for_each($v->begin(), $v->end(), mem_fun('something'));
print "for_each with unary-function-object:\n";
for_each($v->begin(), $v->end(), ptr_fun('::myprint'));

sub myprint { print "Data:", @_, "\n"; }

{
	package MyElem;
	use base qw(Class::STL::Element);
	sub something
	{
		my $self = shift;
		print "Something:", $self->data(), "\n";
	}
}
