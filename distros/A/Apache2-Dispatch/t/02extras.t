use strict;
use warnings FATAL => 'all';

use Apache::Test qw( -withtestmore );
use Apache::TestRequest qw(GET);

plan tests => 5, need_lwp;

my $uri = '/extras';
my $res = GET $uri;
cmp_ok($res->code, '==', 200);
like($res->content, qr/post_dispatch/);
like($res->content, qr/pre_dispatch/);

$uri = '/extras/bad';
$res = GET $uri;
cmp_ok($res->code, '==', 200);
like($res->content, qr/Yikes(.*?)dispatch_error/i, 'content like Yikes');

