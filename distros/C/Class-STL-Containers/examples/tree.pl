#!/usr/bin/perl
use strict;
use warnings;
use stl;

print ">>>$0>>>:\n";
my $l1 = list();
$l1->push_back($l1->factory(data => 'first'));
$l1->push_back($l1->factory(data => 'second'));
$l1->push_back($l1->factory(data => 'third'));
$l1->push_back($l1->factory(data => 'fourth'));
$l1->push_back($l1->factory(data => 'fifth'));

my $l2 = list();
$l2->push_back($l2->factory(data => 'red'));
$l2->push_back($l2->factory(data => 'blue'));
$l2->push_back($l2->factory(data => 'yellow'));
$l2->push_back($l2->factory(data => 'pink'));
$l2->push_back($l2->factory(data => 'white'));

my $t1 = tree($l1);
my $t2 = tree($l2);

my $tree = tree();
$tree->push_back($tree->factory($t1));
$tree->push_back($tree->factory($t2));

print "Tree Foreach:\n";
for_each($tree->begin(), $tree->end(), MyPrint->new());

print "Tree Find_If 'yellow':",
	find_if($tree->begin(), $tree->end(), MyFind->new(what => 'yellow'))
	? '...Found' : '...Not found!', "\n";

print "Tree Count_If(/e/i):",
	count_if($tree->begin(), $tree->end(), MyMatch->new(what => 'e')),
	"\n";

print "Tree Remove_If(/l/i):\n";
remove_if($tree->begin(), $tree->end(), MyMatch->new(what => 'l'));
for_each($tree->begin(), $tree->end(), MyPrint->new());

print "Tree Find_If 'yellow':",
	find_if($tree->begin(), $tree->end(), MyFind->new(what => 'yellow'))
	? '...Found' : '...Not found!', "\n";
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
