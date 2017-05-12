#!/usr/bin/perl
use strict;
use warnings;
use stl;

print ">>>$0>>>>:\n";
my $l = list();
$l->push_back($l->factory(data => 'first'));
$l->push_back($l->factory(data => 'second'));
$l->push_back($l->factory(data => 'third'));
$l->push_back($l->factory(data => 'fourth'));
$l->push_back($l->factory(data => 'fifth'));
print join(' ', map($_->data(), $l->to_array())), "\n";

my $l2 = list();
print 'transform($l->begin(), $l->end(), $l2->begin(), MyUFunc->new());', "\n";
transform($l->begin(), $l->end(), $l2->begin(), MyUFunc->new());
print '$l=', join(' ', map($_->data(), $l->to_array())), "\n";
print '$l2=', join(' ', map($_->data(), $l2->to_array())), "\n";

$l2->clear();
$l2->push_back($l2->factory(data => '1'));
$l2->push_back($l2->factory(data => '2'));
$l2->push_back($l2->factory(data => '3'));
$l2->push_back($l2->factory(data => '4'));
$l2->push_back($l2->factory(data => '5'));
my $l3 = list();
print 'transform($l->begin(), $l->end(), $l2->begin(), $l3->begin(), MyBFunc->new());', "\n";
transform($l->begin(), $l->end(), $l2->begin(), $l3->begin(), MyBFunc->new());
print '$l=', join(' ', map($_->data(), $l->to_array())), "\n";
print '$l2=', join(' ', map($_->data(), $l2->to_array())), "\n";
print '$l3=', join(' ', map($_->data(), $l3->to_array())), "\n";

# ----------------------------------------------------------------------------------------------------
{
	package MyBFunc;
	use base qw(Class::STL::Utilities::FunctionObject::BinaryFunction);
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift;
		my $arg2 = shift;
		my $tmp = $arg1->clone();
		$tmp->data($tmp->data() . '-' . $arg2->data());
		return $tmp;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package MyUFunc;
	use base qw(Class::STL::Utilities::FunctionObject::UnaryFunction);
	sub function_operator
	{
		my $self = shift;
		my $arg = shift;
		my $tmp = $arg->clone();
		$tmp->data(uc($arg->data()));
		return $tmp;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package MyMatch;
	use base qw(Class::STL::Utilities::FunctionObject::UnaryFunction);
	use Class::STL::ClassMembers (
			qw(what),
			Class::STL::ClassMembers::FunctionMember::New->new(),
	); 
	sub function_operator
	{
		my $self = shift;
		my $arg = shift;
		return ($arg->data() =~ /@{[ $self->what() ]}/i) ? $arg : 0;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package MyFind;
	use base qw(Class::STL::Utilities::FunctionObject::UnaryFunction);
	use Class::STL::ClassMembers (
			qw(what),
			Class::STL::ClassMembers::FunctionMember::New->new(),
	); 
	sub function_operator
	{
		my $self = shift;
		my $arg = shift;
		return $arg->data() eq $self->what() ? $arg : 0;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package MyPrint;
	use base qw(Class::STL::Utilities::FunctionObject::UnaryFunction);
	sub function_operator
	{
		my $self = shift;
		my $arg = shift;
		print "Data:", $arg->data(), "\n";
	}
}
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
