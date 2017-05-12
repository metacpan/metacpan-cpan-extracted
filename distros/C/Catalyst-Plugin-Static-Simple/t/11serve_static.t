#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 6;
use Catalyst::Test 'TestApp';

# test getting a file via serve_static_file
ok( my $res = request('http://localhost/serve_static'), 'request ok' );
is( $res->code, 200, '200 ok' );
# .pm can be both application/x-pagemaker or text/x-perl, so only check for a slash
like( $res->content_type, qr{/}, 'content-type ok' );
like( $res->content, qr/package TestApp/, 'content of serve_static ok' );

# test getting a non-existant file via serve_static_file
ok( $res = request('http://localhost/serve_static_404'), 'request ok' );
is( $res->code, 404, '404 ok' );
