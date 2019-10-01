#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/ say /;

my $column_order = [ @ARGV ];
my $data = [
	{
		1 => 'Liz',
		2 => 'Nat',
		3 => 'Lee',
	},
];

# transform an array of hashes into an array of arrays where each array
# contains the values from the hash sorted by the original hash keys or
# the passed order of columns (hash slicing)
my @field_data = @{ $column_order // [] }
    ? map { [ @$_{ @{ $column_order } } ] } @{ $data }
    : map { [ @$_{sort keys %$_} ] } @{ $data };

say join( ",",map { @{ $_ } } @field_data );
