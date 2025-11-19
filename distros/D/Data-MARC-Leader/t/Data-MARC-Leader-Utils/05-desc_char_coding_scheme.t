use strict;
use warnings;

use Data::MARC::Leader::Utils;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::MARC::Leader::Utils->new;
my $ret = $obj->desc_char_coding_scheme('a');
is($ret, 'UCS/Unicode',
	'Get character coding scheme (a = UCS/Unicode - eng).');

# Test.
$obj = Data::MARC::Leader::Utils->new(
	'lang' => 'ces',
);
$ret = $obj->desc_char_coding_scheme('a');
is($ret, 'UCS/Unicode',
	'Get description of bibliographic level (a = UCS/Unicode - ces).');
