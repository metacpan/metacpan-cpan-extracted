use strict;
use warnings;

use Data::Icon;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Data::Icon->new;
my $ret = $obj->char;
is($ret, undef, 'Get character (undef).');

# Test.
$obj = Data::Icon->new(
	'char' => decode_utf8('†'),
	'color' => 'red',
);
$ret = $obj->char;
is($ret, decode_utf8('†'), 'Get character (†).');
