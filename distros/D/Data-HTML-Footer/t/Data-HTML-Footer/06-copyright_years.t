use strict;
use warnings;

use Data::HTML::Footer;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Footer->new;
is($obj->copyright_years, undef, 'Get copyright years (undef - default).');

# Test.
$obj = Data::HTML::Footer->new(
	'copyright_years' => '2022-2024',
);
is($obj->copyright_years, '2022-2024', 'Get copyright years (2022-2024).');
