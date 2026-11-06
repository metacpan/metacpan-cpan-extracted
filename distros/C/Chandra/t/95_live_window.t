#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# These tests open a real window and a tray icon on the desktop, so they run
# only when asked for: CHANDRA_LIVE_TESTS=1 make test
#
# The bundled webview registers its Objective-C classes by name on init, so a
# process can initialise one webview only, and the app's exit at the end of
# run ends the process. Everything therefore happens inside one app run, with
# the plan declared from its last tick, and the notification goes first in a
# child of its own.
plan skip_all => 'set CHANDRA_LIVE_TESTS=1 to run the tests that open windows' unless $ENV{CHANDRA_LIVE_TESTS};
plan skip_all => 'the live tests need a display' if $^O ne 'darwin' && $^O ne 'MSWin32' && !$ENV{DISPLAY} && !$ENV{WAYLAND_DISPLAY};

use Chandra;
use Chandra::App;
use Chandra::Modal;
use Chandra::Toast;
use Chandra::Window;
use Chandra::Notify;

my @warned;
local $SIG{__WARN__} = sub { push @warned, $_[0] };

# --- a notification, in a child so that a refusal cannot take the suite down ---
SKIP: {
    skip 'fork is needed', 1 if $^O eq 'MSWin32';
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        close STDERR;
        my $app = Chandra::App->new(title => 'Notify');
        my $sent = $app->notify(title => 'Chandra live test', body => 'hello', icon => 'none', sound => 1, timeout => 1000);
        my $raw = Chandra::Notify::_xs_send({ title => 'Chandra raw', body => 'b', icon => 'i', sound => 0, timeout => 1 });
        exit(($sent && $raw) ? 0 : 1);
    }
    waitpid $pid, 0;
    ok(1, 'a notification was ' . ($? == 0 ? 'sent' : "refused ($?)"));
}

# --- one app, run for a few ticks, doing everything it can while live ---
{
    my $app = Chandra::App->new(title => 'Live App', width => 320, height => 200);
    my $wv = $app->webview;
    $app->route('/', sub { '<p id="p">home</p>' });
    $app->route('/other', sub { 'other' });
    my $child = Chandra::Window->new(id => 'named', title => 'Child', width => 200, height => 100, parent => $app, content => '<script>window.external.invoke("from-child")</script>');
    my @got;
    my @low;
    $wv->_set_callback(sub { push @got, $_[0] });
    my $n = 0;
    my $tray;
    $app->on_tick(sub {
        $n++;
        if ($n == 1) {
            $wv->init;
            pass('init on the running window is a no-op');
            is($wv->eval_js('1 + 1'), 0, 'eval_js on the live window returns 0');
            $wv->dispatch_eval_js('document.title = "dispatched"');
            $wv->set_title('Retitled');
            is($wv->title, 'Retitled', 'set_title keeps the title');
            $wv->resize(330, 210);
            $wv->inject_css('body { margin: 0 }');
            $wv->set_fullscreen(0);
            $wv->set_color(10, 20, 30, 255);
            is($wv->loop(0), 0, 'a non-blocking loop turn says to go on');
            Chandra::_xs_dispatch('{"type":"call","id":1,"method":"nothing"}');
            pass('a dispatch while the window is live resolves through the webview');

            is($app->eval('1'), 0, 'eval on the live app');
            $app->dispatch_eval('1');
            $app->update('#p', 'changed');
            $app->set_title('Live App 2');
            $app->inject_css('p { color: red }');
            $app->fullscreen(0);
            $app->set_color(1, 2, 3);
            $app->navigate('/other');
            $app->refresh;
            Chandra::Modal->show($app, title => 'Live modal');
            Chandra::Toast->show($app, 'live toast');
            Chandra::_xs_dispatch('{"type":"call","id":2,"method":"nothing"}');

            $tray = $app->tray(icon => '', tooltip => 'Live tray');
            $tray->add_item('One', sub { push @got, 'tray one' });
            $tray->add_separator;
            $tray->add_submenu('More', [ { label => 'Sub', handler => sub { push @got, 'tray sub' } } ]);
            is($tray->show, $tray, 'the tray shows on the live app');
            ok($tray->is_active, 'and is active');
            $tray->set_tooltip('Live tray 2');
            $tray->update_item('One', label => 'Uno');
            $wv->_xs_test_tray_menu(1);
            $wv->_xs_test_tray_menu(-1);
            $wv->_xs_test_tray_menu(99);
            $tray->on_click(sub { push @got, 'tray click' });
            $tray->_sync;
            $tray->remove;
            ok(!$tray->is_active, 'and removed');
            ok(scalar(grep { /tray one/ } @got), 'the tray menu callback ran its handler');

            is($wv->_tray_create('', 'tip', '[{"id":1,"label":"A"},{"separator":1}]', sub { push @low, $_[0] }), 0, 'a low-level tray is created');
            $wv->_tray_create('', 'tip', '[]', sub { push @low, $_[0] });
            $wv->_tray_create('', 'tip', '[]', undef);
            ok($wv->_tray_active, 'and active');
            $wv->_tray_update('', 'tip2', '[{"id":2,"label":"B"}]');
            $wv->_xs_test_tray_menu(2);
            $wv->_tray_destroy;
            $wv->_tray_destroy;
            $wv->_tray_update('', 'tip3', '[]');
            ok(!$wv->_tray_active, 'and destroyed, twice without harm');
            $wv->_tray_create('', 'tip', '[{"id":3,"label":"C"}]', sub { push @low, $_[0] });
            $wv->_xs_test_tray_menu(3);
            is_deeply(\@low, [2, 3], 'the low-level tray callback ran for the trays that had one');

            my $spare = Chandra->new;
            is($spare->_tray_create('', 'spare', '[{"id":9,"label":"S"}]', sub { push @low, $_[0] }), 0, 'a window never initialised can still carry a tray');
            undef $spare;
            pass('and freeing it takes the tray down');

            $child->show;
            $child->eval('window.external.invoke("from-child-eval")');
        }
        if ($n >= 20) {
            diag("messages from the child window: " . join(', ', grep { /child/ } @got)) if grep { /child/ } @got;
            $child->close;
            $wv->terminate;
            pass('terminate on the window ends the next loop turn');
            done_testing;
            $app->terminate;
        }
    });
    $app->run;
}
