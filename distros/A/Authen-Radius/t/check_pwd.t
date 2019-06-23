use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('Authen::Radius') };

my $r = Authen::Radius->new(Host => '127.0.0.1', Secret => 'secret');
ok($r, 'object created');

my $check = $r->check_pwd('test', 'test');
ok(! $check, 'no RADIUS available - check failed');
