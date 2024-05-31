use strict;
use warnings;

use Data::HTML::Footer;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Footer->new;
is($obj->author, undef, 'Get author (undef - default).');

# Test.
$obj = Data::HTML::Footer->new(
	'author' => 'Michal',
);
is($obj->author, 'Michal', 'Get author (Michal).');
