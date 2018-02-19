use strict;
use warnings;

use Config::Dot;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $c = Config::Dot->new(
	'config' => {
		'key' => 'value',
	},
);
is($c->serialize, 'key=value', 'Serialize befor reset.');
$c->reset;
is($c->serialize, '', 'Serialize after reset.');
