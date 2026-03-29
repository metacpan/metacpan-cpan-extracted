#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra');

# Test default values
{
    my $app = Chandra->new();
    ok($app, 'created with no args');
    is($app->title, 'Chandra', 'default title');
    is($app->url, 'about:blank', 'default url');
    is($app->width, 800, 'default width');
    is($app->height, 600, 'default height');
    is($app->resizable, 1, 'default resizable');
    is($app->debug, 0, 'default debug');
}

# Test custom values
{
    my $app = Chandra->new(
        title     => 'Custom',
        url       => 'https://example.com',
        width     => 1024,
        height    => 768,
        resizable => 0,
        debug     => 1,
    );
    is($app->title, 'Custom', 'custom title');
    is($app->url, 'https://example.com', 'custom url');
    is($app->width, 1024, 'custom width');
    is($app->height, 768, 'custom height');
    is($app->resizable, 0, 'custom resizable=0');
    is($app->debug, 1, 'custom debug=1');
}

# Test zero dimensions
{
    my $app = Chandra->new(width => 0, height => 0);
    is($app->width, 0, 'zero width');
    is($app->height, 0, 'zero height');
}

# Test data URI url
{
    my $app = Chandra->new(url => 'data:text/html,<h1>Hello</h1>');
    is($app->url, 'data:text/html,<h1>Hello</h1>', 'data URI url');
}

# Test empty string title
{
    my $app = Chandra->new(title => '');
    is($app->title, '', 'empty string title');
}

# Test UTF-8 title
{
    my $app = Chandra->new(title => 'Ünïcödë Tïtlë');
    is($app->title, 'Ünïcödë Tïtlë', 'UTF-8 title');
}

# Test multiple instances
{
    my $a = Chandra->new(title => 'Window A');
    my $b = Chandra->new(title => 'Window B');
    is($a->title, 'Window A', 'instance A title');
    is($b->title, 'Window B', 'instance B title');
    isnt($a, $b, 'different instances');
}

# Test ISA
{
    my $app = Chandra->new();
    isa_ok($app, 'Chandra');
}

# Test odd args croak
{
    eval { Chandra->new('odd') };
    like($@, qr/Odd number/, 'odd args croak');
}

# Test with callback
{
    my $called = 0;
    my $app = Chandra->new(
        callback => sub { $called = 1 },
    );
    ok($app, 'created with callback');
}

# Test unknown keys are silently ignored
{
    my $app = Chandra->new(unknown_key => 'whatever');
    ok($app, 'unknown keys ignored');
    is($app->title, 'Chandra', 'defaults still applied');
}

done_testing();
