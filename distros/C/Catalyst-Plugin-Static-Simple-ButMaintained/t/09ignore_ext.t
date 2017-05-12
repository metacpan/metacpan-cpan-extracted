#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 4;
use Catalyst::Test 'TestApp';

# test ignoring extensions
# default is tt/html/xhtml

ok( my $res = request('http://localhost/ignored/tmpl.tt'), 'request ok' );
is( $res->content, 'default', 'ignored extension tt ok' );

ok( $res = request('http://localhost/ignored/index.html'), 'request ok' );
is( $res->content, 'default', 'ignored extension html ok' );
