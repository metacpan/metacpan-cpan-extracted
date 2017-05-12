use strict;
use warnings;

use Test::More;

my $numtests = 40;

plan(tests => $numtests);

for my $testnum (1 .. $numtests)
{
	pass($testnum . " (" . __FILE__ . ":" . __LINE__ . ")");
	sleep(1);
	BAIL_OUT("Bailing out on request") if grep(/^BAILOUT$/, @ARGV);
}

done_testing() if $Test::More::VERSION >= 0.88;
