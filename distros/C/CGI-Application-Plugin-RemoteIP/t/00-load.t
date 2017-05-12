#!/usr/bin/perl -I../lib/ -Ilib/

use strict;
use warnings;

use Test::More tests => 3;

BEGIN
{
    use_ok("CGI::Application::Plugin::RemoteIP","We could load the module" );
}

ok( $CGI::Application::Plugin::RemoteIP::VERSION, "Version defined");
ok( $CGI::Application::Plugin::RemoteIP::VERSION =~ /^([0-9\.]+)/,
    "Version is numeric");
