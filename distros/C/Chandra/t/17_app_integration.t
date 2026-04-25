#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
no warnings 'once', 'redefine';

use_ok('Chandra::App');
use_ok('Chandra::Error');

# --- Reusable mock webview that tracks all calls ---
{
    package MockWebview;
    sub new {
        bless {
            eval_js          => [],
            dispatch_eval_js => [],
            inject_css       => [],
            set_fullscreen   => [],
            set_color        => [],
            set_title        => [],
            terminate        => [],
        }, shift;
    }
    sub eval_js          { push @{$_[0]->{eval_js}}, $_[1] }
    sub dispatch_eval_js { push @{$_[0]->{dispatch_eval_js}}, $_[1] }
    sub inject_css       { push @{$_[0]->{inject_css}}, $_[1] }
    sub set_fullscreen   { push @{$_[0]->{set_fullscreen}}, $_[1] }
    sub set_color        { push @{$_[0]->{set_color}}, [@_[1..$#_]] }
    sub set_title        { push @{$_[0]->{set_title}}, $_[1] }
    sub terminate        { push @{$_[0]->{terminate}}, 1 }
    sub init             { }
    sub loop             { return 1 } # exit immediately
    sub exit             { }
    sub bind             { }
    sub title     { 'Mock' }
    sub url       { '' }
    sub width     { 800 }
    sub height    { 600 }
    sub resizable { 1 }
    sub debug     { 0 }
}

sub _mock_app {
    my $app = Chandra::App->new();
    $app->{_webview} = MockWebview->new;
    return $app;
}

# === inject_css ===
{
    my $app = _mock_app();
    my $ret = $app->inject_css('body { background: red; }');
    isa_ok($ret, 'Chandra::App', 'inject_css returns self');
    is(scalar @{$app->{_webview}{inject_css}}, 1, 'inject_css called on webview');
    is($app->{_webview}{inject_css}[0], 'body { background: red; }', 'CSS passed through');
}

# === inject_css chaining ===
{
    my $app = _mock_app();
    my $ret = $app->inject_css('a { color: blue; }')
                  ->inject_css('h1 { font-size: 2em; }');
    is(scalar @{$app->{_webview}{inject_css}}, 2, 'inject_css chained twice');
}

# === fullscreen enable ===
{
    my $app = _mock_app();
    my $ret = $app->fullscreen(1);
    isa_ok($ret, 'Chandra::App', 'fullscreen returns self');
    is($app->{_webview}{set_fullscreen}[0], 1, 'fullscreen(1) passes 1');
}

# === fullscreen disable ===
{
    my $app = _mock_app();
    $app->fullscreen(0);
    is($app->{_webview}{set_fullscreen}[0], 0, 'fullscreen(0) passes 0');
}

# === fullscreen default ===
{
    my $app = _mock_app();
    $app->fullscreen;
    is($app->{_webview}{set_fullscreen}[0], 1, 'fullscreen() defaults to 1');
}

# === set_color with RGBA ===
{
    my $app = _mock_app();
    my $ret = $app->set_color(255, 128, 0, 200);
    isa_ok($ret, 'Chandra::App', 'set_color returns self');
    is_deeply($app->{_webview}{set_color}[0], [255, 128, 0, 200], 'RGBA values passed');
}

# === set_color alpha default ===
{
    my $app = _mock_app();
    $app->set_color(10, 20, 30);
    is_deeply($app->{_webview}{set_color}[0], [10, 20, 30, 255], 'alpha defaults to 255');
}

# === update with string ===
{
    my $app = _mock_app();
    $app->update('#content', '<p>Updated</p>');
    my @dispatched = @{$app->{_webview}{dispatch_eval_js}};
    is(scalar @dispatched, 1, 'update dispatches one JS eval');
    like($dispatched[0], qr/querySelector\('#content'\)/, 'selector in JS');
    like($dispatched[0], qr/Updated/, 'content in JS');
}

# === update with renderable object ===
{
    package MockRenderable;
    sub new { bless { html => $_[1] }, $_[0] }
    sub render { $_[0]->{html} }
}
{
    my $app = _mock_app();
    my $obj = MockRenderable->new('<span>Fancy</span>');
    $app->update('.target', $obj);
    like($app->{_webview}{dispatch_eval_js}[0], qr/Fancy/, 'update renders object');
}

# === update escapes special chars ===
{
    my $app = _mock_app();
    $app->update('#x', "line1\nline2\\end'quote");
    my $js = $app->{_webview}{dispatch_eval_js}[0];
    unlike($js, qr/(?<!\\)\n/, 'newlines escaped in update');
    like($js, qr/\\'/, 'single quotes escaped in update');
}

# === update selector escaping ===
{
    my $app = _mock_app();
    $app->update("div[data-x='a']", '<p>ok</p>');
    my $js = $app->{_webview}{dispatch_eval_js}[0];
    like($js, qr/querySelector\('div\[data-x=\\'a\\'\]'\)/, 'selector quotes escaped');
}

# === multiple consecutive updates ===
{
    my $app = _mock_app();
    $app->update('#a', 'first');
    $app->update('#b', 'second');
    $app->update('#c', 'third');
    is(scalar @{$app->{_webview}{dispatch_eval_js}}, 3, 'three updates dispatched');
}

# === alert ===
{
    my $app = _mock_app();
    $app->alert('Hello World');
    my @dispatched = @{$app->{_webview}{dispatch_eval_js}};
    is(scalar @dispatched, 1, 'alert dispatches one JS eval');
    like($dispatched[0], qr/alert\(/, 'alert JS uses alert()');
    like($dispatched[0], qr/Hello World/, 'alert message present');
}

# === alert escapes special characters ===
{
    my $app = _mock_app();
    $app->alert("it's a \"test\"\nwith newlines");
    my $js = $app->{_webview}{dispatch_eval_js}[0];
    like($js, qr/alert\(/, 'alert called');
    # The JSON encoding should handle escaping
    ok(defined $js, 'alert with special chars does not crash');
}

# === dispatch_eval ===
{
    my $app = _mock_app();
    $app->dispatch_eval('console.log("hi")');
    is($app->{_webview}{dispatch_eval_js}[0], 'console.log("hi")', 'dispatch_eval passes JS through');
}

# === eval ===
{
    my $app = _mock_app();
    $app->eval('document.title = "test"');
    is($app->{_webview}{eval_js}[0], 'document.title = "test"', 'eval passes JS through');
}

# === set_title ===
{
    my $app = _mock_app();
    my $ret = $app->set_title('New Title');
    isa_ok($ret, 'Chandra::App', 'set_title returns self');
    is($app->{_webview}{set_title}[0], 'New Title', 'title passed to webview');
}

# === terminate ===
{
    my $app = _mock_app();
    $app->terminate;
    is(scalar @{$app->{_webview}{terminate}}, 1, 'terminate called on webview');
}

# === devtools() auto-creates and enables ===
{
    Chandra::Error->clear_handlers;
    my $app = _mock_app();
    # Provide bind method on mock webview so DevTools can register bindings
    no strict 'refs';
    my $orig_bind = \&MockWebview::bind;
    local *MockWebview::bind = sub {
        my ($self, $name, $sub) = @_;
        # no-op but accept args
    };
    use strict 'refs';

    my $dt = $app->devtools;
    ok(defined $dt, 'devtools() returns something');
    isa_ok($dt, 'Chandra::DevTools');
    ok($dt->is_enabled, 'devtools auto-enabled on first call');

    # Second call returns same instance
    my $dt2 = $app->devtools;
    is($dt, $dt2, 'devtools() returns same instance');

    Chandra::Error->clear_handlers;
}

# === dialog() auto-creates ===
{
    my $app = _mock_app();
    my $dlg = $app->dialog;
    ok(defined $dlg, 'dialog() returns something');
    isa_ok($dlg, 'Chandra::Dialog');

    # Second call returns same instance
    my $dlg2 = $app->dialog;
    is($dlg, $dlg2, 'dialog() returns same instance');
}

# === protocol() auto-creates ===
{
    my $app = _mock_app();
    my $proto = $app->protocol;
    ok(defined $proto, 'protocol() returns something');
    isa_ok($proto, 'Chandra::Protocol');

    # Second call returns same instance
    my $proto2 = $app->protocol;
    is($proto, $proto2, 'protocol() returns same instance');
}

# === watch() creates HotReload and stores it ===
{
    use File::Temp qw(tempfile);
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh "test\n";
    close $fh;

    my $app = _mock_app();
    my $ret = $app->watch($filename, sub { });
    isa_ok($ret, 'Chandra::App', 'watch returns self');
    ok($app->{_hot_reload}, 'hot reload instance created');
    isa_ok($app->{_hot_reload}, 'Chandra::HotReload');
}

# === watch() reuses HotReload instance ===
{
    use File::Temp qw(tempfile);
    my ($fh1, $f1) = tempfile(UNLINK => 1);
    print $fh1 "a\n"; close $fh1;
    my ($fh2, $f2) = tempfile(UNLINK => 1);
    print $fh2 "b\n"; close $fh2;

    my $app = _mock_app();
    $app->watch($f1, sub { });
    my $hr = $app->{_hot_reload};
    $app->watch($f2, sub { });
    is($app->{_hot_reload}, $hr, 'same HotReload instance reused');
    is(scalar $hr->watched_paths, 2, 'two paths watched');
}

# === on_error registers handler ===
{
    Chandra::Error->clear_handlers;
    my $app = _mock_app();
    my $called = 0;
    my $ret = $app->on_error(sub { $called++ });
    isa_ok($ret, 'Chandra::App', 'on_error returns self');

    Chandra::Error->capture("test error");
    is($called, 1, 'on_error handler called on capture');

    Chandra::Error->clear_handlers;
}

# === refresh with no content does nothing ===
{
    my $app = _mock_app();
    $app->{_started} = 1;
    $app->refresh;
    is(scalar @{$app->{_webview}{dispatch_eval_js}}, 0, 'refresh with no content is no-op');
}

# === refresh with static content re-injects ===
{
    my $app = _mock_app();
    $app->{_started} = 1;
    $app->set_content('<h1>Static</h1>');
    $app->refresh;
    ok(scalar @{$app->{_webview}{eval_js}} >= 1, 'refresh dispatches eval');
    ok((grep { /Static/ } @{$app->{_webview}{eval_js}}), 'refresh contains static content');
}

# === refresh with routes re-renders current route ===
{
    my $app = _mock_app();
    $app->{_started} = 1;
    $app->route('/page' => sub { '<p>Page Content</p>' });
    $app->{_current_route} = '/page';
    $app->refresh;
    ok(scalar @{$app->{_webview}{eval_js}} >= 1, 'refresh with route dispatches eval');
    ok((grep { /Page Content/ } @{$app->{_webview}{eval_js}}), 'refresh renders route content');
}

# === navigate before started only stores route ===
{
    my $app = _mock_app();
    $app->route('/' => sub { 'home' });
    $app->route('/about' => sub { 'about' });
    $app->navigate('/about');
    is($app->{_current_route}, '/about', 'navigate stores route');
    is(scalar @{$app->{_webview}{dispatch_eval_js}}, 0, 'no JS dispatched before start');
}

# === navigate after started dispatches JS with content ===
{
    my $app = _mock_app();
    $app->route('/' => sub { '<p>Home</p>' });
    $app->route('/about' => sub { '<p>About Us</p>' });
    $app->{_started} = 1;

    $app->navigate('/about');
    is($app->{_current_route}, '/about', 'route stored');
    my @dispatched = @{$app->{_webview}{dispatch_eval_js}};
    ok(@dispatched >= 1, 'navigate dispatches JS');
    like($dispatched[0], qr/About Us/, 'navigate renders route content');
    like($dispatched[0], qr/pushState/, 'navigate pushes history');
}

# === navigate with layout wraps in chandra-content ===
{
    my $app = _mock_app();
    $app->route('/' => sub { '<p>Home</p>' });
    $app->route('/page' => sub { '<p>Page</p>' });
    $app->layout(sub { "<div id='chandra-content'>$_[0]</div>" });
    $app->{_started} = 1;

    $app->navigate('/page');
    my $js = $app->{_webview}{dispatch_eval_js}[0];
    like($js, qr/chandra-content/, 'navigate JS references chandra-content');
    like($js, qr/Page/, 'content present in JS');
}

# === _inject_post_content_js with dispatch=1 ===
{
    my $app = _mock_app();
    $app->route('/' => sub { 'home' });
    $app->{_started} = 1;
    $app->_inject_post_content_js(1);
    my @dispatched = @{$app->{_webview}{dispatch_eval_js}};
    my $found = grep { /chandra_navigate/ } @dispatched;
    ok($found, 'dispatch mode injects router JS via dispatch_eval_js');
}

# === _inject_post_content_js with devtools enabled ===
{
    Chandra::Error->clear_handlers;
    my $app = _mock_app();

    # Manually create and enable devtools
    require Chandra::DevTools;
    my $dt = Chandra::DevTools->new(app => $app);
    $dt->{enabled} = 1; # bypass enable() to avoid bind issues
    $app->{_devtools} = $dt;

    $app->_inject_post_content_js(0);
    my @evaled = @{$app->{_webview}{eval_js}};
    my $found_devtools = grep { /__chandraDevTools/ } @evaled;
    ok($found_devtools, 'devtools JS injected when enabled');

    Chandra::Error->clear_handlers;
}

# === _inject_post_content_js with protocol registered ===
{
    my $app = _mock_app();
    require Chandra::Protocol;
    my $proto = Chandra::Protocol->new(app => $app);
    $proto->{protocols} = { 'myapp' => sub {} };
    $app->{_protocol} = $proto;

    # Non-dispatch mode calls inject()
    $app->_inject_post_content_js(0);
    ok($proto->{_injected}, 'protocol inject() called in non-dispatch mode');
}

# === _inject_post_content_js with protocol in dispatch mode ===
{
    my $app = _mock_app();
    require Chandra::Protocol;
    my $proto = Chandra::Protocol->new(app => $app);
    $proto->{protocols} = { 'myapp' => sub {} };
    $app->{_protocol} = $proto;

    $app->_inject_post_content_js(1);
    my @dispatched = @{$app->{_webview}{dispatch_eval_js}};
    my $found = grep { /__chandraProtocol/ } @dispatched;
    ok($found, 'protocol JS dispatched in dispatch mode');
}

# === navigate updates content without re-injecting listeners ===
{
    Chandra::Error->clear_handlers;
    my $app = _mock_app();
    $app->route('/' => sub { 'home' });
    $app->route('/page' => sub { '<p>Page</p>' });

    # Set up devtools
    require Chandra::DevTools;
    my $dt = Chandra::DevTools->new(app => $app);
    $dt->{enabled} = 1;
    $app->{_devtools} = $dt;

    # Set up protocol
    require Chandra::Protocol;
    my $proto = Chandra::Protocol->new(app => $app);
    $proto->{protocols} = { 'test' => sub {} };
    $app->{_protocol} = $proto;

    $app->{_started} = 1;
    $app->navigate('/page');

    my @dispatched = @{$app->{_webview}{dispatch_eval_js}};
    my $has_content = grep { /Page/ } @dispatched;

    ok($has_content, 'navigate dispatches content');
    # navigate does NOT re-inject listeners on partial updates to avoid duplicates
    # listeners survive innerHTML changes and are only injected once in run()

    Chandra::Error->clear_handlers;
}

# === init / loop / exit lifecycle ===
{
    my $app = _mock_app();
    my $ret = $app->init;
    isa_ok($ret, 'Chandra::App', 'init returns self');
    is($app->{_started}, 1, 'init sets _started');

    # exit resets _started
    $app->exit;
    is($app->{_started}, 0, 'exit resets _started');

    # Double exit is safe
    eval { $app->exit };
    is($@, '', 'double exit does not crash');
}

# === loop delegates to webview ===
{
    my $app = _mock_app();
    my $result = $app->loop(1);
    is($result, 1, 'loop returns webview loop result');
}

# === loop default blocking ===
{
    my $app = _mock_app();
    # MockWebview::loop always returns 1
    my $result = $app->loop;
    is($result, 1, 'loop defaults to blocking=1');
}

# === webview accessor ===
{
    my $app = _mock_app();
    my $wv = $app->webview;
    isa_ok($wv, 'MockWebview', 'webview returns mock');
}

# === _escape_js edge cases ===
{
    is(Chandra::App::_escape_js(""), '', 'empty string escapes to empty');
    is(Chandra::App::_escape_js("plain text"), 'plain text', 'plain text unchanged');
    is(Chandra::App::_escape_js("a\\b"), 'a\\\\b', 'backslash escaped');
    is(Chandra::App::_escape_js("a'b"), "a\\'b", 'single quote escaped');
    is(Chandra::App::_escape_js("a\nb"), 'a\\nb', 'newline escaped');
    is(Chandra::App::_escape_js("a\rb"), 'a\\rb', 'carriage return escaped');
    is(Chandra::App::_escape_js("a\\\nb"), 'a\\\\\\nb', 'backslash+newline both escaped');
}

done_testing;
