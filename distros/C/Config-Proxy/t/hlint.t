# -*- perl -*-
use lib qw(t lib);
use strict;
use warnings;
use Test::More;

BEGIN {
    plan tests => 7; 
    use_ok('Test::HAProxy');
}

my $hp = new Test::HAProxy;
isa_ok($hp,'Config::Proxy::Impl::haproxy');


ok($hp->lint, 'haproxy -c -f');

$hp->lint(0);
ok(!$hp->lint);

$hp->lint(1);
ok($hp->lint, 'haproxy -c -f');

$hp->lint(enable => 0);
ok(!$hp->lint);

$hp->lint(enable => 1, command => '/bin/true');
ok($hp->lint, '/bin/true');

__DATA__
global
    log /dev/log daemon
    user haproxy
    group haproxy
