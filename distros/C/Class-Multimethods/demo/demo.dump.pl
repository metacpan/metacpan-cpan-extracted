#!/usr/bin/env perl -w

use strict;
use 5.005;

use Class::Multimethods;

multimethod stringify => ('ARRAY') => sub
{
	'[' . join(",", map { stringify($_) } @{$_[0]}) . ']';
};

multimethod stringify => ('HASH') => sub
{
	'{' . join(",", map { "$_=>".stringify($_[0]->{$_}) } keys %{$_[0]}) . '}';
};

multimethod stringify => ('CODE') => sub { 'sub {...}'; };
multimethod stringify => ('#') => sub { "+$_[0]"; };
multimethod stringify => ('$') => sub { "'$_[0]'"; };


print stringify([{a=>1,b=>[sub{0},{d=>'e'}]},2,3]), "\n";

print stringify(1), "\n";
print stringify(1.0), "\n";
print stringify(1.01), "\n";
print stringify(1.0000), "\n";
print stringify("1"), "\n";
print stringify("1s"), "\n";
