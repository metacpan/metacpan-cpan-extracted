use strict;
use warnings;

use Data::Person;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Data::Person->new;
is($obj->sex, undef, 'Get sex (undef - default).');

# Test.
$obj = Data::Person->new(
	'name' => decode_utf8('Michal Josef Špaček'),
	'sex' => 'male',
);
is($obj->sex, 'male', 'Get sex (male).');
