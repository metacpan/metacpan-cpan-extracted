#!/usr/bin/perl
use strict;
use warnings;
use stl;

print ">>>$0>>>>:\n";
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

print "Compare:\n";
my $rev = reverse_iterator($p->rbegin());
MyPrint->new()->function_operator($rev->first()->p_element());
MyPrint->new()->function_operator($p->begin()->last()->p_element());
print '$rev->first() and $p->begin()->last() are ', $rev->first()->eq($p->begin()->last()) ? 'equal' : 'not equal', "\n";

my $iter2 = $p->end();
$iter2--;
$iter2--;
$iter2--;
my $iter1;
for ($iter1 = $p->begin(); $iter1 != $iter2; ++$iter1) {}
MyPrint->new()->function_operator($iter1->p_element());
for ($iter1 = $p->begin(); $iter1 <= $iter2; ++$iter1) {}
MyPrint->new()->function_operator($iter1->p_element());

print "Overloaded Forward:\n";
for (my $i = $p->begin(); !$i->at_end(); $i++)
{
	MyPrint->new()->function_operator($i->p_element());
}
print "Overloaded Reverse:\n";
for (my $r = $p->end(); !$r->at_end(); --$r)
{
	MyPrint->new()->function_operator($r->p_element());
}

my $ii = $p->end();
print '$ii->p_element()->data()=', $ii->p_element()->data(), "\n";
$p->push($p->factory(priority => 331, data => 'thirty'));
++$ii;
print '$ii->p_element()->data()=', $ii->p_element()->data(), "\n";

print "Forward:\n";
my $i = $p->begin();
while (!$i->at_end())
{
	MyPrint->new()->function_operator($i->p_element());
	$i->next();
}
print "Backward:\n";
$i = $p->end();
while (!$i->at_end())
{
	MyPrint->new()->function_operator($i->p_element());
	$i->prev();
}
print "Reverse:\n";
my $ri = reverse_iterator($p->rbegin())->first();
while (!$ri->at_end())
{
	MyPrint->new()->function_operator($ri->p_element());
	$ri->next();
}
print "Compare:\n";
MyPrint->new()->function_operator($ri->first()->p_element());
MyPrint->new()->function_operator($p->begin()->last()->p_element());
print '$ri->first() and $p->begin()->last() are ', $ri->first()->eq($p->begin()->last()) ? 'equal' : 'not equal', "\n";

my $i2 = iterator($p->begin());
while ($i2->le($p->end()))
{
	MyPrint->new()->function_operator($i2->p_element());
	$i2->next();
}

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
