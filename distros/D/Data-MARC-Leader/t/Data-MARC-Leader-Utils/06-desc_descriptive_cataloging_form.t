use strict;
use warnings;

use Data::MARC::Leader::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::MARC::Leader::Utils->new;
my $ret = $obj->desc_descriptive_cataloging_form('a');
is($ret, 'AACR 2',
	'Get descriptive cataloging form (a = AACR 2).');
