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
Hash Demo. Attributes: {}
    |--- {} [HASH 1]. Attributes: {}
         |--- a = b [VALUE 2]. Attributes: {}
EOS
		literal => q|{a => 'b'}|,
	},
	2 =>
	{
		data     => {a => 'b', c => 'd'},
		expected => <<EOS,
Hash Demo. Attributes: {}
    |--- {} [HASH 1]. Attributes: {}
         |--- a = b [VALUE 2]. Attributes: {}
         |--- c = d [VALUE 3]. Attributes: {}
EOS
		literal => q|{a => 'b', c => 'd'}|,
	},
	3 =>
	{
		data     => {a => 'b', c => 'd', e => {f => 'g', h => 'i'} },
		expected => <<EOS,
Hash Demo. Attributes: {}
    |--- {} [HASH 1]. Attributes: {}
         |--- a = b [VALUE 2]. Attributes: {}
         |--- c = d [VALUE 3]. Attributes: {}
         |--- e = {} [HASH 4]. Attributes: {}
              |--- {} [HASH 5]. Attributes: {}
                   |--- f = g [VALUE 6]. Attributes: {}
                   |--- h = i [VALUE 7]. Attributes: {}
EOS
		literal => q|{a => 'b', c => 'd', e => {f => 'g', h => 'i'} }|,
	},
	4 =>
	{
		data     => {a => {b => 'c'} },
		expected => <<EOS,
Hash Demo. Attributes: {}
    |--- {} [HASH 1]. Attributes: {}
         |--- a = {} [HASH 2]. Attributes: {}
              |--- {} [HASH 3]. Attributes: {}
                   |--- b = c [VALUE 4]. Attributes: {}
EOS
		literal => q|{a => {b => 'c'} }|,
	},
	5 =>
	{
		data     => {a => {b => 'c'}, d => 'e'},
		expected => <<EOS,
Hash Demo. Attributes: {}
    |--- {} [HASH 1]. Attributes: {}
         |--- a = {} [HASH 2]. Attributes: {}
         |    |--- {} [HASH 3]. Attributes: {}
         |         |--- b = c [VALUE 4]. Attributes: {}
         |--- d = e [VALUE 5]. Attributes: {}
EOS
		literal => q|{a => {b => 'c'}, d => 'e'}|,
	},
	6 =>
	{
		data     => {a => {b => {c => 'd'} } },
		expected => <<EOS,
Hash Demo. Attributes: {}
    |--- {} [HASH 1]. Attributes: {}
         |--- a = {} [HASH 2]. Attributes: {}
              |--- {} [HASH 3]. Attributes: {}
                   |--- b = {} [HASH 4]. Attributes: {}
                        |--- {} [HASH 5]. Attributes: {}
                             |--- c = d [VALUE 6]. Attributes: {}
EOS
		literal => q|{a => {b => {c => 'd'} } }|,
	},
	7 =>
	{
		data     => {a => 'b', c => 'd', e => {f => 'g', h => 'i', j => {k => 'l', m => 'n'}, o => 'p'}, q => 'r'},
		expected => <<EOS,
Hash Demo. Attributes: {}
    |--- {} [HASH 1]. Attributes: {}
         |--- a = b [VALUE 2]. Attributes: {}
         |--- c = d [VALUE 3]. Attributes: {}
         |--- e = {} [HASH 4]. Attributes: {}
         |    |--- {} [HASH 5]. Attributes: {}
         |         |--- f = g [VALUE 6]. Attributes: {}
         |         |--- h = i [VALUE 7]. Attributes: {}
         |         |--- j = {} [HASH 8]. Attributes: {}
         |         |    |--- {} [HASH 9]. Attributes: {}
         |         |         |--- k = l [VALUE 10]. Attributes: {}
         |         |         |--- m = n [VALUE 11]. Attributes: {}
         |         |--- o = p [VALUE 12]. Attributes: {}
         |--- q = r [VALUE 13]. Attributes: {}
EOS
		literal => q|{a => 'b', c => 'd', e => {f => 'g', h => 'i', j => {k => 'l', m => 'n'}, o => 'p'}, q => 'r'}|,
	},
);
my($count)		= 0;
my($successes)	= 0;
my($renderer)	= Data::RenderAsTree -> new
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
my($result);
my($x1, $x2);

for $i (sort keys %source)
{
	$count++;

	$got      = $renderer -> render($source{$i}{data});
	$expected = [split(/\n/, $source{$i}{expected})];
	$x1			= Dumper($got);
	$x2			= Dumper($expected);
	$result		= $x1 eq $x2;

	$successes++ if ($result);

	print "$i: $source{$i}{literal}\n";
	print "Got: \n", Dumper($got), "Expected: \n", Dumper($expected);
	print "# $count: " . ($result ? "OK\n" : "Not OK\n");
}

print "Test count:    $count\n";
print "Success count: $successes\n";
