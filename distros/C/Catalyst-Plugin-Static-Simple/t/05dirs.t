#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 13;
use Catalyst::Test 'TestApp';

# test defined static dirs
TestApp->config->{'Plugin::Static::Simple'}->{dirs} = [
    'always-static',
    qr/^images/,
    'qr/^css/',
];

# a file with no extension will return text/plain
ok( my $res = request('http://localhost/always-static/test'), 'request ok' );
is( $res->content_type, 'text/plain', 'text/plain ok' );

# a file with an extension in ignore_extensions still gets served
ok( $res = request('http://localhost/always-static/test.html'), 'request ok' );
is( $res->code, 200, 'html file in dirs get served' );

# a missing file in a defined static dir will return 404 and text/html
ok( $res = request('http://localhost/always-static/404.txt'), 'request ok' );
is( $res->code, 404, '404 ok' );
is( $res->content_type, 'text/html', '404 is text/html' );

# qr regex test
ok( $res = request('http://localhost/images/catalyst.png'), 'request ok' );
like( $res->content_type, qr{\Aimage/.*png\z}, 'qr regex path ok' );

# eval regex test
ok( $res = request('http://localhost/css/static.css'), 'request ok' );
like( $res->content, qr/background/, 'eval regex path ok' );

# A static dir with no trailing slash is handled by Cat
ok( $res = request('http://localhost/always-static'), 'request ok' );
is( $res->content, 'default', 'content ok' );
