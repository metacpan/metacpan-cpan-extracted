#!/usr/bin/perl
use Test::More tests => 4;

BEGIN { use_ok('CGI::Application::Plugin::Authentication::Driver::Filter::lc') };

use strict;
use warnings;

my $class = 'CGI::Application::Plugin::Authentication::Driver::Filter::lc';

is($class->filter(undef, 'ABC'), 'abc', "filter");
ok($class->check(undef, 'ABC', 'abc'), "check passes");
ok(!$class->check(undef, 'XXX', 'abc'), "check fails");

