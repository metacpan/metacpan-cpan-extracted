use strict;
use warnings;

use Test::More;
use Time::HiRes qw(usleep);

my $numtests = int(rand(50)) + 1;

plan(tests => $numtests);

for my $testnum (1 .. $numtests)
{
	my $tnum = "Test number $testnum";
	(int(rand(1000)) % 10 == 0) ? fail($tnum) : pass($tnum); 
	usleep(int(rand(500_000)) + 200_000);
}

done_testing();
