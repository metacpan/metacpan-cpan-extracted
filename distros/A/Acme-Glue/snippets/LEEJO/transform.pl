#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/ say /;

my $required_order = [ @ARGV ];
my $chaos = [
	{
		1 => 'Liz',
		2 => 'Nat',
		3 => 'Lee',
	},
];

# transform an array of hashes into an array of arrays where each array
# contains the values from the hash sorted by the original hash keys or
# the passed order of columns (hash slicing)
my @ordered = @{ $required_order // [] }
    ? map { [ @$_{ @{ $required_order } } ] } @{ $chaos }
    : map { [ @$_{sort keys %$_} ] } @{ $chaos };

say join( ",",map { @{ $_ } } @ordered );
