#!/usr/bin/env perl

use strict;
use warnings;

use Data::RenderAsTree;

use Test::More;

# ------------------------------------------------

my(%source) =
(
	1 =>
	{
		data     => [{a => 'b'}],
		expected => <<EOS,
Mixup Demo
    |--- 0 = [] [ARRAY 1]
         |--- {} [HASH 2]
              |--- a = b [VALUE 3]
EOS
		literal => q||,
	},
	2 =>
	{
		data     => [{a => 'b'}, {c => 'd'}],
		expected => <<EOS,
Mixup Demo
    |--- 0 = [] [ARRAY 1]
         |--- {} [HASH 2]
         |    |--- a = b [VALUE 3]
         |--- {} [HASH 4]
              |--- c = d [VALUE 5]
EOS
		literal => q|[{a => 'b'}, {c => 'd'}]|,
	},
	3 =>
	{
		data     => [{a => 'b'}, ['c' => 'd'] ],
		expected => <<EOS,
Mixup Demo
    |--- 0 = [] [ARRAY 1]
         |--- {} [HASH 2]
         |    |--- a = b [VALUE 3]
         |--- 1 = [] [ARRAY 4]
              |--- 0 = c [SCALAR 5]
              |--- 1 = d [SCALAR 6]
EOS
		literal => q|[{a => 'b'}, ['c' => 'd'] ]|,
	},
	4 =>
	{
		data     => {a => ['b', 'c'] },
		expected => <<EOS,
Mixup Demo
    |--- {} [HASH 1]
         |--- a [ARRAY 2]
              |--- 0 = [] [ARRAY 3]
                   |--- 0 = b [SCALAR 4]
                   |--- 1 = c [SCALAR 5]
EOS
		literal => q|{a => ['b', 'c'] }|,
	},
	5 =>
	{
		data     => {a => ['b', 'c'], d => {e => 'f'} },
		expected => <<EOS,
Mixup Demo
    |--- {} [HASH 1]
         |--- a [ARRAY 2]
         |    |--- 0 = [] [ARRAY 3]
         |         |--- 0 = b [SCALAR 4]
         |         |--- 1 = c [SCALAR 5]
         |--- d = {} [HASH 6]
              |--- {} [HASH 7]
                   |--- e = f [VALUE 8]
EOS
		literal => q|{a => ['b', 'c'], d => {e => 'f'} }|,
	},
);
my($renderer) = Data::RenderAsTree -> new
	(
		attributes       => 0,
		max_key_length   => 25,
		max_value_length => 20,
		title            => 'Mixup Demo',
		verbose          => 0,
	);

my($expected);
my($got);
my($i);

for $i (sort keys %source)
{
	$got      = $renderer -> render($source{$i}{data});
	$expected = [split(/\n/, $source{$i}{expected})];

	is_deeply($got, $expected, 'Rendered');
}

done_testing($i);
