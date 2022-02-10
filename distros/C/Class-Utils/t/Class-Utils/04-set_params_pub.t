use strict;
use warnings;

use Class::Utils qw(set_params_pub);
use English qw(-no_match_vars);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Default Error::Pure module to use.
$ENV{'ERROR_PURE_TYPE'} = 'AllError';

# Test.
my $self = {
	'key' => undef,
};
set_params_pub($self, 'key', 'value');
is($self->{'key'}, 'value', 'Setting right key.');

# Test.
eval {
	set_params_pub($self, 'bad_key', 'value');
};
is($EVAL_ERROR, "Unknown parameter 'bad_key'.\n", 'Setting bad key.');

# Test.
$self = {
	'key' => undef,
};
set_params_pub($self,
	'key' => 'value',
	'_key' => 'value',
);
is_deeply(
	$self,
	{
		'key' => 'value',
	},
	'Setting right keys.',
);
