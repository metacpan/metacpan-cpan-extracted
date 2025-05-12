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
Mixup Demo. Attributes: {}
    |--- 0 = [] [ARRAY 1]. Attributes: {}
         |--- {} [HASH 2]. Attributes: {}
              |--- a = b [VALUE 3]. Attributes: {}
EOS
		literal => q||,
	},
	2 =>
	{
		data     => [{a => 'b'}, {c => 'd'}],
		expected => <<EOS,
Mixup Demo. Attributes: {}
    |--- 0 = [] [ARRAY 1]. Attributes: {}
         |--- {} [HASH 2]. Attributes: {}
         |    |--- a = b [VALUE 3]. Attributes: {}
         |--- {} [HASH 4]. Attributes: {}
              |--- c = d [VALUE 5]. Attributes: {}
EOS
		literal => q|[{a => 'b'}, {c => 'd'}]|,
	},
	3 =>
	{
		data     => [{a => 'b'}, ['c' => 'd'] ],
		expected => <<EOS,
Mixup Demo. Attributes: {}
    |--- 0 = [] [ARRAY 1]. Attributes: {}
         |--- {} [HASH 2]. Attributes: {}
         |    |--- a = b [VALUE 3]. Attributes: {}
         |--- 1 = [] [ARRAY 4]. Attributes: {}
              |--- 0 = c [SCALAR 5]. Attributes: {}
              |--- 1 = d [SCALAR 6]. Attributes: {}
EOS
		literal => q|[{a => 'b'}, ['c' => 'd'] ]|,
	},
	4 =>
	{
		data     => {a => ['b', 'c'] },
		expected => <<EOS,
Mixup Demo. Attributes: {}
    |--- {} [HASH 1]. Attributes: {}
         |--- a [ARRAY 2]. Attributes: {}
              |--- 0 = [] [ARRAY 3]. Attributes: {}
                   |--- 0 = b [SCALAR 4]. Attributes: {}
                   |--- 1 = c [SCALAR 5]. Attributes: {}
EOS
		literal => q|{a => ['b', 'c'] }|,
	},
	5 =>
	{
		data     => {a => ['b', 'c'], d => {e => 'f'} },
		expected => <<EOS,
Mixup Demo. Attributes: {}
    |--- {} [HASH 1]. Attributes: {}
         |--- a [ARRAY 2]. Attributes: {}
         |    |--- 0 = [] [ARRAY 3]. Attributes: {}
         |         |--- 0 = b [SCALAR 4]. Attributes: {}
         |         |--- 1 = c [SCALAR 5]. Attributes: {}
         |--- d = {} [HASH 6]. Attributes: {}
              |--- {} [HASH 7]. Attributes: {}
                   |--- e = f [VALUE 8]. Attributes: {}
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
