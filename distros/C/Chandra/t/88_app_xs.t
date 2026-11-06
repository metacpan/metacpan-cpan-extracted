#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Chandra::App;
use Chandra::Toast;
use Chandra::Theme;
use Chandra::Splash;

# A webview that records what the app asks of it. Its loop returns 0 for as
# many rounds as it was told, then 1, which ends run().
package MockWV;
sub new { my ($class, %o) = @_; bless { eval_js => [], dispatch_eval_js => [], bound => {}, loops => $o{loops} || 0, inits => 0, exits => 0, titles => [] }, $class }
sub eval_js          { push @{ $_[0]{eval_js} }, $_[1] }
sub dispatch_eval_js { push @{ $_[0]{dispatch_eval_js} }, $_[1] }
sub init             { $_[0]{inits}++ }
sub loop             { my $self = shift; return $self->{loops}-- > 0 ? 0 : 1 }
sub exit             { $_[0]{exits}++ }
sub terminate        { $_[0]{terminated}++ }
sub bind             { $_[0]{bound}{ $_[1] } = $_[2] }
sub set_title        { push @{ $_[0]{titles} }, $_[1] }
sub title            { 'Mock' }

package Renders;
sub new { bless { html => $_[1] }, $_[0] }
sub render { $_[0]{html} }

package NoRender;
sub new { bless {}, shift }

package main;

my @warned;
local $SIG{__WARN__} = sub { push @warned, $_[0] };
my $dir = tempdir(CLEANUP => 1);

sub mock_app {
    my %o = @_;
    my $app = Chandra::App->new(title => 'Test App');
    $app->{_webview} = MockWV->new(%o);
    return $app;
}
sub bare_app {
    my $app = Chandra::App->new;
    $app->{_webview} = undef;
    return $app;
}

# --- an app whose webview is gone ---
{
    my $app = bare_app();
    ok(!defined $app->title, 'no title without a window');
    ok(!defined $app->url, 'no url');
    is($app->width, 800, 'the default width');
    is($app->height, 600, 'the default height');
    is($app->resizable, 1, 'resizable by default');
    is($app->debug, 0, 'not debugging');
    ok(!defined $app->webview, 'webview is undef');
    is($app->bind('x', sub { }), $app, 'bind without a webview returns the app');
    $app->navigate('/nowhere');
    ok(!defined $app->eval('1'), 'eval without a webview is undef');
    $app->dispatch_eval('1');
    $app->update('#x', 'y');
    is($app->set_title('T'), $app, 'set_title returns the app');
    $app->inject_css('a{}');
    $app->fullscreen(1);
    $app->set_color(1, 2, 3);
    $app->terminate;
    is($app->init, $app, 'init without a webview still marks the app started');
    is($app->{_started}, 1, 'started');
    $app->exit;
    is($app->{_started}, 0, 'and exit clears it');
    $app->_inject_route_css_js(0);
    $app->_inject_post_content_js(0);
    $app->refresh;
    pass('refresh without a webview does nothing');
    eval { $app->run };
    like($@, qr/No webview available/, 'run without a webview croaks');
}

# --- tick callbacks replace each other ---
{
    my $app = mock_app();
    is($app->on_tick(sub { 1 }), $app, 'on_tick returns the app');
    $app->on_tick(sub { 2 });
    is($app->{_tick_cb}->(), 2, 'the later callback replaces the first');
}

# --- theme, toast and dismiss_toast, with and without errors ---
{
    my $app = mock_app();
    is($app->theme('dark'), $app, 'theme returns the app');
    is($app->toast('hello'), 'toast_1', 'toast returns the id');
    is($app->dismiss_toast('toast_1'), $app, 'dismiss_toast returns the app');
    {
        no warnings 'redefine';
        local *Chandra::Theme::apply = sub { die "theme boom\n" };
        local *Chandra::Toast::show = sub { die "show boom\n" };
        local *Chandra::Toast::dismiss = sub { die "dismiss boom\n" };
        @warned = ();
        $app->theme('dark');
        ok(!defined $app->toast('x'), 'a toast that dies is undef');
        $app->dismiss_toast('x');
        is_deeply([ map { /^(Chandra::App::\w+): (\w+ boom)/ ? "$1 $2" : $_ } @warned ],
            [ 'Chandra::App::theme theme boom', 'Chandra::App::toast show boom', 'Chandra::App::dismiss_toast dismiss boom' ],
            'each failure is a warning naming the method');
    }
}

