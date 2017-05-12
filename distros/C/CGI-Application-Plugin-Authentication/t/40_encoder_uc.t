#!/usr/bin/perl
use Test::More tests => 4;

BEGIN { use_ok('CGI::Application::Plugin::Authentication::Driver::Filter::uc') };

use strict;
use warnings;

my $class = 'CGI::Application::Plugin::Authentication::Driver::Filter::uc';

is($class->filter(undef, 'abc'), 'ABC', "filter");
ok($class->check(undef, 'abc', 'ABC'), "check passes");
ok(!$class->check(undef, 'xxx', 'ABC'), "check fails");

