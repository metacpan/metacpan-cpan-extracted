use strict;
eval { require warnings; };
use Test::More tests => 7;

use_ok('Apache::Action::State');
my $request = { };	# Fake!
my $session = { };	# As good as anything.
my $state = new Apache::Action::State(
				Request	=> $request,
				Session	=> $session,
					);
ok(defined $state, 'Made something ...');
ok(UNIVERSAL::isa($state, 'Apache::Action::State'), '... a state!');
ok($state->error('test'), 'Added an error');
ok($state->errors, 'The error was stored');
ok($state->set('name', 'value'), 'Set a value in the state');
ok($state->get('name') eq 'value', 'Got the value from the state');
