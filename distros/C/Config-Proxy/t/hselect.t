# -*- perl -*-
use lib qw(t lib);
use strict;
use warnings;
use Test::More;

BEGIN {
    plan tests => 4; 
    use_ok('Test::HAProxy');
}

my $hp = new Test::HAProxy;
isa_ok($hp,'Config::Proxy::Impl::haproxy');

is(join(',', map { $_->arg(0) } $hp->select ( name => 'frontend' )),
   'in,ins',
   'simple select');

is(join(',', map { $_->arg(0) } $hp->select ( name => 'frontend',
	                                      arg => { n => 0, v => 'in' } )),
   'in',
   'complex select');


__DATA__
global
    log /dev/log daemon
    user haproxy
    group haproxy
defaults
    log global
    mode http
frontend in
    mode http
    bind :::80 v4v6
backend out
    server localhost http://127.0.0.1
frontend ins
    mode https
    bind :::443 v4v6

   
