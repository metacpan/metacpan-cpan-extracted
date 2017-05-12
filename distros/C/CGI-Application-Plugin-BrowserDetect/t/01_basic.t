#!/usr/bin/perl
use Test::More tests => 4;
use strict;

BEGIN
{
    require_ok('CGI::Application::Plugin::BrowserDetect');
}

{
    package TestApp;
    use CGI::Application::Plugin::BrowserDetect;
}

# Test that browser was exported into TestApp package.
ok(TestApp->can('browser'), 'browser() was exported');

# Create the browser object.
my $self    = bless {}, 'TestApp';
my $browser = $self->browser;
ok($browser, 'Browser object created');

# Make sure the same object is returned.
is($self->browser, $browser, 'Same object returned on subsequent requests');
