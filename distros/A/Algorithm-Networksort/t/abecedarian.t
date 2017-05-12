use strict;

use Algorithm::Networksort;
use Test::More;
require "t/zero_one.pl";

#
# "It can be a primer for teaching reading and spelling and more loosely
# any listing in alphabetical order."
#      World Wide Words: Abecedarian
# http://www.worldwidewords.org/weirdwords/ww-abe2.htm
#
# Test file created to check the algorithms together. Since we now have a method
# to limit the size of the test once the package is out of the author's hands,
# it's now easier to combine the various tests into one file.
#
# The tests for the 'best' comparator set have their own files since these
# comparators were created by different individuals using different methods.
# It is more sensible to test them individually.
#
# The file may be run by itself with "Build test --test_files=t/abecedarian.t"
#
our $author_testing = $ENV{AUTHOR_TESTING};
our @input_range = $author_testing? (3..17): (3..10);
our @algorithms = nwsrt_algorithms();

plan tests => (scalar @input_range  * scalar @algorithms);

for my $algorithm (@algorithms)
{
	for my $inputs (@input_range)
	{
		my $nw = nwsrt(inputs => $inputs, algorithm => $algorithm);
		my $status = zero_one($nw);
		is($status, "pass", $nw->title() . ": $status");
	}
}

