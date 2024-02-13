use strict;
use warnings;

use Data::MARC::Leader::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::MARC::Leader::Utils->new;
my $ret = $obj->desc_char_coding_scheme('a');
is($ret, 'UCS/Unicode',
	'Get character coding scheme (a = UCS/Unicode).');
