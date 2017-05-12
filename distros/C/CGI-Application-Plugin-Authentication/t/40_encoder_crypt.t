#!/usr/bin/perl -wT
use Test::More tests => 4;

BEGIN { use_ok('CGI::Application::Plugin::Authentication::Driver::Filter::crypt') };

use strict;
use warnings;

my $class = 'CGI::Application::Plugin::Authentication::Driver::Filter::crypt';

is($class->filter(undef, '123', 'mQPVY1HNg8SJ2'), 'mQPVY1HNg8SJ2', "encode");
ok($class->check(undef, '123', 'mQPVY1HNg8SJ2'), "check passes");
ok(!$class->check(undef, 'xxx', 'mQPVY1HNg8SJ2'), "check fails");

