use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Catalyst::Test 'TestApp07';
use Test::More tests => 4;

ok( my $res = request('/action1'), 'request ok' );
is( $res->content, 'blank', 'action1 errors ok');

ok( $res = request('/action2'), 'request ok' );
is( $res->content, 'blank', 'action2 errors ok');
