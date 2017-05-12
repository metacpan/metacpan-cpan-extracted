use strict;
eval { require warnings; };
use Test::More tests => 6;

use_ok('Apache::Action::State');
use_ok('Apache::Action');
my $request = { };	# Fake!
my $session = { };	# As good as anything.
my $state = new Apache::Action::State(
				Request	=> $request,
				Session	=> $session,
					);
my $action = new Apache::Action(
				Request	=> $request,
				Session	=> $session,
				State	=> $state,
					);
ok(defined $action, 'Made something ...');
ok(UNIVERSAL::isa($action, 'Apache::Action'), '... a dispatcher!');
ok($state->error('test'), 'Added an error');
ok($state->errors, 'The error was stored');
