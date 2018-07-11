# -*- perl -*-
use lib qw(t lib);
use strict;
use warnings;
use Test::More;
use autodie;

BEGIN {
    plan tests => 6; 
    use_ok('Test::HAProxy');
}

my $hp = new Test::HAProxy;
isa_ok($hp,'Test::HAProxy');

my $s;
open(my $fh, '>', \$s);
$hp->write($fh);
close $fh;

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

open($fh, '>', \$s);
$hp->write($fh, indent => 2);
close $fh;

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

open($fh, '>', \$s);
$hp->write($fh, indent => 2, reindent_comments => 1);
close $fh;

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

open($fh, '>', \$s);
$hp->write($fh, indent => 4, tabstop => [ 10, 24 ]);
close $fh;

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
