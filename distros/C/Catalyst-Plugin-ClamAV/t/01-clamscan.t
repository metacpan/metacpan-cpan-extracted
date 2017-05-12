use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;
use Catalyst::Test 'TestApp';
use HTTP::Request::Common;
use Data::Dumper;

plan tests => 6;

my $no_scan;
if ( !$ENV{CLAMAV_SOCKET_NAME}
  && !$ENV{CLAMAV_SOCKET_HOST}
  && !$ENV{CLAMAV_SOCKET_PORT}
) {
    diag('To real scan test, set ENV CLAMAV_SOCKET_NAME or CLAMAV_SOCKET_HOST and CLAMAV_SOCKET_HOST.');
    $no_scan = 1;
}

{
    my $request = POST(
        "http://localhost/upload",
        'Content-Type' => 'multipart/form-data',
        'Content'      => [
            'file1' => [
                undef,
                'foo.txt',
                'Content-Type' => 'text/plain',
                Content => 'x' x 1024,
            ],
        ]
    );

    ok( my $response = request($request), 'Request' );
    ok( $response->is_success, 'Upload ok' );

    my $content = $response->content;
    ok( $content eq ( $no_scan ? '-1' : '0'), 'Scan ok' )
}

{
    my $request = POST(
        "http://localhost/upload",
        'Content-Type' => 'multipart/form-data',
        'Content'      => [
            'file1' => [
                undef,
                'foo.txt',
                'Content-Type' => 'text/plain',
                Content => 'x' x 1024,
            ],
            'file2' => [
                undef,
                'bar.txt',
                'Content-Type' => 'text/plain',
                Content => 'y' x 1024,
            ],
        ]
    );

    ok( my $response = request($request), 'Request' );
    ok( $response->is_success, 'Upload ok' );

    my $content = $response->content;
    ok( $content eq ( $no_scan ? '-1' : '0'), 'Scan ok' )
}
