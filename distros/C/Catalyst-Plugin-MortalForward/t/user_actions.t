#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 6;
use Catalyst::Test 'TestApp';

my $res = request('/ok');
cmp_ok($res->header('X-Test'), 'eq', 'ok', 'No exception thrown - normal way');

$res = request('/test');
cmp_ok(
    $res->header('X-Test'),
    'eq',
    'failure i_die/life is beautiful/failure i_live_and_i_die/failure i_die_and_i_live',
    'test serie',
);
ok $res->header('X-Chouette'), 'header check';

$res = request('/i_die');
ok ! $res->header('X-Chouette'), "check i_die directly";

$res = request('/i_die_and_i_live');
ok ! $res->header('X-Chouette'), "check with a forward in between";

$res = request('/class_fwd');
ok ! $res->header('X-Alive'), "forward to a class also working ";

## test begin, end and auto die
