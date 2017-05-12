use strict;

use Test::More tests => 1;

use_ok 'Business::IS::PIN';

diag sprintf q<Testing %s v%s, Perl %f, %s>,
	'Business::IS::PIN',
	$Business::IS::PIN::VERSION,
	$],
	$^X;
