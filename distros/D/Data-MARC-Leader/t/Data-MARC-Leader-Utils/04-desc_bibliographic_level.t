use strict;
use warnings;

use Data::MARC::Leader::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::MARC::Leader::Utils->new;
my $ret = $obj->desc_bibliographic_level('a');
is($ret, 'Monographic component part',
	'Get description of bibliographic level (a = Monographic component part).');
