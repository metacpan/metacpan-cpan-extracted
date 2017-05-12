#!/usr/bin/perl
use strict;
use warnings;
use stl;

print ">>>$0>>>>\n";
my $p = priority_queue();
$p->push($p->factory(priority => 10, data => 'ten'));
$p->push($p->factory(priority => 2, data => 'two'));
$p->push($p->factory(priority => 12, data => 'twelve'));
$p->push($p->factory(priority => 3, data => 'three'));
$p->push($p->factory(priority => 11, data => 'eleven'));
$p->push($p->factory(priority => 1, data => 'one'));
$p->push($p->factory(priority => 1, data => 'one-2'));
$p->push($p->factory(priority => 12, data => 'twelve-2'));
$p->push($p->factory(priority => 20, data => 'twenty'), $p->factory(priority => 0, data => 'zero'));
print "\$p->size()=", $p->size(), "\n";
print "\$p->top():"; MyPrint->new()->function_operator($p->top());
for_each($p->begin(), $p->end(), MyPrint->new());
print '$p->top()->priority(7);', "\n";
print '$p->refresh();', "\n";
$p->top()->priority(7);
$p->refresh();
for_each($p->begin(), $p->end(), MyPrint->new());
print "\$p->top():"; MyPrint->new()->function_operator($p->top());
print '$p->pop();'. "\n";
$p->pop();
print "\$p->top():"; MyPrint->new()->function_operator($p->top());

# ----------------------------------------------------------------------------------------------------
{
	package MyPrint;
	use base qw(Class::STL::Utilities::FunctionObject::UnaryFunction);
	sub function_operator
	{
		my $self = shift;
		my $element = shift;
		print "Data:", $element->data(), '[', $element->priority(), ']', "\n";
	}
}
# ----------------------------------------------------------------------------------------------------
