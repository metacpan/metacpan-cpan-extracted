# Normal.t version 0.01
#
# Copyright (C) 2005 - 2006
#
# Anagha Kulkarni, University of Minnesota Duluth
# kulka020@d.umn.edu
#
# Ted Pedersen, University of Minnesota Duluth
# tpederse@d.umn.edu

# A script to run tests on the Algorithm::Mukres module.
# The following are among the tests run by this script:
# This test case checks the module with normal input values, i.e. without fractions/negative values/zeros etc.
# 1. Try loading the Algorithm::Munkres i.e. is it added to the @INC variable
# 2. Compare the lengths of the Solution array and the Output array.
# 3. Compare each element of the Solution array and the Output array.

use strict;
use warnings;

use Test::More tests => 11;

BEGIN { use_ok('Algorithm::Munkres') };

my @mat = (
	[ 12, 3, 7, 4, 10],
	[ 5, 10, 6, 2, 4],
	[ 8, 5, 1, 4, 9],
	[ 15, 2, 7, 8, 10],
	[ 7, 2, 8, 1, 12],
	);

my @soln = (3,4,2,1,0);

my @assign_out = ();
my $i = 0;

assign(\@mat,\@assign_out);

#Compare the lengths of the Solution array and the Output array.
is($#soln, $#assign_out, 'Compare the lengths of the Solution array and the Output array.');

#Compare each element of the Solution array and the Output array.
for($i = 0; $i <= $#assign_out; $i++)
{
	is($soln[$i], $assign_out[$i], "Compare $i element of the Solution array and the Output array")	
}

@mat = (
	[2,4,7],
	[3,9,5],
	[8,2,9],
	);

@soln = (0,2,1);

@assign_out = ();

assign(\@mat,\@assign_out);

#Compare the lengths of the Solution array and the Output array.
is($#soln, $#assign_out, 'Compare the lengths of the Solution array and the Output array.');

#Compare each element of the Solution array and the Output array.
for($i = 0; $i <= $#assign_out; $i++)
{
	is($soln[$i], $assign_out[$i], "Compare $i element of the Solution array and the Output array")	
}

#eq_array(\@assign_out,\@out,"Are these equal ?");

__END__
