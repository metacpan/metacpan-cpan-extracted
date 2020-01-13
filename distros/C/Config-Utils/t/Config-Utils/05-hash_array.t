use strict;
use warnings;

use Config::Utils qw(hash_array);
use English qw(-no_match_vars);
use Test::More 'tests' => 13;
use Test::NoWarnings;

# Test.
my $self = {
	'config' => {},
	'stack' => [],
};
hash_array($self, ['key'], 'val');
is($self->{'config'}->{'key'}, 'val');

# Test.
$self = {
	'config' => {},
	'stack' => [],
};
hash_array($self, ['key', 'subkey'], 'val');
is(ref $self->{'config'}->{'key'}, 'HASH');
is($self->{'config'}->{'key'}->{'subkey'}, 'val', 'Initialization is {}.');

# Test.
$self = {
	'config' => {
		'key' => {},
	},
	'stack' => [],
};
hash_array($self, ['key', 'subkey'], 'val');
is(ref $self->{'config'}->{'key'}, 'HASH');
is($self->{'config'}->{'key'}->{'subkey'}, 'val',
	'Initialization is key => {}.');

# Test.
$self = {
	'config' => {
		'key' => 'value',
	},
	'set_conflicts' => 0,
	'stack' => [],
};
hash_array($self, ['key', 'subkey'], 'val');
is(ref $self->{'config'}->{'key'}, 'HASH');
is($self->{'config'}->{'key'}->{'subkey'}, 'val');

# Test.
$self = {
	'config' => {
		'key' => 'val1',
	},
	'set_conflicts' => 1,
	'stack' => [],
};
hash_array($self, ['key'], 'val2');
is_deeply(
	$self->{'config'}->{'key'},
	['val1', 'val2'],
	'Multiple values for one key. Initialization is one value.',
);

# Test.
$self = {
	'config' => {
		'key' => [
			'val1',
			'val2',
		],
	},
	'set_conflicts' => 1,
	'stack' => [],
};
hash_array($self, ['key'], 'val3');
is_deeply(
	$self->{'config'}->{'key'},
	['val1', 'val2', 'val3'],
	'Multiple values for one key. Initialization are two values.',
);

# Test.
$self = {
	'config' => {
		'key' => 'value',
	},
	'set_conflicts' => 1,
	'stack' => [],
};
eval {
	hash_array($self, ['key', 'subkey'], 'val');
};
is($EVAL_ERROR, "Conflict in 'key'.\n");

# Test.
$self = {
	'callback' => sub {
		return 1;
	},
	'config' => {},
	'set_conflicts' => 1,
	'stack' => [],
};
hash_array($self, ['key'], 'value');
is_deeply(
	$self->{'config'},
	{
		'key' => 1,
	},
	'Callback test.',
);

# Test.
$self = {
	'callback' => sub {
		return 1;
	},
	'config' => {},
	'set_conflicts' => 1,
	'stack' => [],
};
hash_array($self, ['key'], 'value');
hash_array($self, ['key'], 'value');
is_deeply(
	$self->{'config'},
	{
		'key' => [1, 1],
	},
	'Callback test. Multiple values.',
);
