#!/usr/bin/env perl

use Test::More;
use Test::Warnings;
use AnyEvent::Beanstalk;
use t::start_server;

my $c = get_client();

plan tests => 2;

$c->use('foo')->recv();
is($c->using(), 'foo');

done_testing;

