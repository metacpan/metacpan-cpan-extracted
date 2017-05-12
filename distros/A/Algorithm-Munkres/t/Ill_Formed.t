# Ill_Formed.t version 0.01
#
# Copyright (C) 2005 - 2006
#
# Anagha Kulkarni, University of Minnesota Duluth
# kulka020@d.umn.edu
#
# Ted Pedersen, University of Minnesota Duluth
# tpederse@d.umn.edu

# A script to run tests on the Algorithm::Mukres module.
# This test cases check for a not well-formed input matrix.
# The following are among the tests run by this script:
# 1. Try loading the Algorithm::Munkres i.e. is it added to the @INC variable
# 2. Check the returned error message.

use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok('Algorithm::Munkres') };

my @mat = (
	[1,2,3],
	[1,2],
	);

my @assign_out = ();
my $soln_out = "Please check the input matrix.\nThe input matrix is not a well-formed matrix!\nThe input matrix has to be rectangular or square matrix.\n";

eval {assign(\@mat,\@assign_out)};

#Compare the lengths of the Solution array and the Output array.
is($soln_out, $@, 'Compare the returned error message.');

__END__

