#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
no warnings 'once';

use_ok('Chandra::App');

# Mock webview that records all eval_js / dispatch_eval_js calls on the object
{
	package MockWV_CJ;
	sub new { bless { calls => [], eval_calls => [], dispatch_calls => [] }, shift }
	sub eval_js { push @{ $_[0]->{calls} }, $_[1]; push @{ $_[0]->{eval_calls} }, $_[1] }
	sub dispatch_eval_js { push @{ $_[0]->{calls} }, $_[1]; push @{ $_[0]->{dispatch_calls} }, $_[1] }
	sub clear { $_[0]->{calls} = []; $_[0]->{eval_calls} = []; $_[0]->{dispatch_calls} = [] }
}

# --- css() stores global CSS and returns self ---
{
	my $app = Chandra::App->new();
	my $ret = $app->css('body { color: red; }');
	is($ret, $app, 'css() returns self');
	is(scalar @{ $app->{_global_css} }, 1, 'one CSS entry stored');
	is($app->{_global_css}[0], 'body { color: red; }', 'CSS content stored');
}

# --- css() accumulates multiple entries ---
{
	my $app = Chandra::App->new();
	$app->css('body { margin: 0; }');
	$app->css('h1 { font-size: 2em; }');
	$app->css('p { line-height: 1.5; }');
	is(scalar @{ $app->{_global_css} }, 3, 'three CSS entries stored');
}

# --- css() chaining ---
{
	my $app = Chandra::App->new();
	my $ret = $app->css('a {}')->css('b {}')->css('c {}');
	is($ret, $app, 'css chaining returns $app');
	is(scalar @{ $app->{_global_css} }, 3, 'chained CSS entries stored');
}

# --- js() stores global JS and returns self ---
{
	my $app = Chandra::App->new();
	my $ret = $app->js('console.log("hello")');
	is($ret, $app, 'js() returns self');
	is(scalar @{ $app->{_global_js} }, 1, 'one JS entry stored');
	is($app->{_global_js}[0], 'console.log("hello")', 'JS content stored');
}

# --- js() accumulates multiple entries ---
{
	my $app = Chandra::App->new();
	$app->js('var a = 1;');
	$app->js('var b = 2;');
	is(scalar @{ $app->{_global_js} }, 2, 'two JS entries stored');
}

# --- js() chaining ---
{
	my $app = Chandra::App->new();
	my $ret = $app->js('a()')->js('b()');
	is($ret, $app, 'js chaining returns $app');
	is(scalar @{ $app->{_global_js} }, 2, 'chained JS entries stored');
}

# --- route() with js/css options ---
{
	my $app = Chandra::App->new();
	$app->route('/styled' => sub { '<p>Styled</p>' },
		css => '.styled { color: blue; }',
		js  => 'initStyled();',
	);
	is(scalar @{ $app->{_routes} }, 1, 'route with opts stored');
	my $entry = $app->{_routes}[0];
	is($entry->[0], '/styled', 'route path stored');
	is(ref $entry->[2], 'HASH', 'route options is a hashref');
	is($entry->[2]{css}, '.styled { color: blue; }', 'route CSS stored');
	is($entry->[2]{js}, 'initStyled();', 'route JS stored');
}

# --- route() without opts still works ---
{
	my $app = Chandra::App->new();
	$app->route('/' => sub { 'home' });
	my $entry = $app->{_routes}[0];
	is(ref $entry->[2], 'HASH', 'opts hash exists even without opts');
	ok(!$entry->[2]{css}, 'no CSS in default route');
	ok(!$entry->[2]{js}, 'no JS in default route');
}

# --- route() with only css ---
{
	my $app = Chandra::App->new();
	$app->route('/about' => sub { 'about' }, css => 'h1 { color: green; }');
	is($app->{_routes}[0][2]{css}, 'h1 { color: green; }', 'route with only CSS');
	ok(!$app->{_routes}[0][2]{js}, 'no JS when not specified');
}

# --- route() with only js ---
{
	my $app = Chandra::App->new();
	$app->route('/about' => sub { 'about' }, js => 'setup()');
	is($app->{_routes}[0][2]{js}, 'setup()', 'route with only JS');
	ok(!$app->{_routes}[0][2]{css}, 'no CSS when not specified');
}

