#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(skip_all);

BEGIN {
	eval {
		require Test::Kwalitee;
		# :optional is not present in all Test::Kwalitee releases; default import runs checks.
		Test::Kwalitee->import;
		1;
	} or skip_all 'Test::Kwalitee is required for this author test';
}
