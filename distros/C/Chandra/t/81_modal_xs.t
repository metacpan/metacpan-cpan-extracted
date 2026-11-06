#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Chandra::Modal;

# A mock app has no _webview, so the XS builds its JS and discards it, and
# every bind it asks for is recorded here.
package MockModalApp;
our @bound;
sub new { bless {}, shift }
sub bind { my ($self, $name, $code) = @_; push @bound, [$name, $code]; return $self }

package MockModalAppDies;
sub new { bless {}, shift }
sub bind { die "no binding here\n" }

package main;

my $app = MockModalApp->new;
Chandra::Modal->reset;

# --- show: the first call injects the JS, ids count from 1 ---
is(Chandra::Modal->show($app), 'modal_1', 'a bare show returns the first id');
is(Chandra::Modal->show($app), 'modal_2', 'the next show counts on');
Chandra::Modal->reset;
is(Chandra::Modal->show($app), 'modal_1', 'reset starts the ids again');

# --- every keyword ---
my $id = Chandra::Modal->show($app,
    title    => "It's a title",
    content  => '<p>content</p>',
    message  => 'a message',
    width    => 500,
    closable => 0,
    backdrop => 0,
    input    => { label => 'Name', value => 'Bob' },
    buttons  => [
        { label => 'Cancel', class => 'secondary', action => 'close' },
        { label => 'OK', class => 'primary', action => sub { 'ok' } },
        'not a hash',
        { label => undef, class => undef, action => undef },
        {},
    ],
);
is($id, 'modal_2', 'show with every keyword returns the next id');
is(scalar @MockModalApp::bound, 1, 'one button had a code action, so one bind was asked for');
is($MockModalApp::bound[0][0], '_modal_btn_modal_2_1', 'the handler is named for the modal and the button');
is(ref $MockModalApp::bound[0][1], 'CODE', 'and binds the code given');

# --- input with only a value, and with neither ---
is(Chandra::Modal->show($app, input => { value => 'v' }), 'modal_3', 'an input with a value alone');
is(Chandra::Modal->show($app, input => { label => undef, value => undef }), 'modal_4', 'an input with undef label and value');

# --- keywords that are not what they claim to be are skipped ---
is(Chandra::Modal->show($app, buttons => 'nope', input => 'nope', unknown => 1), 'modal_5', 'a buttons or input that is not a reference is ignored');

# --- an odd trailing key is dropped ---
is(Chandra::Modal->show($app, 'title'), 'modal_6', 'a key with no value is ignored');

# --- a bind that dies is swallowed ---
my $dies = MockModalAppDies->new;
is(Chandra::Modal->show($dies, buttons => [ { label => 'x', action => sub { } } ]), 'modal_7', 'a dying bind does not stop the modal');
ok(!$@, 'and leaves no error behind');

# --- close returns the app ---
is(Chandra::Modal->close($app, 'modal_1'), $app, 'close returns the app for chaining');

# --- confirm builds two buttons and calls show ---
Chandra::Modal->reset;
@MockModalApp::bound = ();
is(Chandra::Modal->confirm($app), 'modal_1', 'confirm with defaults');
is(scalar @MockModalApp::bound, 0, 'no code actions, no binds');
is(Chandra::Modal->confirm($app, title => 'T', message => 'M', on_ok => sub { 1 }, on_cancel => sub { 0 }), 'modal_2', 'confirm with both callbacks');
is(scalar @MockModalApp::bound, 2, 'both callbacks are bound');
is_deeply([ map { $_->[0] } @MockModalApp::bound ], [ '_modal_btn_modal_2_0', '_modal_btn_modal_2_1' ], 'cancel first, then ok');
is(Chandra::Modal->confirm($app, on_ok => 'not a ref', on_cancel => 'nor this', 'odd'), 'modal_3', 'confirm ignores callbacks that are not references and an odd key');

# --- prompt builds an input and two buttons ---
@MockModalApp::bound = ();
is(Chandra::Modal->prompt($app), 'modal_4', 'prompt with defaults');
is(Chandra::Modal->prompt($app, title => 'Name', label => 'Your name', value => 'x', on_submit => sub { 1 }), 'modal_5', 'prompt with every option');
is(scalar @MockModalApp::bound, 1, 'the submit callback is bound');
is($MockModalApp::bound[0][0], '_modal_btn_modal_5_1', 'as the second button');
is(Chandra::Modal->prompt($app, on_submit => 'nope', 'odd'), 'modal_6', 'prompt ignores a submit that is not a reference and an odd key');

done_testing;