# --- _match_route sets _current_route_opts ---
{
	my $app = Chandra::App->new();
	$app->route('/' => sub { 'home' }, css => 'body {}', js => 'init()');
	$app->route('/about' => sub { 'about' }, css => 'h1 {}');
	$app->route('/plain' => sub { 'plain' });

	$app->_match_route('/');
	is($app->{_current_route_opts}{css}, 'body {}', 'opts set for /');
	is($app->{_current_route_opts}{js}, 'init()', 'js opts set for /');

	$app->_match_route('/about');
	is($app->{_current_route_opts}{css}, 'h1 {}', 'opts set for /about');
	ok(!$app->{_current_route_opts}{js}, 'no js for /about');

	$app->_match_route('/plain');
	ok(!$app->{_current_route_opts}{css}, 'no css for /plain');
	ok(!$app->{_current_route_opts}{js}, 'no js for /plain');

	$app->_match_route('/nonexistent');
	is_deeply($app->{_current_route_opts}, {}, 'empty opts for unmatched route');
}

# --- _match_route with :param routes preserves opts ---
{
	my $app = Chandra::App->new();
	$app->route('/user/:id' => sub { "user" }, js => 'loadUser()');

	my ($h, %p) = $app->_match_route('/user/42');
	ok($h, 'matched parameterized route');
	is($p{id}, '42', 'param extracted');
	is($app->{_current_route_opts}{js}, 'loadUser()', 'opts preserved with params');
}

# --- Global CSS injected via _inject_post_content_js ---
{
	my $mock = MockWV_CJ->new;
	my $app = Chandra::App->new();
	$app->css('body { margin: 0; }');
	$app->css('h1 { color: red; }');
	$app->route('/' => sub { 'home' });
	$app->{_webview} = $mock;
	$app->{_current_route_opts} = {};

	$mock->clear;
	$app->_inject_post_content_js(0);

	my $has_global_css = grep { /chandra-global-css/ && /margin:\s*0/ && /color:\s*red/ } @{ $mock->{calls} };
	ok($has_global_css, 'global CSS injected into head via style element');
}

# --- Route CSS injected via _inject_post_content_js ---
{
	my $mock = MockWV_CJ->new;
	my $app = Chandra::App->new();
	$app->route('/styled' => sub { 'styled' }, css => '.fancy { border: 1px; }');
	$app->{_webview} = $mock;

	# Simulate matching this route
	$app->_match_route('/styled');

	$mock->clear;
	$app->_inject_post_content_js(0);

	my $has_route_css = grep { /chandra-route-css/ && /fancy/ && /border/ } @{ $mock->{calls} };
	ok($has_route_css, 'route CSS injected via style element');
}

# --- Route CSS cleared when route has no CSS ---
{
	my $mock = MockWV_CJ->new;
	my $app = Chandra::App->new();
	$app->route('/plain' => sub { 'plain' });
	$app->{_webview} = $mock;
	$app->_match_route('/plain');

	$mock->clear;
	$app->_inject_post_content_js(0);

	my $clears_route_css = grep { /chandra-route-css/ && /textContent=''/ } @{ $mock->{calls} };
	ok($clears_route_css, 'route CSS cleared for route without CSS');
}

# --- Global JS injected at end of body ---
{
	my $mock = MockWV_CJ->new;
	my $app = Chandra::App->new();
	$app->js('console.log("init")');
	$app->js('setupApp()');
	$app->route('/' => sub { 'home' });
	$app->{_webview} = $mock;
	$app->{_current_route_opts} = {};

	$mock->clear;
	$app->_inject_post_content_js(0);

	my $has_global_js = grep { /chandra-global-js/ && /body\.appendChild/ && /console\.log/ && /setupApp/ } @{ $mock->{calls} };
	ok($has_global_js, 'global JS appended as script at end of body');
}

# --- Route JS injected at end of body ---
{
	my $mock = MockWV_CJ->new;
	my $app = Chandra::App->new();
	$app->route('/dynamic' => sub { 'dynamic' }, js => 'activatePage()');
	$app->{_webview} = $mock;
	$app->_match_route('/dynamic');

	$mock->clear;
	$app->_inject_post_content_js(0);

	my $has_route_js = grep { /chandra-route-js/ && /body\.appendChild/ && /activatePage/ } @{ $mock->{calls} };
	ok($has_route_js, 'route JS appended as script at end of body');
}

