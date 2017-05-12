# Pragmas.
use strict;
use warnings;

# Modules.
use Config::Dot::Array;
use English qw(-no_match_vars);
use Test::More 'tests' => 10;
use Test::NoWarnings;

# Test.
my $obj = Config::Dot::Array->new;
isa_ok($obj, 'Config::Dot::Array');

# Test.
$obj = Config::Dot::Array->new(
	'callback' => sub {
		return 1;
	},
);
isa_ok($obj, 'Config::Dot::Array');

# Test.
eval {
	Config::Dot::Array->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Unknown parameter.');

# Test.
eval {
	Config::Dot::Array->new('something' => 'value');
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Unknown parameter \'something\'.');

# Test.
eval {
	Config::Dot::Array->new('config' => '');
};
is($EVAL_ERROR, "Bad 'config' parameter.\n",
	'Bad \'config\' parameter.');

# Test.
eval {
	Config::Dot::Array->new(
		'config' => {
			'key' => \*STDOUT,
		},
	);
};
is($EVAL_ERROR, "Bad 'config' parameter.\n",
	'Bad \'config\' parameter.');

# Test.
eval {
	Config::Dot::Array->new(
		'config' => {
			'key' => [sub {}],
		},
	);
};
is($EVAL_ERROR, "Bad 'config' parameter.\n",
	'Bad \'config\' parameter.');

# Test.
$obj = Config::Dot::Array->new(
	'config' => {
		'key' => [{
			'subkey1' => 'val1',
		}, {
			'subkey2' => 'val2',
		}],
	},
);
isa_ok($obj, 'Config::Dot::Array');

# Test.
eval {
	Config::Dot::Array->new(
		'callback' => 'FOOBAR',
	);
};
is($EVAL_ERROR, "Parameter 'callback' isn't code reference.\n",
	'Parameter \'callback\' isn\'t code reference.');
