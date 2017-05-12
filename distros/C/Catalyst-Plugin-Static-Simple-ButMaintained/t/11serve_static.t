use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 14;
use Catalyst::Test 'TestApp';

my $res;

{
  # test getting a file via serve_static_file
  ok( $res = request('http://localhost/serve_static'), 'request ok' );
  is( $res->code, 200, '200 ok' );
  # .pm can be both application/x-pagemaker or text/x-perl, so only check for a slash
  like( $res->content_type, qr{/}, 'content-type ok' );
  like( $res->content, qr/package TestApp/, 'content of serve_static ok' );
}

{
  # test getting a file via serve_static_file with custom filetype
  ok( $res = request('http://localhost/serve_static/foobared'), 'request ok' );
  is( $res->code, 200, '200 ok' );
  like( $res->content_type, qr{foobared}, 'content-type ok' );
  like( $res->content, qr/package TestApp/, 'content of serve_static ok' );
}

{
  # test getting a file via serve_static_file with custom extention
  ok( $res = request('http://localhost/serve_static_ext_jpg'), 'request ok' );
  is( $res->code, 200, '200 ok' );
  like( $res->content_type, qr{image/jpeg}, 'content-type ok' );
  like( $res->content, qr/package TestApp/, 'content of serve_static ok' );
}

{
  # test getting a non-existant file via serve_static_file
  ok( $res = request('http://localhost/serve_static_404'), 'request ok' );
  is( $res->code, 404, '404 ok' );
}
