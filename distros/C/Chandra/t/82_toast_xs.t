#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Chandra::Toast;

package MockToastApp;
our @bound;
sub new { bless {}, shift }
sub bind { my ($self, $name, $code) = @_; push @bound, [$name, $code]; return $self }

package MockToastAppDies;
sub new { bless {}, shift }
sub bind { die "no binding here\n" }

package main;

my $app = MockToastApp->new;
Chandra::Toast->reset;

is(Chandra::Toast->show($app, 'hello'), 'toast_1', 'the first toast is toast_1');
is(Chandra::Toast->show($app, "it's \"quoted\""), 'toast_2', 'a message with quotes is escaped and counted on');
Chandra::Toast->reset;
is(Chandra::Toast->show($app, 'hello'), 'toast_1', 'reset starts the ids again');

is(Chandra::Toast->show($app, 'saved', type => 'success', duration => 10), 'toast_2', 'type and duration');
is(scalar @MockToastApp::bound, 0, 'no action, no bind');

is(Chandra::Toast->show($app, 'undo?', action => { label => 'Undo', handler => sub { 'undone' } }), 'toast_3', 'an action with a label and a handler');
is(scalar @MockToastApp::bound, 1, 'the handler is bound');
is($MockToastApp::bound[0][0], '_toast_action_toast_3', 'under the name of the toast');

is(Chandra::Toast->show($app, 'x', action => { label => 'Only' }), 'toast_4', 'a label without a handler is shown but not bound');
is(Chandra::Toast->show($app, 'x', action => { handler => sub { } }), 'toast_5', 'a handler without a label is neither');
is(Chandra::Toast->show($app, 'x', action => { label => undef, handler => undef }), 'toast_6', 'undef label and handler');
is(Chandra::Toast->show($app, 'x', action => 'nope', unknown => 1), 'toast_7', 'an action that is not a hash is ignored');
is(Chandra::Toast->show($app, 'x', 'type'), 'toast_8', 'a key with no value is ignored');
is(scalar @MockToastApp::bound, 1, 'none of those bound anything');

my $dies = MockToastAppDies->new;
is(Chandra::Toast->show($dies, 'x', action => { label => 'L', handler => sub { } }), 'toast_9', 'a dying bind does not stop the toast');
ok(!$@, 'and leaves no error behind');

is(Chandra::Toast->dismiss($app, 'toast_1'), $app, 'dismiss returns the app');

eval { Chandra::Toast->show('not an app', 'x') };
like($@, qr/first argument must be a Chandra::App/, 'a plain string is refused');
eval { Chandra::Toast->show(\'ref', 'x') };
like($@, qr/first argument must be a Chandra::App/, 'an unblessed reference is refused');

done_testing;
