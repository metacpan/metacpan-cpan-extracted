#!/usr/bin/env perl

use Test::More tests => 43;
use strict;
use lib qw( lib t/lib );
use_ok('CatalystX::CRUD::Model::File');
use_ok('CatalystX::CRUD::Object::File');

use Catalyst::Test 'MyApp';
use Data::Dump qw( dump );
use HTTP::Request::Common;
use JSON;

####################################################
# basic CRUD

sub json_PUT {
    my ( $url, $body, $headers ) = @_;
    my $req = HTTP::Request->new( PUT => $url );
    $req->headers($headers) if $headers;
    $req->header( 'Content-Type'   => 'application/json' );
    $req->header( 'Content-Length' => length($body) );
    $req->content($body);
    $req;
}

my $res;

# confirm testfile is not there
ok( $res = request( GET('/rest/file/testfile') ), "GET testfile" );
is( $res->code, 404, "no testfile at start" );

# create testfile
ok( $res = request(
        json_PUT(
            '/rest/file/testfile', encode_json( { content => 'hello world' } )
        )
    ),
    "PUT new file"
);
is( $res->code, 201, "PUT returns 201" );
is_deeply(
    decode_json( $res->content ),
    { content => "hello world", file => "testfile" },
    "PUT new file response"
);

# read the file we just created
ok( $res = request( HTTP::Request->new( GET => '/rest/file/testfile' ) ),
    "GET new file" );

#diag( $res->content );

is_deeply(
    decode_json( $res->content ),
    { content => "hello world", file => "testfile" },
    "GET file response"
);

# update the file
ok( $res = request(
        json_PUT(
            '/rest/file/testfile', encode_json( { content => 'foo bar baz' } )
        )
    ),
    "update file"
);

is_deeply(
    decode_json( $res->content ),
    { content => "foo bar baz", file => "testfile" },
    "PUT file update response"
);

####################################################
# create another new file
ok( $res = request(
        json_PUT(
            '/rest/file/otherdir%2ftestfile2',
            encode_json( { content => 'hello world 2' } )
        )
    ),
    "PUT new file2"
);

is_deeply(
    decode_json( $res->content ),
    { content => "hello world 2", file => "otherdir/testfile2" },
    "PUT new file2 response"
);

is( $res->code, 201, "new file 201 status" );

###################################################
# test with no args

#system("tree t/lib/MyApp/root");

ok( $res = request('/rest/file'), "/ request with multiple items" );
is( $res->code, 200, "/ request with multiple items lists" );

#diag( dump( decode_json( $res->content ) ) );
is_deeply(
    decode_json( $res->content ),
    {   count   => 2,
        query   => 1,
        results => [
            { content => "foo bar baz",   file => "./testfile" },
            { content => "hello world 2", file => "otherdir/testfile2" },
        ],
    },
    "content has 2 files"
);

###################################################
# test dispatching

ok( $res = request('/rest/file'), "zero" );
is( $res->code, 200, "zero => list()" );
ok( $res = request('/rest/file/testfile'), "one" );
is( $res->code, 200, "oid == one" );
ok( $res = request('/rest/file/testfile/view'), "view" );
is( $res->code, 404, "rpc == two" );

######################################################
# relate 2 files together

# create relationship between testfile and testfile2
ok( $res = request( PUT('/rest/file/testfile/dir/otherdir%2ftestfile2') ),
    "three" );
is( $res->code, 204, "related == three" );

# more test routing
ok( $res = request( PUT('/rest/file/testfile/dir/otherdir%2ftestfile2/rpc') ),
    "four" );
is( $res->code, 404, "404 4 is too many args" );
ok( $res = request('/rest/file/testfile/two/three/four/five'), "five" );
is( $res->code, 404, "404 5 is too many args" );

########################################################
# non-CRUD actions: search and count
ok( $res = request( GET('/rest/file/search?file=testfile') ),
    "/search?file=testfile" );

#diag( dump decode_json( $res->content ) );
is_deeply(
    decode_json( $res->content ),
    {   count   => 3,
        query   => 1,
        results => [
            { content => "foo bar baz",   file => "./testfile" },
            { content => "foo bar baz",   file => "./testfile2" },
            { content => "hello world 2", file => "otherdir/testfile2" },
        ],
    },
    "search gets 3 results"
);

ok( $res = request( GET('/rest/file/count') ), "GET /count" );

#diag( dump decode_json( $res->content ) );
is_deeply(
    decode_json( $res->content ),
    {   count   => 3,
        query   => 1,
        results => [],
    },
    "count gets 3 results"
);

########################################################
# test "browser-like" behavior tunneling through POST

# delete relationship between testfile and testfile2
ok( $res = request(
        POST(
            '/rest/file/testfile/dir/otherdir%2ftestfile2',
            [ 'x-tunneled-method' => 'DELETE' ]
        )
    ),
    "three"
);
is( $res->code, 204, "tunneled DELETE related == three" );

# delete testfile
ok( $res = request(
        POST( '/rest/file/testfile', [ 'x-tunneled-method' => 'DELETE' ] )
    ),
    "rm file"
);

ok( $res = request(
        POST(
            '/rest/file/otherdir%2ftestfile2',
            [ 'x-tunneled-method' => 'DELETE' ]
        )
    ),
    "rm otherdir/testfile2"
);
is( $res->code, 204, "tunneled DELETE otherdir/testfile2" );

#diag( $res->content );

# confirm testfile is gone
ok( $res = request( GET('/rest/file/testfile') ),
    "confirm we nuked the file" );

#diag( dump $res->content );
is( $res->code, 404, "testfile is gone" );

ok( $res = request('/rest/file'), "/ request with no items" );
is( $res->code, 200, "/ request with no items == 200" );

#diag( dump decode_json( $res->content ) );
is_deeply(
    decode_json( $res->content ),
    { count => 0, query => 1, results => [], },
    "no content for no results"
);