# --- set_content with objects ---
{
    my $app = mock_app();
    $app->set_content(Renders->new('<b>r</b>'));
    is($app->{_html}, '<b>r</b>', 'an object that renders gives its rendering');
    my $plain = NoRender->new;
    $app->set_content($plain);
    like($app->{_html}, qr/^NoRender=HASH/, 'an object that cannot render is stringified');
    $app->set_content('<i>s</i>');
    is($app->{_html}, '<i>s</i>', 'a string is kept');
}

# --- routes: matching and rendering edge cases ---
{
    my $app = mock_app();
    is_deeply([ $app->_match_route('/x') ], [], 'no routes match nothing');
    is_deeply($app->{_current_route_opts}, {}, 'and leave empty options');
    $app->route('/u/:id', sub { my %p = @_; "user $p{id}" }, css => 'c', js => 'j');
    $app->route('/plain', sub { 'plain' });
    $app->route('/undef', undef);
    $app->route('/obj', sub { Renders->new('<obj>') });
    $app->route('/bad', sub { NoRender->new });
    push @{ $app->{_routes} }, 'not a ref', [ '/only' ], [ '/noopts', sub { 'noopts' }, 'not a hash' ];
    is($app->_render_route('/u/7'), 'user 7', 'a parameter route renders with its parameter');
    is_deeply($app->{_current_route_opts}, { css => 'c', js => 'j' }, 'and sets the options');
    is($app->_render_route('/plain'), 'plain', 'a plain route past the odd entries');
    is($app->_render_route('/noopts'), 'noopts', 'a route whose options are not a hash gets empty ones');
    is_deeply($app->{_current_route_opts}, {}, 'empty');
    is($app->_render_route('/undef'), '<h1>404 - Not Found</h1>', 'a route with no handler is not found');
    is($app->_render_route('/missing'), '<h1>404 - Not Found</h1>', 'and so is a path that matches nothing');
    is($app->_render_route('/obj'), '<obj>', 'a handler returning an object renders it');
    like($app->_render_route('/bad'), qr/^NoRender=HASH/, 'one that cannot render is stringified');
    $app->not_found(sub { 'custom 404' });
    is($app->_render_route('/missing'), 'custom 404', 'a not_found handler is used');

    $app->layout(sub { "[$_[0]]" });
    is($app->_render_route('/plain'), '[plain]', 'a layout wraps the body');
    $app->layout(sub { Renders->new("{$_[0]}") });
    is($app->_render_route('/plain'), '{plain}', 'a layout returning an object renders it');
    $app->layout(sub { NoRender->new });
    like($app->_render_route('/plain'), qr/^NoRender=HASH/, 'a layout object that cannot render is stringified');
}

# --- injection of css, js, extensions and widgets ---
{
    my $app = mock_app();
    my $wv = $app->{_webview};
    $app->{_global_css} = [];
    $app->{_global_js} = [];
    $app->_inject_post_content_js(0);
    ok(!scalar(grep { /chandra-global/ } @{ $wv->{eval_js} }), 'empty css and js lists inject nothing');
    $app->{_global_css} = [ undef, 'b{}' ];
    $app->{_global_js} = [ undef, 'x()' ];
    $app->_inject_post_content_js(0);
    ok(scalar(grep { /chandra-global-css.*b\{\}/ } @{ $wv->{eval_js} }), 'an undef css entry is skipped and the next kept');
    ok(scalar(grep { /chandra-global-js.*x\(\)/ } @{ $wv->{eval_js} }), 'the same for js');

    $app->extend_bridge('extone', 'window.extone = 1;');
    $app->extend_bridge('exttwo', 'window.exttwo = 2;', depends => ['extone']);
    $app->extend_bridge('extthree', 'window.extthree = 3;', depends => 'not a list', other => 1);
    $app->extend_bridge('extfour', 'window.extfour = 4;', depends => []);
    $app->extend_bridge('extsix', 'window.extsix = 6;', 'odd');
    @{ $wv->{eval_js} } = ();
    $app->_inject_post_content_js(0);
    ok(scalar(grep { /extone/ } @{ $wv->{eval_js} }), 'registered extensions are injected');

    $app->devtools;
    $app->protocol;
    @{ $wv->{eval_js} } = ();
    $app->_inject_post_content_js(0);
    pass('disabled devtools and an empty protocol are walked');

    $app->shortcut('ctrl+s', sub { 'save' }, description => 'save');
    $app->on_file_drop(sub { });
    $app->context_menu('.menu', [ { label => 'A', action => sub { } } ]);
    @{ $wv->{eval_js} } = ();
    @{ $wv->{dispatch_eval_js} } = ();
    $app->_inject_post_content_js(1);
    ok(scalar @{ $wv->{dispatch_eval_js} } >= 3, 'with dispatch the shortcut, drag and drop and context menu scripts are dispatched');
    $app->_inject_post_content_js(0);
    ok(scalar @{ $wv->{eval_js} } >= 1, 'without dispatch they are injected through the widgets');
}

