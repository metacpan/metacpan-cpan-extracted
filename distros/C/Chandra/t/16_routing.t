#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
no warnings 'once';

use_ok('Chandra::App');

# --- route() registration ---
{
    my $app = Chandra::App->new();
    my $ret = $app->route('/' => sub { '<h1>Home</h1>' });
    is($ret, $app, 'route() returns $self');
    ok($app->{_routes}, 'routes stored');
    is(scalar @{ $app->{_routes} }, 1, 'one route registered');
}

# --- multiple routes ---
{
    my $app = Chandra::App->new();
    $app->route('/' => sub { 'home' });
    $app->route('/about' => sub { 'about' });
    $app->route('/contact' => sub { 'contact' });
    is(scalar @{ $app->{_routes} }, 3, 'three routes registered');
}

# --- _match_route exact paths ---
{
    my $app = Chandra::App->new();
    $app->route('/' => sub { 'home' });
    $app->route('/about' => sub { 'about' });
    $app->route('/about/team' => sub { 'team' });

    my ($h1) = $app->_match_route('/');
    ok($h1, 'match /');
    is($h1->(), 'home', '/ returns home');

    my ($h2) = $app->_match_route('/about');
    ok($h2, 'match /about');
    is($h2->(), 'about', '/about returns about');

    my ($h3) = $app->_match_route('/about/team');
    ok($h3, 'match /about/team');
    is($h3->(), 'team', '/about/team returns team');

    my ($h4) = $app->_match_route('/nonexistent');
    ok(!$h4, 'no match for /nonexistent');
}

# --- _match_route with :param ---
{
    my $app = Chandra::App->new();
    $app->route('/user/:id' => sub { my (%p) = @_; "user=$p{id}" });
    $app->route('/post/:id/comment/:cid' => sub {
        my (%p) = @_;
        "post=$p{id} comment=$p{cid}";
    });

    my ($h1, %p1) = $app->_match_route('/user/42');
    ok($h1, 'match /user/42');
    is($p1{id}, '42', 'param id=42');
    is($h1->(%p1), 'user=42', 'handler gets params');

    my ($h2, %p2) = $app->_match_route('/post/7/comment/99');
    ok($h2, 'match /post/7/comment/99');
    is($p2{id}, '7', 'param id=7');
    is($p2{cid}, '99', 'param cid=99');
    is($h2->(%p2), 'post=7 comment=99', 'multi-param handler');

    my ($h3) = $app->_match_route('/user');
    ok(!$h3, 'no match for /user (too few segments)');

    my ($h4) = $app->_match_route('/user/42/extra');
    ok(!$h4, 'no match for /user/42/extra (too many segments)');
}

# --- first match wins ---
{
    my $app = Chandra::App->new();
    $app->route('/test' => sub { 'first' });
    $app->route('/test' => sub { 'second' });

    my ($h) = $app->_match_route('/test');
    is($h->(), 'first', 'first match wins');
}

# --- layout() ---
{
    my $app = Chandra::App->new();
    my $ret = $app->layout(sub { my ($body) = @_; "<nav>NAV</nav><div id='chandra-content'>$body</div>" });
    is($ret, $app, 'layout() returns $self');
    ok($app->{_layout}, 'layout stored');
}

# --- not_found() ---
{
    my $app = Chandra::App->new();
    my $ret = $app->not_found(sub { '<h1>Custom 404</h1>' });
    is($ret, $app, 'not_found() returns $self');
    ok($app->{_not_found}, 'not_found stored');
}

# --- _render_route with string content ---
{
    my $app = Chandra::App->new();
    $app->route('/' => sub { '<h1>Home</h1>' });

    my $html = $app->_render_route('/');
    is($html, '<h1>Home</h1>', 'render route returns HTML string');
}

# --- _render_route_body returns body without layout ---
{
    my $app = Chandra::App->new();
    $app->route('/' => sub { '<p>Body</p>' });
    $app->layout(sub { "<div class='shell'>$_[0]</div>" });

    my $body = $app->_render_route_body('/');
    is($body, '<p>Body</p>', 'render_route_body returns raw body');
    unlike($body, qr/shell/, 'render_route_body has no layout');

    my $full = $app->_render_route('/');
    like($full, qr/shell/, 'render_route includes layout');
}

