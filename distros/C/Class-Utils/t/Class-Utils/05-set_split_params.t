# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_split_params);
use English qw(-no_match_vars);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => undef,
};
my @ret = set_split_params($self, 'key', 'value');
is($self->{'key'}, 'value', 'Setting right key.');
is_deeply(
	\@ret,
	[],
	'No other params.',
);

# Test.
$self = {
	'key' => undef,
};
@ret = set_split_params($self,
	'key', 'value',
	'foo', 'bar',
);
is($self->{'key'}, 'value', 'Setting right key.');
is_deeply(
	\@ret,
	['foo', 'bar'],
	'Other params, which not supported by object.',
);