# --- on_reload and refresh ---
{
    my $app = mock_app();
    is($app->on_reload(sub { }), $app, 'on_reload returns the app');
    $app->route('/', sub { 'home' });
    $app->{_current_route} = '/';
    $app->refresh;
    ok(scalar(grep { /home/ } @{ $app->{_webview}{eval_js} }), 'refresh re-renders the current route');
}

# --- the dialog and tray singletons ---
{
    my $app = mock_app();
    my $tray = $app->tray(icon => 'i.png');
    isa_ok($tray, 'Chandra::Tray', 'tray()');
    is($app->tray, $tray, 'and is kept');
    my $dlg = $app->dialog;
    isa_ok($dlg, 'Chandra::Dialog', 'dialog()');
    is($app->dialog, $dlg, 'and is kept');
}

# --- run with a blocking loop ---
{
    my $app = mock_app();
    my $wv = $app->{_webview};
    $app->tray(icon => 'i.png')->show;
    is($app->tray->{_pending}, 1, 'a tray shown before run is pending');
    $app->route('/', sub { 'home' });
    $app->run;
    is($wv->{inits}, 1, 'run initialises the webview');
    is($wv->{exits}, 1, 'and exits it');
    is($app->{_started}, 0, 'and is no longer started');
    is(ref $wv->{bound}{__chandra_refresh}, 'CODE', 'the refresh callback is bound');
    is(ref $wv->{bound}{__chandra_navigate}, 'CODE', 'and the navigate callback, since there are routes');
    is($app->tray->{_pending}, 0, 'the pending tray was shown');
    ok(scalar(grep { /document\.write.*home/ } @{ $wv->{eval_js} }), 'the initial route was written');
    is($app->{_current_route}, '/', 'the current route is the root');

    my $html = mock_app();
    $html->set_content('<p>static</p>');
    $html->run;
    ok(scalar(grep { /document\.write.*static/ } @{ $html->{_webview}{eval_js} }), 'static content is written when there are no routes');
}

# --- run with a polling loop ---
{
    my $app = mock_app(loops => 3);
    my $ticks = 0;
    $app->on_tick(sub { $ticks++; die "tick boom\n" if $ticks == 2 });
    my $watched = "$dir/watched.txt";
    open my $fh, '>', $watched or die; print $fh "x\n"; close $fh;
    $app->watch($watched, sub { });
    my $hub = $app->hub(name => "apprun-$$");
    my $client = $app->client(name => 'inner', hub => "apprun-$$");
    $app->run;
    is($ticks, 3, 'the tick callback ran once a round, and its death was swallowed');
    $client->close;
    $hub->close;
}

# --- notify without a title ---
{
    my $app = mock_app();
    @warned = ();
    is($app->notify(body => 'no title'), 0, 'notify without a title is 0');
    like($warned[0], qr/notify: title is required/, 'and warns');
}

