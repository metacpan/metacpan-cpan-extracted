#!/usr/bin/perl
use Test::More tests => 20;
use strict;

BEGIN
{
    require_ok('CGI::Application::Plugin::Flash');
}

{
    package TestApp;
    use base 'CGI::Application';
    use CGI::Application::Plugin::Flash;

    sub session { return bless {}, 'My::Session'; }

    package My::Session;
    our @ISA = 'CGI::Session';

    sub param
    {
        return undef
    };
}

my $app = TestApp->new;

# Make sure that the flash and flash_now methods were exported.
can_ok($app, qw/flash flash_config/);

# Make sure flash_config returns an empty hashref if no config set.
my $empty_config = $app->flash_config;
is(ref $empty_config, 'HASH', "flash_config returns hashref before being set");
is(scalar keys %$empty_config, 0, "  empty");

# Setting flash_config.
ok($app->flash_config(session_key => 'TESTING'), "set flash_config");

# Getting flash_config.
my %config = $app->flash_config;
my $config = scalar $app->flash_config;
is(scalar keys %config, 1, "flash_config can return a hash");
is_deeply(\%config, { 'session_key' => 'TESTING' }, "  data is right");
is(ref $config, 'HASH', "flash_config in scalar is ref");
is_deeply(\%config, $config, "  ref and hash data are the same");

# Make sure that we get the same object back on subsequent tries.
my $flash = $app->flash;
is($app->flash, $flash, "got the same object");
is($flash->session_key, 'TESTING', "flash used flash_config");

# Testing flash get and set wrapper.
ok($flash->set('info' => 'test1'), "set flash info key to a single value");
is($flash->get('info'), 'test1', "  got back right value");
ok($flash->set('info' => 'test2'), "set flash info again");
is($flash->get('info'), 'test2', "  value overwritten");
ok($flash->set('error' => "foo", "bar"), "set flash error key to 2 values");
my $errors = $flash->get('error');
my @errors = $flash->get('error');
is(ref $errors, 'ARRAY', "  arrayref returned in scalar context");
is_deeply($errors, [ 'foo', 'bar' ], "    right contents");
is(scalar @errors, 2, "   list returned in list context");
is_deeply(\@errors, $errors, "    right contents");
