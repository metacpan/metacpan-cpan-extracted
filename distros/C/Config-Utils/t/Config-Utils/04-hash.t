use strict;
use warnings;

use Config::Utils qw(hash);
use English qw(-no_match_vars);
use Test::More 'tests' => 12;
use Test::NoWarnings;

# Test.
my $self = {
	'config' => {},
	'stack' => [],
};
hash($self, ['key'], 'val');
is($self->{'config'}->{'key'}, 'val');

# Test.
$self = {
	'config' => {},
	'stack' => [],
};
hash($self, ['key', 'subkey'], 'val');
is(ref $self->{'config'}->{'key'}, 'HASH');
is($self->{'config'}->{'key'}->{'subkey'}, 'val', 'Initialization is {}.');

# Test.
$self = {
	'config' => {
		'key' => {},
	},
	'stack' => [],
};
hash($self, ['key', 'subkey'], 'val');
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
hash($self, ['key'], 'val');
is($self->{'config'}->{'key'}, 'val');

# Test.
$self = {
	'config' => {
		'key' => 'value',
	},
	'set_conflicts' => 0,
	'stack' => [],
};
hash($self, ['key', 'subkey'], 'val');
is(ref $self->{'config'}->{'key'}, 'HASH');
is($self->{'config'}->{'key'}->{'subkey'}, 'val');

# Test.
$self = {
	'config' => {
		'key' => 'value',
	},
	'set_conflicts' => 1,
	'stack' => [],
};
eval {
	hash($self, ['key'], 'val');
};
is($EVAL_ERROR, "Conflict in 'key'.\n");

# Test.
$self = {
	'config' => {
		'key' => 'value',
	},
	'set_conflicts' => 1,
	'stack' => [],
};
eval {
	hash($self, ['key', 'subkey'], 'val');
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
hash($self, ['key'], 'value');
is($self->{'config'}->{'key'}, '1', 'Callback test.');

