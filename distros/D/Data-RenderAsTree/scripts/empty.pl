#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper::Concise;
use Data::RenderAsTree;

use Test::More;

# ------------------------------------------------

my(%source) =
(
	1 =>
	{
		data     => '',
		expected => <<EOS,
Empty Demo
    |---  [VALUE 1]
EOS
		literal => q||,
	},
);
my($renderer) = Data::RenderAsTree -> new
	(
		attributes       => 0,
		max_key_length   => 25,
		max_value_length => 20,
		title            => 'Empty Demo',
		verbose          => 0,
	);

my($expected);
my($got);
my($i);

for $i (sort keys %source)
{
	$got      = $renderer -> run($source{$i}{data});
	$expected = [split(/\n/, $source{$i}{expected})];

	print "$i: $source{$i}{literal}\n";
	print Dumper($got);
}
