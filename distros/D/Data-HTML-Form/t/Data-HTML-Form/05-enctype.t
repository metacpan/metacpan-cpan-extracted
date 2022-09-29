use strict;
use warnings;

use Data::HTML::Form;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Form->new;
is($obj->enctype, undef, 'Get enctype (undef - default).');

# Test.
$obj = Data::HTML::Form->new(
	'enctype' => 'application/x-www-form-urlencoded',
);
is($obj->enctype, 'application/x-www-form-urlencoded',
	'Get enctype (application/x-www-form-urlencoded).');
