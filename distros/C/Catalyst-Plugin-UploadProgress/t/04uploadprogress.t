#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN {
    unlink "$FindBin::Bin/cache.dat" if -e "$FindBin::Bin/cache.dat";
}

use Test::More;
use Catalyst::Test 'TestApp';
use HTTP::Request::Common;

eval { 
    require Catalyst::Plugin::Cache::FastMmap;
};
if ($@) {
    plan skip_all => 'Requires the Cache::FastMmap plugin for testing.';
}
else {
    plan tests => 12;
}

use Data::Dump qw(dump);

# test a single file upload
{
    my $id = '38f8a17599a8dd9c80bfb01643404f80';
    my $upload_size = 1024 * 16;

    my $request = POST(
        "http://localhost/upload?progress_id=$id",
        'Content-Type' => 'multipart/form-data',
        'Content'      => [
            'file.dat' => [ 
                undef, 
                'filename.dat',
                'Content-Type' => 'text/plain',
                Content => 'x' x $upload_size, 
            ],
        ]
    );
    
    ok( my $response = request($request), 'Request' );
    is( $response->content, 'ok', 'Upload ok' );
    
    ok( $response = request("http://localhost/progress?progress_id=$id"), 'Request' );
    is( $response->content_type, 'text/x-json', 'Progress JSON ok' );
    my $content = $response->content;
    my ( $size, $received ) = $content =~ m/"size":(\d+),"received":(\d+)/;
    cmp_ok( $size, '>', 16384, 'JSON size ok' );
    is( $size, $received, 'JSON received ok' );
}

# test a multiple-file upload
{
    my $id = '8b70fa267d2885464d2b70a68d2b8cf7';
    my $upload_size_1 = 1024 * 16;
    my $upload_size_2 = 1024 * 32;

    my $request = POST(
        "http://localhost/upload?progress_id=$id",
        'Content-Type' => 'multipart/form-data',
        'Content'      => [
            'file.dat' => [ 
                undef, 
                'file.dat',
                'Content-Type' => 'text/plain',
                Content => 'x' x $upload_size_1, 
            ],
            'file2.dat' => [
                undef,
                'file2.dat',
                'Content-Type' => 'text/plain',
                Content => 'y' x $upload_size_2,
            ],
        ]
    );
    
    ok( my $response = request($request), 'Request' );
    is( $response->content, 'ok', 'Multi-file upload OK' );
    
    # test that any URL with '?progress_id=...' in it will work
    ok( $response = request("http://localhost/deep/path/progress?progress_id=$id"), 'Request' );
    is( $response->content_type, 'text/x-json', 'Progress JSON ok' );
    my $content = $response->content;
    my ( $size, $received ) = $content =~ m/"size":(\d+),"received":(\d+)/;
    cmp_ok( $size, '>', 49152, 'JSON size ok' );
    is( $size, $received, 'JSON received ok' );
}

# clean up
unlink "$FindBin::Bin/cache.dat" if -e "$FindBin::Bin/cache.dat";