# --- Route JS removed when route has no JS ---
{
	my $mock = MockWV_CJ->new;
	my $app = Chandra::App->new();
	$app->route('/noscript' => sub { 'noscript' });
	$app->{_webview} = $mock;
	$app->_match_route('/noscript');

	$mock->clear;
	$app->_inject_post_content_js(0);

	my $removes_route_js = grep { /chandra-route-js/ && /removeChild/ } @{ $mock->{calls} };
	ok($removes_route_js, 'route JS element removed for route without JS');
}

# --- navigate() triggers route CSS/JS injection ---
{
	my $mock = MockWV_CJ->new;
	my $app = Chandra::App->new();
	$app->route('/' => sub { 'home' });
	$app->route('/styled' => sub { 'styled' },
		css => '.nav { display: flex; }',
		js  => 'initNav();',
	);
	$app->layout(sub { "<div id='chandra-content'>$_[0]</div>" });
	$app->{_webview} = $mock;
	$app->{_started} = 1;

	$mock->clear;
	$app->navigate('/styled');

	# Should have: content update + pushState, then route CSS, then route JS
	ok(@{ $mock->{calls} } >= 2, 'navigate dispatches multiple JS calls');
	my $has_nav_css = grep { /chandra-route-css/ && /display:\s*flex/ } @{ $mock->{calls} };
	ok($has_nav_css, 'navigate injects route CSS');
	my $has_nav_js = grep { /chandra-route-js/ && /initNav/ } @{ $mock->{calls} };
	ok($has_nav_js, 'navigate injects route JS');
}

# --- navigate() clears route CSS/JS when navigating to plain route ---
{
	my $mock = MockWV_CJ->new;
	my $app = Chandra::App->new();
	$app->route('/' => sub { 'home' });
	$app->route('/styled' => sub { 'styled' }, css => '.x {}', js => 'x()');
	$app->layout(sub { "<div id='chandra-content'>$_[0]</div>" });
	$app->{_webview} = $mock;
	$app->{_started} = 1;

	# Navigate to styled first
	$app->navigate('/styled');

	# Then navigate to plain
	$mock->clear;
	$app->navigate('/');

	my $clears_css = grep { /chandra-route-css/ && /textContent=''/ } @{ $mock->{calls} };
	ok($clears_css, 'navigate to plain route clears route CSS');
	my $removes_js = grep { /chandra-route-js/ && /removeChild/ } @{ $mock->{calls} };
	ok($removes_js, 'navigate to plain route removes route JS');
}

# --- dispatch mode uses dispatch_eval_js ---
{
	my $mock = MockWV_CJ->new;
	my $app = Chandra::App->new();
	$app->css('body {}');
	$app->js('init()');
	$app->route('/' => sub { 'home' }, css => 'h1 {}', js => 'page()');
	$app->{_webview} = $mock;
	$app->_match_route('/');

	$mock->clear;
	$app->_inject_post_content_js(1);

	ok(@{ $mock->{dispatch_calls} } > 0, 'dispatch mode uses dispatch_eval_js');
	is(scalar @{ $mock->{eval_calls} }, 0, 'dispatch mode does not use eval_js');
}

# --- css/js work with css() + js() chaining and route() together ---
{
	my $app = Chandra::App->new();
	my $ret = $app
		->css('* { box-sizing: border-box; }')
		->js('window.APP = {};')
		->route('/' => sub { 'home' }, js => 'APP.home()')
		->route('/about' => sub { 'about' }, css => '.about {}', js => 'APP.about()');

	is($ret, $app, 'full chaining returns $app');
	is(scalar @{ $app->{_global_css} }, 1, 'global CSS stored');
	is(scalar @{ $app->{_global_js} }, 1, 'global JS stored');
	is(scalar @{ $app->{_routes} }, 2, 'routes stored');
	is($app->{_routes}[0][2]{js}, 'APP.home()', 'route 1 JS');
	is($app->{_routes}[1][2]{css}, '.about {}', 'route 2 CSS');
	is($app->{_routes}[1][2]{js}, 'APP.about()', 'route 2 JS');
}

done_testing();
