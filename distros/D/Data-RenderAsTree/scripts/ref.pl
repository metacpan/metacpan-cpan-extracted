#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper::Concise;
use Data::RenderAsTree;

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
Ref Demo. Attributes: {}
    |--- SCALAR() [SCALAR 1]. Attributes: {}
EOS
		literal => q|\'s'|, # Use ' in comment for UltraEdit hiliting.
	},
	2 =>
	{
		data     => {key => \'s'}, # Use ' in comment for UltraEdit hiliting.
		expected => <<EOS,
Ref Demo. Attributes: {}
    |--- {} [HASH 1]. Attributes: {}
         |--- key = SCALAR() [SCALAR 2]. Attributes: {}
              |--- SCALAR() = s [SCALAR 3]. Attributes: {}
EOS
		literal => q|{key => \'s'}|, # Use ' in comment for UltraEdit hiliting.
	},
);
my($count)		= 0;
my($successes)	= 0;
my($renderer)	= Data::RenderAsTree -> new
	(
		attributes => 0,
		title      => 'Ref Demo',
		verbose    => 0,
	);

my($expected);
my($got);
my($i);
my($result);
my($x1, $x2);

for $i (sort keys %source)
{
	$count++;

	$got      = [map{clean($_)} @{$renderer -> render($source{$i}{data})}];
	$expected = [map{clean($_)} split(/\n/, $source{$i}{expected})];
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
