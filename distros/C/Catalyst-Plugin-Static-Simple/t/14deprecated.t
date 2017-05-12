#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 5;
use Catalyst::Test 'IncTestApp';

is( $TestLog::logged, "Deprecated 'static' config key used, please use the key 'Plugin::Static::Simple' instead",
    "Got warning" );

# test overlay dir
ok( my $res = request('http://localhost/overlay.jpg'), 'request ok' );
is( $res->content_type, 'image/jpeg', 'overlay path ok' );

# test passthrough to root
ok( $res = request('http://localhost/images/bad.gif'), 'request ok' );
is( $res->content_type, 'image/gif', 'root path ok' );

