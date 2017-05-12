#!/usr/bin/env perl

use Test::More tests => 40;
use strict;
use lib qw( lib t/lib );
use_ok('CatalystX::CRUD::Model::File');
use_ok('CatalystX::CRUD::Object::File');

use Catalyst::Test 'MyApp';
use Data::Dump qw( dump );
use HTTP::Request::Common;

###########################################
# basic sanity check
ok( get('/foo'), "get /foo" );

ok( my $response = request('/file/search'), "response for /file/search" );

#dump( $response );

is( $response->code, '302', "/file/search response was redirect" );

ok( get('/autoload'), "get /autoload" );

###########################################
# do CRUD stuff

my $res;

# create
ok( $res = request(
        POST( '/file/testfile/save', [ content => 'hello world' ] )
    ),
    "POST new file"
);

is( $res->content,
    '{ content => "hello world", file => "testfile" }',
    "POST new file response"
);

is( $res->code, 302, "new file 302 redirect status" );

# read the file we just created
ok( $res = request( HTTP::Request->new( GET => '/file/testfile/view' ) ),
    "GET new file" );

#diag( $res->content );

like( $res->content, qr/content => "hello world"/, "read file" );

# update the file
ok( $res = request(
        POST( '/file/testfile/save', [ content => 'foo bar baz' ] )
    ),
    "update file"
);

like( $res->content, qr/content => "foo bar baz"/, "update file" );

# test for default()
ok( $res = request('/file/testfile'), "get /file/testfile" );

#diag( $res->content );
is( $res->code, 404, "default is 404" );

# create related file
ok( $res = request(
        POST(
            '/file/otherdir%2ftestfile2/save',
            [ content => 'hello world 2' ]
        )
    ),
    "POST new file2"
);

is( $res->content,
    '{ content => "hello world 2", file => "otherdir/testfile2" }',
    "POST new file2 response"
);

is( $res->code, 302, "new file 302 redirect status" );

# create relationship
ok( $res
        = request(
        POST( '/file/testfile/dir/otherdir%2ftestfile2/add', [] ) ),
    "add related dir/otherdir%2ftestfile2"
);

#dump $res;

is( $res->code, 204, "relationship created with status 204" );

# remove the relationship

ok( $res = request(
        POST( '/file/testfile/dir/otherdir%2ftestfile2/remove', [] )
    ),
    "remove related dir/testfile2"
);

is( $res->code, 204, "relationship removed with status 204" );

# delete the file

ok( $res = request( POST( '/file/testfile/delete', [] ) ), "rm file" );

# delete the file2

ok( $res = request( POST( '/file/testfile2/delete', [] ) ), "rm file2" );

#diag( $res->content );

# confirm it is gone
ok( $res = request( HTTP::Request->new( GET => '/file/testfile/view' ) ),
    "confirm we nuked the file" );

#diag( $res->content );

like( $res->content, qr/content => undef/, "file nuked" );

##############################################################
## Adapter API

# create
ok( $res = request(
        POST( '/fileadapter/testfile/save', [ content => 'hello world' ] )
    ),
    "POST new file adapter"
);

is( $res->content,
    '{ content => "hello world", file => "testfile" }',
    "POST new file response adapter"
);

# read the file we just created
ok( $res
        = request(
        HTTP::Request->new( GET => '/fileadapter/testfile/view' ) ),
    "GET new file adapter"
);

#diag( $res->content );

like( $res->content, qr/content => "hello world"/, "read file adapter" );

# update the file
ok( $res = request(
        POST( '/fileadapter/testfile/save', [ content => 'foo bar baz' ] )
    ),
    "update file adapter"
);

like( $res->content, qr/content => "foo bar baz"/, "update file adapter" );

# delete the file

ok( $res = request( POST( '/fileadapter/testfile/rm', [] ) ),
    "rm file adapter" );

#diag( $res->content );

# confirm it is gone
ok( $res
        = request(
        HTTP::Request->new( GET => '/fileadapter/testfile/view' ) ),
    "confirm we nuked the file adapter"
);

#diag( $res->content );

like( $res->content, qr/content => undef/, "file nuked adapter" );

# test the fetch() rewrite

# create a new file
ok( $res = request(
        POST(
            '/fetchrewrite/id/testfile/save', [ content => 'hello world' ]
        )
    ),
    "POST new file adapter"
);

is( $res->content,
    '{ content => "hello world", file => "testfile" }',
    "POST new file response adapter"
);

ok( $res = request(
        HTTP::Request->new( GET => '/fetchrewrite/id/testfile/view' )
    ),
    "fetch rewrite works"
);

# delete the file

ok( $res = request( POST( '/fetchrewrite/id/testfile/rm', [] ) ),
    "rm fetch rewrite" );

# confirm it is gone
ok( $res = request(
        HTTP::Request->new( GET => '/fetchrewrite/id/testfile/view' )
    ),
    "confirm we nuked the fetch rewrite file"
);
