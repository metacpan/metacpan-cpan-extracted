#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper::Concise;
use Data::RenderAsTree;

# ------------------------------------------------

my(%source) =
(
	1 =>
	{
		data     => {a => 'b'},
		expected => <<EOS,
Hash Demo
    |--- {} [HASH 1]
         |--- a = b [VALUE 2]
EOS
		literal => q|{a => 'b'}|,
	},
	2 =>
	{
		data     => {a => 'b', c => 'd'},
		expected => <<EOS,
Hash Demo
    |--- {} [HASH 1]
         |--- a = b [VALUE 2]
         |--- c = d [VALUE 3]
EOS
		literal => q|{a => 'b', c => 'd'}|,
	},
	3 =>
	{
		data     => {a => 'b', c => 'd', e => {f => 'g', h => 'i'} },
		expected => <<EOS,
Hash Demo
    |--- {} [HASH 1]
         |--- a = b [VALUE 2]
         |--- c = d [VALUE 3]
         |--- e = {} [HASH 4]
              |--- {} [HASH 5]
                   |--- f = g [VALUE 6]
                   |--- h = i [VALUE 7]
EOS
		literal => q|{a => 'b', c => 'd', e => {f => 'g', h => 'i'} }|,
	},
	4 =>
	{
		data     => {a => {b => 'c'} },
		expected => <<EOS,
Hash Demo
    |--- {} [HASH 1]
         |--- a = {} [HASH 2]
              |--- {} [HASH 3]
                   |--- b = c [VALUE 4]
EOS
		literal => q|{a => {b => 'c'} }|,
	},
	5 =>
	{
		data     => {a => {b => 'c'}, d => 'e'},
		expected => <<EOS,
Hash Demo
    |--- {} [HASH 1]
         |--- a = {} [HASH 2]
         |    |--- {} [HASH 3]
         |         |--- b = c [VALUE 4]
         |--- d = e [VALUE 5]
EOS
		literal => q|{a => {b => 'c'}, d => 'e'}|,
	},
	6 =>
	{
		data     => {a => {b => {c => 'd'} } },
		expected => <<EOS,
Hash Demo
    |--- {} [HASH 1]
         |--- a = {} [HASH 2]
              |--- {} [HASH 3]
                   |--- b = {} [HASH 4]
                        |--- {} [HASH 5]
                             |--- c = d [VALUE 6]
EOS
		literal => q|{a => {b => {c => 'd'} } }|,
	},
	7 =>
	{
		data     => {a => 'b', c => 'd', e => {f => 'g', h => 'i', j => {k => 'l', m => 'n'}, o => 'p'}, q => 'r'},
		expected => <<EOS,
Hash Demo
    |--- {} [HASH 1]
         |--- a = b [VALUE 2]
         |--- c = d [VALUE 3]
         |--- e = {} [HASH 4]
         |    |--- {} [HASH 5]
         |         |--- f = g [VALUE 6]
         |         |--- h = i [VALUE 7]
         |         |--- j = {} [HASH 8]
         |         |    |--- {} [HASH 9]
         |         |         |--- k = l [VALUE 10]
         |         |         |--- m = n [VALUE 11]
         |         |--- o = p [VALUE 12]
         |--- q = r [VALUE 13]
EOS
		literal => q|{a => 'b', c => 'd', e => {f => 'g', h => 'i', j => {k => 'l', m => 'n'}, o => 'p'}, q => 'r'}|,
	},
);
my($renderer) = Data::RenderAsTree -> new
	(
		attributes       => 0,
		max_key_length   => 25,
		max_value_length => 20,
		title            => 'Hash Demo',
		verbose          => 0,
	);

my($expected);
my($got);
my($i);

for $i (sort keys %source)
{
	$got      = $renderer -> render($source{$i}{data});
	$expected = [split(/\n/, $source{$i}{expected})];

	print "$i: $source{$i}{literal}\n";
	print Dumper($got);
}
