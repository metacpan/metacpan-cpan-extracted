use strict;
use warnings;

use Data::HTML::Footer;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Footer->new;
is($obj->height, undef, 'Get height (undef - default).');

# Test.
$obj = Data::HTML::Footer->new(
	'height' => '40px',
);
is($obj->height, '40px', 'Get height (40px).');
