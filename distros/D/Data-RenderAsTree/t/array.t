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
		data     => ['a'],
		expected => <<EOS,
Array Demo. Attributes: {}
    |--- 0 = [] [ARRAY 1]. Attributes: {}
         |--- 0 = a [SCALAR 2]. Attributes: {}
EOS
		literal => q|['a']|,
	},
	2 =>
	{
		data     => ['a', 'b'],
		expected => <<EOS,
Array Demo. Attributes: {}
    |--- 0 = [] [ARRAY 1]. Attributes: {}
         |--- 0 = a [SCALAR 2]. Attributes: {}
         |--- 1 = b [SCALAR 3]. Attributes: {}
EOS
		literal => q|['a', 'b']|,
	},
	3 =>
	{
		data     => ['a', 'b', ['c'] ],
		expected => <<EOS,
Array Demo. Attributes: {}
    |--- 0 = [] [ARRAY 1]. Attributes: {}
         |--- 0 = a [SCALAR 2]. Attributes: {}
         |--- 1 = b [SCALAR 3]. Attributes: {}
         |--- 2 = [] [ARRAY 4]. Attributes: {}
              |--- 0 = c [SCALAR 5]. Attributes: {}
EOS
		literal => q|['a', 'b', ['c'] ]|,
	},
	4 =>
	{
		data     => ['a', 'b', ['c', 'd'], 'e', ['f', ['g', 'h', ['i'], 'j'], 'k', 'l'], 'm'],
		expected => <<EOS,
Array Demo. Attributes: {}
    |--- 0 = [] [ARRAY 1]. Attributes: {}
         |--- 0 = a [SCALAR 2]. Attributes: {}
         |--- 1 = b [SCALAR 3]. Attributes: {}
         |--- 2 = [] [ARRAY 4]. Attributes: {}
         |    |--- 0 = c [SCALAR 5]. Attributes: {}
         |    |--- 1 = d [SCALAR 6]. Attributes: {}
         |--- 3 = e [SCALAR 7]. Attributes: {}
         |--- 4 = [] [ARRAY 8]. Attributes: {}
         |    |--- 0 = f [SCALAR 9]. Attributes: {}
         |    |--- 1 = [] [ARRAY 10]. Attributes: {}
         |    |    |--- 0 = g [SCALAR 11]. Attributes: {}
         |    |    |--- 1 = h [SCALAR 12]. Attributes: {}
         |    |    |--- 2 = [] [ARRAY 13]. Attributes: {}
         |    |    |    |--- 0 = i [SCALAR 14]. Attributes: {}
         |    |    |--- 3 = j [SCALAR 15]. Attributes: {}
         |    |--- 2 = k [SCALAR 16]. Attributes: {}
         |    |--- 3 = l [SCALAR 17]. Attributes: {}
         |--- 5 = m [SCALAR 18]. Attributes: {}
EOS
		literal => q|['a', 'b', ['c', 'd'], 'e', ['f', ['g', 'h', ['i'], 'j'], 'k', 'l'], 'm']|,
	},
	5 =>
	{
		data     => [ ['a'] ],
		expected => <<EOS,
Array Demo. Attributes: {}
    |--- 0 = [] [ARRAY 1]. Attributes: {}
         |--- 0 = [] [ARRAY 2]. Attributes: {}
              |--- 0 = a [SCALAR 3]. Attributes: {}
EOS
		literal => q|[ ['a'] ]|,
	},
);
my($renderer) = Data::RenderAsTree -> new
	(
		attributes       => 0,
		max_key_length   => 25,
		max_value_length => 20,
		title            => 'Array Demo',
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
