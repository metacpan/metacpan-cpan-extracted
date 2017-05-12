#!/usr/bin/env perl

use strict;
use warnings;

#use Data::Dumper::Concise; # For Dumper().
use Data::RenderAsTree;

use Test::More;

# ------------------------------------------------
# Remove things from strings which are run-dependent,
# e.g. memory addresses.
# Warning: This only works if the max_key_length and max_value_length options have not shortened
# the data so much that the '(' and ')' can't be found. In that case with, e.g., 'SCALAR(0x123...',
# $s not parsed as expected and hence not converted into SCALAR().

sub clean
{
	my($s) = @_;
	$s     =~ s/\(.+?\)/\(\)/g;

	return $s;

} # End of clean.

# ------------------------------------------------

my(%source) =
(
	1 =>
	{
		data     => \'s', # Use ' in comment for UltraEdit hiliting.
		expected => <<EOS,
Ref Demo
    |--- SCALAR() [SCALAR 1]
EOS
		literal => q|\'s'|, # Use ' in comment for UltraEdit hiliting.
	},
	2 =>
	{
		data     => {key => \'s'}, # Use ' in comment for UltraEdit hiliting.
		expected => <<EOS,
Ref Demo
    |--- {} [HASH 1]
         |--- key = SCALAR() [SCALAR 2]
              |--- SCALAR() = s [SCALAR 3]
EOS
		literal => q|{key => \'s'}|, # Use ' in comment for UltraEdit hiliting.
	},
);
my($renderer) = Data::RenderAsTree -> new
	(
		attributes => 0,
		title      => 'Ref Demo',
		verbose    => 0,
	);

my($expected);
my($got);
my($i);

for $i (sort keys %source)
{
	$got      = [map{clean($_)} @{$renderer -> render($source{$i}{data})}];
	$expected = [map{clean($_)} split(/\n/, $source{$i}{expected})];

	#diag "\nGot:\n", Dumper($got), "Expected:\n", Dumper($expected);

	is_deeply($got, $expected, 'Rendered');
}

done_testing($i);
