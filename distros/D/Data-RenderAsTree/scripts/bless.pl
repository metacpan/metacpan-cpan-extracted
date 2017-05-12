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
		data     => Tree::DAG_Node -> new({name => 'Root', attributes => {one => 1} }),
		expected => <<EOS,
Bless Demo
    |--- Class = Tree::DAG_Node [BLESS 1]
         |--- {} [HASH 2]
              |--- attributes = {} [HASH 3]
              |    |--- {} [HASH 4]
              |         |--- one = 1 [VALUE 5]
              |--- daughters [ARRAY 6]
              |    |--- 1 = [] [ARRAY 7]
              |--- mother = undef [VALUE 8]
              |--- name = Root [VALUE 9]
EOS
		literal => q|Tree::DAG_Node -> new({name => 'Root', attributes => {one => 1} })|,
	},
	2 =>
	{
		data     => {root => Tree::DAG_Node -> new({name => 'Root', attributes => {one => 1} })},
		expected => <<EOS,
Bless Demo
    |--- {} [HASH 1]
         |--- root = {} [HASH 2]
              |--- Class = Tree::DAG_Node [BLESS 3]
                   |--- {} [HASH 4]
                        |--- attributes = {} [HASH 5]
                        |    |--- {} [HASH 6]
                        |         |--- one = 1 [VALUE 7]
                        |--- daughters [ARRAY 8]
                        |    |--- 1 = [] [ARRAY 9]
                        |--- mother = undef [VALUE 10]
                        |--- name = Root [VALUE 11]
EOS
		literal => q|{root => Tree::DAG_Node -> new({name => 'Root', attributes => {one => 1} })}|,
	},
);
my($renderer) = Data::RenderAsTree -> new
	(
		attributes       => 0,
		max_key_length   => 25,
		max_value_length => 20,
		title            => 'Bless Demo',
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
