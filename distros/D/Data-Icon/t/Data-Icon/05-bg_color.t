use strict;
use warnings;

use Data::Icon;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Data::Icon->new;
my $ret = $obj->bg_color;
is($ret, undef, 'Get background color (undef).');

# Test.
$obj = Data::Icon->new(
	'bg_color' => 'grey',
	'char' => decode_utf8('†'),
	'color' => 'red',
);
$ret = $obj->bg_color;
is($ret, 'grey', 'Get background color (grey).');
