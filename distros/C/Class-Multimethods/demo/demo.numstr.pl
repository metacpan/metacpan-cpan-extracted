#!/usr/bin/env perl -w

use Class::Multimethods;

multimethod mm => ('#') => sub
{
	print "mm(number)\n";
	mm(superclass($_[0]));
};

multimethod mm => ('$') => sub
{
	print "mm(string)\n";
};

sub try
{
	print "$_[0]\n";
	eval $_[0];
	print "---\n";
}

try q{ mm(1) };
try q{ mm("2") };
try q{ mm("three") };
try q{ mm(4 . "") };
try q{ mm("5" + 0) };
