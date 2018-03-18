#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

# Module::Build craps out on files with spaces so it's not included in the dist
my $has_space_file = -e "$FindBin::Bin/lib/TestApp/root/files/space file.txt";

use Test::More;
plan tests => ($has_space_file) ? 12 : 9;
use Catalyst::Test 'TestApp';

# test getting a css file
ok( my $res = request('http://localhost/files/static.css'), 'request ok' );
is( $res->content_type, 'text/css', 'content-type text/css ok' );
like( $res->content, qr/background/, 'content of css ok' );

# test a file with spaces
if ( $has_space_file ) {
    ok( $res = request('http://localhost/files/space file.txt'), 'request ok' );
    is( $res->content_type, 'text/plain', 'content-type text/plain ok' );
    like( $res->content, qr/background/, 'content of space file ok' );
}

# test a non-existent file
ok( $res = request('http://localhost/files/404.txt'), 'request ok' );
is( $res->content, 'default', 'default handler for non-existent content ok' );

# test unknown extension
ok( $res = request('http://localhost/files/err.unknown'), 'request ok' );
is( $res->content_type, 'text/plain', 'unknown extension as text/plain ok' );

ok( $res = request('http://localhost/files/empty.txt'), 'request ok' );
is( $res->content, '', 'empty files result in an empty response' );
