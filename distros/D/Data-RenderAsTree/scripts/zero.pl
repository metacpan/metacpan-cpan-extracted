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
		data     => 0,
		expected => 0,
		literal => q|0|,
	},
);
my($count)		= 0;
my($successes)	= 0;
my($renderer)	= Data::RenderAsTree -> new
	(
		attributes       => 0,
		max_key_length   => 25,
		max_value_length => 20,
		title            => 'Undef Demo',
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

	$got      = $renderer -> run($source{$i}{data});
	$expected = $source{$i}{expected} ? [split(/\n/, $source{$i}{expected})] : 0;
	$x1			= Dumper($got);
	$x2			= Dumper($expected);
	$result		= $x1 eq $x2;

	$successes++ if ($result);

	print "$i: <$source{$i}{literal}>\n";
	print "# $count: " . ($result ? "OK\n" : "Not OK\n");
}

print "Test count:    $count\n";
print "Success count: $successes\n";
