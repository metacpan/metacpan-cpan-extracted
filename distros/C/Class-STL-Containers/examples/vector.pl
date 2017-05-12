#!/usr/bin/perl
use strict;
use warnings;
use stl;
print ">>>$0>>>>:\n";
my $v = vector();
$v->push_back($v->factory(data => 'first'));
$v->push_back($v->factory(data => 'second'));
$v->push_back($v->factory(data => 'third'));
$v->push_back($v->factory(data => 'fourth'));
$v->push_back($v->factory(data => 'fifth'));
for_each($v->begin(), $v->end(), MyPrint->new());

my $e = $v->at(0);
print 'Element-0:'; MyPrint->new()->function_operator($e);

$e = $v->at($v->size()-1);
print 'Element-last:'; MyPrint->new()->function_operator($e);

$e = $v->at(2);
print 'Element-2:'; MyPrint->new()->function_operator($e);

print '$v->pop_back();', "\n";
print '$v->push_back($v->factory(data => \'sixth\'));', "\n";
$v->pop_back();
$v->push_back($v->factory(data => 'sixth'));

for_each($v->begin(), $v->end(), MyPrint->new());

print "Erase:\n";
$v->clear();
$v->push_back($v->factory(data => 'first'));
$v->push_back($v->factory(data => 'second'));
$v->push_back($v->factory(data => 'third'));
$v->push_back($v->factory(data => 'fourth'));
$v->push_back($v->factory(data => 'fifth'));
for_each($v->begin(), $v->end(), MyPrint->new());

print '$i1 = $v->begin(); $i2 = $v->end(); $i1++; $i2--;', "\n";
my $i1 = $v->begin();
my $i2 = $v->end();
$i1++;
$i2--;
print '$v->erase($i1, $i2);', "\n";
$v->erase($i1, $i2);
print "Elements Deleted.\n";
for_each($v->begin(), $v->end(), MyPrint->new());

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
