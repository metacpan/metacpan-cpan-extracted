use strict;
use warnings;

use Test::More;

my $numtests = int(rand(5)) + 1;

plan(tests => $numtests);

if (grep(/^NOTE$/, @ARGV))
{
	note("NOTE: COMMANDLINE: '$_'\n") foreach (@ARGV);
}

if (grep(/^DIAG$/, @ARGV))
{
	diag("DIAG: COMMANDLINE: '$_'\n") foreach (@ARGV);
}

for my $testnum (1 .. $numtests)
{
	pass($testnum . " (" . __FILE__ . ":" . __LINE__ . ")");
	sleep(int(rand(3)));
}

done_testing() if $Test::More::VERSION >= 0.88;
