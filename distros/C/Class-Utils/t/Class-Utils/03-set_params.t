# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);
use English qw(-no_match_vars);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => undef,
};
set_params($self, 'key', 'value');
is($self->{'key'}, 'value', 'Setting right key.');

# Test.
eval {
	set_params($self, 'bad_key', 'value');
};
is($EVAL_ERROR, "Unknown parameter 'bad_key'.\n", 'Setting bad key.');
