#!/usr/bin/perl -I../lib/ -Ilib/

use strict;
use warnings;

use Test::More tests => 3;

BEGIN
{
    use_ok("CGI::Application::Plugin::AB","We could load the module" );
}

ok( $CGI::Application::Plugin::AB::VERSION, "Version defined");
ok( $CGI::Application::Plugin::AB::VERSION =~ /^([0-9\.]+)/,
    "Version is numeric");
