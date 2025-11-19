use strict;
use warnings;

use Data::MARC::Leader::Utils;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Data::MARC::Leader::Utils->new;
my $ret = $obj->desc_bibliographic_level('a');
is($ret, 'Monographic component part',
	'Get description of bibliographic level (a = Monographic component part - eng).');

# Test.
$obj = Data::MARC::Leader::Utils->new(
	'lang' => 'ces',
);
$ret = $obj->desc_bibliographic_level('a');
is($ret, decode_utf8('analytická část (monografická)'),
	'Get description of bibliographic level (a = analytická část (monografická) - ces).');
