use strict;
use warnings;

use Data::OFN::Address;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Data::OFN::Address->new;
is($obj->house_number_type, undef, 'Get house number_type (undef - default).');

# Test.
$obj = Data::OFN::Address->new(
	'house_number_type' => decode_utf8('č.p.'),
);
is($obj->house_number_type, decode_utf8('č.p.'), 'Get house number type (č.p.).');