# --- stores ---
{
    my $app = mock_app();
    my $named = $app->store('named');
    isa_ok($named, 'Chandra::Store', 'a named store');
    is($app->store('named'), $named, 'and is kept');
    local $ENV{HOME} = $dir;
    my $real = Chandra::App->new(title => 'Test App');
    my $own = $real->store;
    like($own->path, qr{/test_app/store\.json$}, 'an unnamed store takes its name from the title');
    is($real->store, $own, 'and is kept too');

    my $bare = bare_app();
    like($bare->store->path, qr{/chandra/store\.json$}, 'with no title the store is chandra');
    my $odd = Chandra::App->new(title => '!!My App--Title 2!!');
    like($odd->store->path, qr{/my_app--title_2/store\.json$}, 'punctuation runs become single underscores, hyphens stay, and the ends are trimmed');
    my $dies = Chandra::App->new(title => 'Dies');
    {
        no warnings 'redefine';
        local *Chandra::App::title = sub { die "no title\n" };
        like($dies->store->path, qr{/chandra/store\.json$}, 'a title that dies gives chandra');
    }
}

# --- windows ---
{
    my $app = mock_app();
    is($app->window_count, 0, 'no windows yet');
    is_deeply([ $app->windows ], [], 'and none listed');
    ok(!defined $app->window_by_id('w1'), 'and none found');
    my $w = $app->open_window(title => 'First', id => 'w1', width => 200, height => 100);
    isa_ok($w, 'Chandra::Window', 'open_window');
    is($app->window_count, 1, 'one window');
    is($app->window_by_id('w1'), $w, 'found by id');
    ok(!defined $app->window_by_id('nope'), 'an unknown id is undef');
    push @{ $app->{_windows} }, undef, 'string', { noid => 1 };
    is_deeply([ grep { defined } $app->windows ], [ $w, 'string', { noid => 1 } ], 'windows skips the undef entry');
    ok(!defined $app->window_by_id('nope'), 'the odd entries do not match an id');
    is($app->on_close(sub { }), $app, 'on_close returns the app');
    $app->open_window(title => 'Second');
    is($app->window_count, 5, 'a second window is added to the list');
    $w->close;
}

# --- assets, clipboard, drag and drop, context menus ---
{
    my $app = mock_app();
    eval { $app->assets };
    like($@, qr/assets\(\) requires a root directory/, 'assets needs a root the first time');
    my $assets = $app->assets($dir, prefix => '/static');
    isa_ok($assets, 'Chandra::Assets', 'assets with a root');
    is($app->assets, $assets, 'and is kept');
    is($app->clipboard, 'Chandra::Clipboard', 'clipboard names its class');
    my $dd = $app->drag_drop;
    isa_ok($dd, 'Chandra::DragDrop', 'drag_drop');
    is($app->drag_drop, $dd, 'and is kept');
    is($app->on_file_drop(sub { }), $app, 'on_file_drop returns the app');
    is($app->drop_zone('#z', sub { }), $app, 'drop_zone returns the app');
    my $cm = $app->context_menu_instance;
    isa_ok($cm, 'Chandra::ContextMenu', 'context_menu_instance');
    is($app->context_menu_instance, $cm, 'and is kept');
    is($app->context_menu('.a', sub { [] }), $app, 'a context menu with a callback');
    is($app->context_menu('.b', [ { label => 'x', action => sub { } } ]), $app, 'one with items');
    is($app->context_menu('.c', 'neither'), $app, 'and one with neither attaches statically');
}

# --- splash ---
{
    my $app = mock_app();
    my @init;
    my $s = $app->splash(title => 'Loading', init => sub { push @init, $_[0] });
    isa_ok($s, 'Chandra::Splash', 'splash');
    is($init[0], $s, 'the init callback got the splash');
    @warned = ();
    $app->splash(title => 'Dies', init => sub { die "init boom\n" });
    like($warned[0], qr/splash init callback died: init boom/, 'a dying init warns');
    ok(defined $app->splash(title => 'Plain', init => 'not code'), 'an init that is not code is ignored');
    {
        no warnings 'redefine';
        local *Chandra::Splash::new = sub { undef };
        ok(!defined $app->splash(title => 'None'), 'no splash object gives undef');
    }
}

# --- a hole in a depends list is an unknown extension, checked when the
# table is next resolved, so this comes last ---
{
    my $app = mock_app();
    my $holes = []; $#$holes = 1; $holes->[0] = 'extone';
    eval { $app->extend_bridge('exthole', 'window.exthole = 1;', depends => $holes) };
    eval { $app->_inject_post_content_js(0) };
    like($@, qr/depends on unknown extension ''/, 'a hole in the depends list is an unknown extension when the scripts are generated');
}

done_testing;
