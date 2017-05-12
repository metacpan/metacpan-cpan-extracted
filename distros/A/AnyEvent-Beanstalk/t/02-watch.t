#!/usr/bin/env perl

use AnyEvent::Beanstalk;
use Test::More;
use Test::Warnings;
use t::start_server;

my $c = get_client();

plan tests => 3;

$c->use('foo')->recv;
$c->watch('bar')->recv;
$c->reconnect();
is($c->using(), 'foo');
ok(grep { $_ eq 'bar' } $c->watching());

done_testing;



