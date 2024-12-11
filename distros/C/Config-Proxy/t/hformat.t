# -*- perl -*-
use lib qw(t lib);
use strict;
use warnings;
use Test::More;

BEGIN {
    plan tests => 6; 
    use_ok('Test::HAProxy');
}

my $hp = new Test::HAProxy;
isa_ok($hp,'Config::Proxy::Impl::haproxy');

my $s;
$hp->write(\$s);

is($s, q{global
# comment
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
}, 'default write');

$hp->write(\$s, indent => 2);

is($s, q{global
# comment
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
}, 'reindent');

$hp->write(\$s, indent => 2, reindent_comments => 1);

is($s, q{global
  # comment
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
}, 'reindent comments');

$hp->write(\$s, indent => 4, tabstop => [ 10, 24 ]);

is($s, q{global
# comment
    log   /dev/log      daemon
    user  haproxy
    group haproxy
defaults
    log   global
    mode  http
frontend  in
    mode  http
    bind  :::80         v4v6
backend   out
    server localhost    http://127.0.0.1
}, 'tabstops');

__DATA__
global
# comment
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
