#!/usr/bin/perl
use Test::More tests => 4;

BEGIN { use_ok('CGI::Application::Plugin::Authentication::Driver::Filter::strip') };

use strict;
use warnings;

my $class = 'CGI::Application::Plugin::Authentication::Driver::Filter::strip';

is($class->filter(undef, "  abc\t\n"), 'abc', "filter");
ok($class->check(undef, "  abc\t\n", 'abc'), "check passes");
ok(!$class->check(undef, "  xxx\t\n", 'abc'), "check fails");

