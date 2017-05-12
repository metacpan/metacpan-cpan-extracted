#!/usr/bin/perl

use strict;
use warnings;

package MyClass;

use Hash::FieldHash qw/:all/;

fieldhash my %date => 'date';
fieldhash my %time => 'time';

sub new
{
	my($class) = shift;
	my($self)  = bless {}, $class;

	return from_hash $self, @_;
}

sub doit2it
{
	my($self, $value) = @_;

	$self -> time($value);
}

package main;

my($class1) = MyClass -> new(date => 'd1');
my($class2) = MyClass -> new(date => 'd2', time => 't2');
my($class3) = MyClass -> new(time => 't3');

$class3 -> doit2it('t33333');

print 'd1. Expect d1:      ', $class1 -> date(), "\n";
print 't1. Expect undef:   ', $class1 -> time() || 'undef', "\n";
print 'd2. Expect d2:      ', $class2 -> date(), "\n";
print 't2. Expect t2:      ', $class2 -> time(), "\n";
print 'd3. Expect undef:   ', $class3 -> date() || 'undef', "\n";
print 't3. Expect t33333:  ', $class3 -> time(), "\n";
