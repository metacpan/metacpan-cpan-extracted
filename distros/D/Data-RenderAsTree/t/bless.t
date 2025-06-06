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
		data     => Tree::DAG_Node -> new({name => 'Root', attributes => {one => 1} }),
		expected => <<EOS,
Bless Demo. Attributes: {}
    |--- Class = Tree::DAG_Node [BLESS 1]. Attributes: {}
         |--- {} [HASH 2]. Attributes: {}
              |--- attributes = {} [HASH 3]. Attributes: {}
              |    |--- {} [HASH 4]. Attributes: {}
              |         |--- one = 1 [VALUE 5]. Attributes: {}
              |--- daughters [ARRAY 6]. Attributes: {}
              |    |--- 1 = [] [ARRAY 7]. Attributes: {}
              |--- mother = undef [VALUE 8]. Attributes: {}
              |--- name = Root [VALUE 9]. Attributes: {}
EOS
		literal => q|Tree::DAG_Node -> new({name => 'Root', attributes => {one => 1} })|,
	},
	2 =>
	{
		data     => {root => Tree::DAG_Node -> new({name => 'Root', attributes => {one => 1} })},
		expected => <<EOS,
Bless Demo. Attributes: {}
    |--- {} [HASH 1]. Attributes: {}
         |--- root = {} [HASH 2]. Attributes: {}
              |--- Class = Tree::DAG_Node [BLESS 3]. Attributes: {}
                   |--- {} [HASH 4]. Attributes: {}
                        |--- attributes = {} [HASH 5]. Attributes: {}
                        |    |--- {} [HASH 6]. Attributes: {}
                        |         |--- one = 1 [VALUE 7]. Attributes: {}
                        |--- daughters [ARRAY 8]. Attributes: {}
                        |    |--- 1 = [] [ARRAY 9]. Attributes: {}
                        |--- mother = undef [VALUE 10]. Attributes: {}
                        |--- name = Root [VALUE 11]. Attributes: {}
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

	is_deeply($got, $expected, 'Rendered');
}

done_testing($i);
