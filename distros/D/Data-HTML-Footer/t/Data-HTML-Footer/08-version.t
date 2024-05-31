use strict;
use warnings;

use Data::HTML::Footer;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Footer->new;
is($obj->version, undef, 'Get version (undef - default).');

# Test.
$obj = Data::HTML::Footer->new(
	'version' => 0.07,
);
is($obj->version, 0.07, 'Get version (0.07).');
