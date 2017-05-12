#!/usr/bin/perl
use strict;
use warnings;
use stl;

print ">>>$0>>>:\n";
my $v = list();
$v->push_back($v->factory(data => 'first'));
$v->push_back($v->factory(data => 'second'));
$v->push_back($v->factory(data => 'third'));
$v->push_back($v->factory(data => 'fourth'));
$v->push_back($v->factory(data => 'fifth'));

my $v2 = list();
$v2->push_back($v2->factory(data => 'red'));
$v2->push_back($v2->factory(data => 'yellow'));
$v2->push_back($v2->factory(data => 'orange'));
$v2->push_back($v2->factory(data => 'green'));
$v2->push_back($v2->factory(data => 'black'));

print "Original list v:\n"; for_each($v->begin(), $v->end(), MyPrint->new());
print "Original list v2:\n"; for_each($v2->begin(), $v2->end(), MyPrint->new());
print '$v->swap($v->front(), $v->back());', "\n";
$v->swap($v2);
print "Swapped list v:\n"; for_each($v->begin(), $v->end(), MyPrint->new());
print "Swapped list v2:\n"; for_each($v2->begin(), $v2->end(), MyPrint->new());

# ----------------------------------------------------------------------------------------------------
{
	package MyPrint;
	use base qw(Class::STL::Utilities::FunctionObject::UnaryFunction);
	sub function_operator
	{
		my $self = shift;
		my $element = shift;
		print "Data:", $element->data(), "\n";
	}
}
# ----------------------------------------------------------------------------------------------------
