use strict;
use warnings;

use Data::MARC::Leader::Utils;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Data::MARC::Leader::Utils->new;
my $ret = $obj->desc_encoding_level(' ');
is($ret, 'Full level',
	'Get encoding level (␣ = Full level).');

# Test.
$obj = Data::MARC::Leader::Utils->new(
	'lang' => 'ces',
);
$ret = $obj->desc_encoding_level(' ');
is($ret, decode_utf8('úplná úroveň'),
	'Get encoding level (␣ = úplná úroveň - ces).');
