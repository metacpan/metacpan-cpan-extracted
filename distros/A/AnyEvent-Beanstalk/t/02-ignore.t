#!/usr/bin/env perl

use Test::More;
use Test::Warnings;
use AnyEvent::Beanstalk;

use t::start_server;

my $c = get_client();

plan tests => 3;

$c->watch('foo')->recv();
ok(grep { $_ eq 'foo' } $c->watching());

$c->ignore('default')->recv();
ok(!grep { $_ eq 'default' } $c->watching());

done_testing;


