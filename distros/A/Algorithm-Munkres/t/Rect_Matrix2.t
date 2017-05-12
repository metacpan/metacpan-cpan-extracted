# Rect_Matrix2.t version 0.01
#
# Copyright (C) 2005 - 2006
#
# Anagha Kulkarni, University of Minnesota Duluth
# kulka020@d.umn.edu
#
# Ted Pedersen, University of Minnesota Duluth
# tpederse@d.umn.edu

# A script to run tests on the Algorithm::Mukres module.
# This test cases check for rectangular input matrix i.e. MxN matrix.
# The following are among the tests run by this script:
# 1. Try loading the Algorithm::Munkres i.e. is it added to the @INC variable
# 2. Compare the lengths of the Solution array and the Output array.
# 3. Compare each element of the Solution array and the Output array.

use strict;
use warnings;

use Test::More tests => 7;

BEGIN { use_ok('Algorithm::Munkres') };

my @mat = (
	[23, 1],
	[24, 5],
	[1, 34],
	[5, 6],
	[12,56],
	);

my @soln = (1,2,0,3,4);

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

__END__