# --- _render_route with Element object ---
{
    my $app = Chandra::App->new();
    $app->route('/' => sub {
        # Mock element that responds to render()
        bless { html => '<h1>Element</h1>' }, 'MockElement';
    });

    {
        package MockElement;
        sub render { return $_[0]->{html} }
    }

    my $html = $app->_render_route('/');
    is($html, '<h1>Element</h1>', 'render route handles Element objects');
}

# --- _render_route with layout ---
{
    my $app = Chandra::App->new();
    $app->route('/' => sub { '<p>Body</p>' });
    $app->layout(sub {
        my ($body) = @_;
        "<div class='shell'><div id='chandra-content'>$body</div></div>";
    });

    my $html = $app->_render_route('/');
    like($html, qr/<div class='shell'>/, 'layout wraps content');
    like($html, qr/<p>Body<\/p>/, 'body content present');
    like($html, qr/chandra-content/, 'container ID present');
}

# --- _render_route with params ---
{
    my $app = Chandra::App->new();
    $app->route('/user/:id' => sub {
        my (%p) = @_;
        "<h1>User $p{id}</h1>";
    });

    my $html = $app->_render_route('/user/42');
    is($html, '<h1>User 42</h1>', 'render route passes params');
}

# --- _render_route with layout and params ---
{
    my $app = Chandra::App->new();
    $app->route('/item/:name' => sub {
        my (%p) = @_;
        "<p>$p{name}</p>";
    });
    $app->layout(sub { "<main>$_[0]</main>" });

    my $html = $app->_render_route('/item/widget');
    is($html, '<main><p>widget</p></main>', 'layout + params work together');
}

# --- _render_route 404 default ---
{
    my $app = Chandra::App->new();
    $app->route('/' => sub { 'home' });

    my $html = $app->_render_route('/missing');
    like($html, qr/404/, 'default 404 page for unmatched route');
}

# --- _render_route custom 404 ---
{
    my $app = Chandra::App->new();
    $app->route('/' => sub { 'home' });
    $app->not_found(sub { '<h1>Custom 404</h1>' });

    my $html = $app->_render_route('/missing');
    is($html, '<h1>Custom 404</h1>', 'custom 404 handler used');
}

# --- _render_route 404 with layout ---
{
    my $app = Chandra::App->new();
    $app->route('/' => sub { 'home' });
    $app->not_found(sub { '<p>Not here</p>' });
    $app->layout(sub { "<div>$_[0]</div>" });

    my $html = $app->_render_route('/missing');
    is($html, '<div><p>Not here</p></div>', '404 wrapped in layout');
}

# --- _router_js content ---
{
    my $js = Chandra::App::_router_js();
    like($js, qr/addEventListener.*click/, 'JS has click listener');
    like($js, qr/__chandra_navigate/, 'JS calls __chandra_navigate');
    like($js, qr/popstate/, 'JS handles popstate');
    like($js, qr/preventDefault/, 'JS prevents default on links');
    like($js, qr/https\?:/, 'JS skips http/https links');
}

# --- navigate() sets current route ---
{
    my $app = Chandra::App->new();
    $app->route('/' => sub { 'home' });
    $app->route('/about' => sub { 'about' });

    # Not started yet — navigate just stores the route
    $app->navigate('/about');
    is($app->{_current_route}, '/about', 'navigate sets _current_route');
}

