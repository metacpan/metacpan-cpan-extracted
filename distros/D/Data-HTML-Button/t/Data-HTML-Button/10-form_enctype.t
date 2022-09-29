use strict;
use warnings;

use Data::HTML::Button;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Button->new;
is($obj->form_enctype, undef, 'Get form enctype (undef - default).');

# Test.
$obj = Data::HTML::Button->new(
	'form_enctype' => 'application/x-www-form-urlencoded',
);
is($obj->form_enctype, 'application/x-www-form-urlencoded',
	'Get form enctype (application/x-www-form-urlencoded).');
