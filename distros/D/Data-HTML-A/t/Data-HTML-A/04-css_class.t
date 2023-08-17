use strict;
use warnings;

use Data::HTML::A;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::A->new;
is($obj->css_class, undef, 'Get CSS class (undef).');

# Test.
$obj = Data::HTML::A->new(
	'css_class' => 'button-nice',
);
is($obj->css_class, 'button-nice', 'Get CSS class (button-nice).');