# --- navigate() with mock webview (started) ---
{
    my @eval_calls;
    {
        package MockWVNav;
        sub new { bless {}, shift }
        sub dispatch_eval_js { push @eval_calls, $_[1] }
    }

    my $app = Chandra::App->new();
    $app->route('/' => sub { '<p>Home</p>' });
    $app->route('/about' => sub { '<p>About</p>' });
    $app->layout(sub { "<nav>NAV</nav><div id='chandra-content'>$_[0]</div>" });
    $app->{_webview} = MockWVNav->new;
    $app->{_started} = 1;

    @eval_calls = ();
    $app->navigate('/about');
    is($app->{_current_route}, '/about', 'navigate stores current route');
    ok(@eval_calls >= 1, 'navigate dispatches JS eval');
    like($eval_calls[0], qr/About/, 'navigate JS contains rendered content');
    like($eval_calls[0], qr/pushState/, 'navigate JS pushes history state');
    # Partial update should use body only (no layout nesting)
    # The innerHTML part should have body only, layout only in the else/fallback branch
    like($eval_calls[0], qr/if\(_c\)\{_c\.innerHTML='<p>About<\/p>'/, 'partial update uses body only');
}

# --- no routes = unchanged behaviour ---
{
    my $app = Chandra::App->new();
    $app->set_content('<h1>Static</h1>');
    ok(!$app->{_routes}, 'no routes by default');
    is($app->{_html}, '<h1>Static</h1>', 'set_content still works');
}

# --- _escape_js helper ---
{
    my $escaped = Chandra::App::_escape_js("line1\nline2\\end'quote");
    unlike($escaped, qr/\n/, 'newlines escaped');
    like($escaped, qr/\\\\/, 'backslashes escaped');
    like($escaped, qr/\\'/, 'quotes escaped');
}

# --- refresh with routing ---
{
    my @eval_calls;
    {
        package MockWVRefresh;
        sub new { bless {}, shift }
        sub eval_js          { push @eval_calls, $_[1] }
        sub dispatch_eval_js { push @eval_calls, $_[1] }
    }

    my $app = Chandra::App->new();
    $app->route('/' => sub { '<p>Home</p>' });
    $app->{_webview} = MockWVRefresh->new;
    $app->{_started} = 1;
    $app->{_current_route} = '/';

    @eval_calls = ();
    $app->refresh;
    ok(@eval_calls >= 1, 'refresh dispatches eval');
    ok((grep { /Home/ } @eval_calls), 'refresh re-renders current route');
}

# --- refresh without routes (existing behaviour) ---
{
    my @eval_calls;
    {
        package MockWVRefresh2;
        sub new { bless {}, shift }
        sub eval_js          { push @eval_calls, $_[1] }
        sub dispatch_eval_js { push @eval_calls, $_[1] }
    }

    my $app = Chandra::App->new();
    $app->set_content('<h1>Static</h1>');
    $app->{_webview} = MockWVRefresh2->new;
    $app->{_started} = 1;

    @eval_calls = ();
    $app->refresh;
    ok(@eval_calls >= 1, 'refresh dispatches eval for static content');
    ok((grep { /Static/ } @eval_calls), 'refresh re-renders static HTML');
}

# --- _inject_post_content_js includes router JS when routes exist ---
{
    my @eval_calls;
    {
        package MockWVInject;
        sub new { bless {}, shift }
        sub eval_js { push @eval_calls, $_[1] }
    }

    my $app = Chandra::App->new();
    $app->route('/' => sub { 'home' });
    $app->{_webview} = MockWVInject->new;

    @eval_calls = ();
    $app->_inject_post_content_js(0);
    my $found_router = grep { /chandra_navigate/ } @eval_calls;
    ok($found_router, 'router JS injected when routes exist');
}

# --- _inject_post_content_js skips router when no routes ---
{
    my @eval_calls;
    {
        package MockWVInject2;
        sub new { bless {}, shift }
        sub eval_js { push @eval_calls, $_[1] }
    }

    my $app = Chandra::App->new();
    $app->{_webview} = MockWVInject2->new;

    @eval_calls = ();
    $app->_inject_post_content_js(0);
    my $found_router = grep { /chandra_navigate/ } @eval_calls;
    ok(!$found_router, 'no router JS when no routes');
}

# --- chained API ---
{
    my $app = Chandra::App->new();
    my $result = $app->route('/' => sub { 'a' })
                     ->route('/b' => sub { 'b' })
                     ->layout(sub { "<div>$_[0]</div>" })
                     ->not_found(sub { '404' });
    is($result, $app, 'chained route/layout/not_found returns $self');
    is(scalar @{ $app->{_routes} }, 2, 'chained routes registered');
}

done_testing;
