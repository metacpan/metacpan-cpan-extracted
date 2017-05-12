# Pragmas.
use strict;
use warnings;

# Modules.
use Config::Utils qw(conflict);
use English qw(-no_match_vars);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $self = {
	'stack' => [],
};
eval {
	conflict($self, {'key' => 'value'}, 'key');
};
is($EVAL_ERROR, '');

# Test.
$self->{'set_conflicts'} = 1;
eval {
	conflict($self, {'key' => 'value'}, 'key');
};
is($EVAL_ERROR, "Conflict in 'key'.\n");
