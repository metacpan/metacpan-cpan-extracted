use strict;
use warnings;

use Config::Dot;
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
my $obj = Config::Dot->new;
isa_ok($obj, 'Config::Dot');

# Test.
$obj = Config::Dot->new(
	'callback' => sub {
		return 1;
	},
);
isa_ok($obj, 'Config::Dot');
$obj->parse('key=value'); # Run callback because coverage of test.

# Test.
eval {
	Config::Dot->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Unknown parameter.');
clean();

# Test.
eval {
	Config::Dot->new('something' => 'value');
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Unknown parameter \'something\'.');
clean();

# Test.
eval {
	Config::Dot->new('config' => '');
};
is($EVAL_ERROR, "Bad 'config' parameter.\n",
	'Bad \'config\' parameter.');
clean();

# Test.
eval {
	Config::Dot->new(
		'config' => {
			'key' => [],
		},
	);
};
is($EVAL_ERROR, "Bad 'config' parameter.\n",
	'Bad \'config\' parameter.');
clean();

# Test.
eval {
	Config::Dot->new(
		'config' => {
			'key' => {
				'subkey' => 'value',
			},
		},
	);
};
isa_ok($obj, 'Config::Dot');

# Test.
eval {
	Config::Dot->new(
		'callback' => 'FOOBAR',
	);
};
is($EVAL_ERROR, "Parameter 'callback' isn't code reference.\n",
	'Parameter \'callback\' isn\'t code reference.');
clean();
