#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
no warnings 'once';
use_ok('Chandra::App');

# --- construction ---
{
    my $app = Chandra::App->new(
        title  => 'Test App',
        url    => 'about:blank',
        width  => 640,
        height => 480,
    );
    ok($app, 'App object created');
    isa_ok($app, 'Chandra::App');
}

# --- accessors delegate to webview ---
{
    my $app = Chandra::App->new(
        title     => 'Accessors',
        url       => 'https://example.com',
        width     => 1024,
        height    => 768,
        resizable => 0,
        debug     => 1,
    );
    is($app->title, 'Accessors', 'title');
    is($app->url, 'https://example.com', 'url');
    is($app->width, 1024, 'width');
    is($app->height, 768, 'height');
    is($app->resizable, 0, 'resizable');
    is($app->debug, 1, 'debug');
}

# --- defaults ---
{
    my $app = Chandra::App->new();
    is($app->title, 'Chandra', 'default title');
    is($app->width, 800, 'default width');
    is($app->height, 600, 'default height');
}

# --- webview() returns underlying Chandra object ---
{
    my $app = Chandra::App->new();
    my $wv = $app->webview;
    ok(defined $wv, 'webview() returns something');
    isa_ok($wv, 'Chandra');
}

# --- bind chaining ---
{
    my $app = Chandra::App->new();
    my $ret = $app->bind('f1', sub { 'a' })
                  ->bind('f2', sub { 'b' })
                  ->bind('f3', sub { 'c' });
    isa_ok($ret, 'Chandra::App', 'bind returns App for chaining');
}

# --- set_content with string ---
{
    my $app = Chandra::App->new();
    my $ret = $app->set_content('<h1>Hello</h1>');
    isa_ok($ret, 'Chandra::App', 'set_content returns self');
}

# --- set_content with object that has render() ---
{
    my $mock = bless {}, 'MockElement';
    {
        no strict 'refs';
        *MockElement::render = sub { '<div>Rendered</div>' };
    }
    my $app = Chandra::App->new();
    $app->set_content($mock);
    ok(1, 'set_content with renderable object works');
}

# --- set_content stores html for later use by run ---
{
    my $app = Chandra::App->new();
    $app->set_content('<p>Stored</p>');
    is($app->{_html}, '<p>Stored</p>', 'html stored internally');
}

# --- set_content with renderable calls render ---
{
    my $rendered = 0;
    my $mock2 = bless {}, 'MockElement2';
    {
        no strict 'refs';
        *MockElement2::render = sub { $rendered = 1; return '<span>test</span>' };
    }
    my $app = Chandra::App->new();
    $app->set_content($mock2);
    is($rendered, 1, 'render() was called');
    is($app->{_html}, '<span>test</span>', 'rendered html stored');
}

# --- DESTROY does not crash ---
{
    my $app = Chandra::App->new(title => 'destroy test');
    undef $app;
    ok(1, 'App destroy works');
}

# --- multiple instances ---
{
    my $a = Chandra::App->new(title => 'App A');
    my $b = Chandra::App->new(title => 'App B');
    is($a->title, 'App A', 'instance A');
    is($b->title, 'App B', 'instance B');
    isnt($a->webview, $b->webview, 'different underlying webviews');
}

# --- exit on non-started app does not crash ---
{
    my $app = Chandra::App->new();
    eval { $app->exit };
    is($@, '', 'exit on non-started app is safe');
}

# --- terminate on non-started app ---
# (terminate calls into XS which may no-op without init, but shouldn't crash)
{
    my $app = Chandra::App->new();
    eval { $app->terminate };
    is($@, '', 'terminate on non-started app does not die');
}

done_testing();
