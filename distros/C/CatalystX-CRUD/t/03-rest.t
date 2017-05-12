use Test::More tests => 56;
use strict;
use lib qw( lib t/lib );
use_ok('CatalystX::CRUD::Model::File');
use_ok('CatalystX::CRUD::Object::File');

use Catalyst::Test 'MyApp';
use Data::Dump qw( dump );
use HTTP::Request::Common;

###########################################
# do CRUD stuff

my $res;

# create
ok( $res = request(
        POST( '/rest/file/testfile', [ content => 'hello world' ] )
    ),
    "POST new file"
);

is( $res->content,
    '{ content => "hello world", file => "testfile" }',
    "POST new file response"
);

####################################################
# read the file we just created
ok( $res = request( HTTP::Request->new( GET => '/rest/file/testfile' ) ),
    "GET new file" );

#diag( $res->content );

like( $res->content, qr/content => "hello world"/, "read file" );

####################################################
# update the file
ok( $res = request(
        POST( '/rest/file/testfile', [ content => 'foo bar baz' ] )
    ),
    "update file"
);

like( $res->content, qr/content => "foo bar baz"/, "update file" );

####################################################
# create related file
ok( $res = request(
        POST(
            '/rest/file/otherdir%2ftestfile2',
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

###################################################
# test with no args

#system("tree t/lib/MyApp/root");

ok( $res = request('/rest/file'), "/ request with multiple items" );
is( $res->code, 200, "/ request with multiple items lists" );
ok( $res->content =~ qr/foo bar baz/ && $res->content =~ qr/hello world/,
    "content has 2 files" );

###################################################
# test the Arg matching with no rpc

ok( $res = request('/rest/file/create'), "/rest/file/create" );
is( $res->code, 302, "/rest/file/create" );
ok( $res = request('/rest/file'), "zero" );
is( $res->code, 200, "zero => list()" );
ok( $res = request('/rest/file/testfile'), "one" );
is( $res->code, 200, "oid == one" );
ok( $res = request('/rest/file/testfile/view'), "view" );
is( $res->code, 404, "rpc == two" );
ok( $res
        = request(
        POST( '/rest/file/testfile/dir/otherdir%2ftestfile2', [] ) ),
    "three"
);
is( $res->code, 204, "related == three" );
ok( $res = request(
        POST( '/rest/file/testfile/dir/otherdir%2ftestfile2/rpc', [] )
    ),
    "four"
);
is( $res->code, 404, "404 == related rpc with no enable_rpc_compat" );
ok( $res = request('/rest/file/testfile/two/three/four/five'), "five" );
is( $res->code, 404, "404 == five" );
ok( $res = request(
        POST(
            '/rest/file/testfile/dir/otherdir%2ftestfile2',
            [ 'x-tunneled-method' => 'DELETE' ]
        )
    ),
    "three"
);
is( $res->code, 204, "related == three" );

# turn rpc enable on and run again
MyApp->controller('REST::File')->enable_rpc_compat(1);

ok( $res = request('/rest/file/create'), "/rest/file/create" );
is( $res->code, 302, "/rest/file/create" );
ok( $res = request('/rest/file'), "zero with rpc" );
is( $res->code, 200, "zero with rpc => list()" );
ok( $res = request('/rest/file/testfile'), "one with rpc" );
is( $res->code, 200, "oid == one with rpc" );
ok( $res = request('/rest/file/testfile/view'), "view with rpc" );
is( $res->code, 200, "rpc == two with rpc" );
ok( $res = request(
        POST( '/rest/file/testfile/dir/otherdir%2ftestfile2/add', [] )
    ),
    "three with rpc"
);
is( $res->code, 204, "related == three with rpc" );
ok( $res = request(
        POST( '/rest/file/testfile/dir/otherdir%2ftestfile2/rpc', [] )
    ),
    "four"
);
is( $res->code, 404, "404 == related rpc with enable_rpc_compat" );

ok( $res = request('/rest/file/testfile/two/three/four/five'),
    "five with rpc" );
is( $res->code, 404, "404 == five with rpc" );

ok( $res = request(
        POST(
            '/rest/file/testfile/dir/otherdir%2ftestfile2/remove',
            [ 'x-tunneled-method' => 'DELETE' ]
        )
    ),
    "three with rpc"
);
is( $res->code, 204, "related == three with rpc" );

# delete the file

ok( $res = request(
        POST( '/rest/file/testfile', [ _http_method => 'DELETE' ] )
    ),
    "rm file"
);

ok( $res = request(
        POST( '/rest/file/testfile2/delete', [ _http_method => 'DELETE' ] )
    ),
    "rm file2"
);

ok( $res = request(
        POST(
            '/rest/file/otherdir%2ftestfile2/delete',
            [ _http_method => 'DELETE' ]
        )
    ),
    "rm otherdir/testfile2"
);

#diag( $res->content );

# confirm it is gone
ok( $res = request( HTTP::Request->new( GET => '/rest/file/testfile' ) ),
    "confirm we nuked the file" );

#diag( $res->content );

like( $res->content, qr/content => undef/, "file nuked" );

ok( $res = request('/rest/file'), "/ request with no items" );

#dump $res;
is( $res->code,    200, "/ request with no items == 200" );
is( $res->content, "",  "no content for no results" );

# request something we know doesn't exist
ok( $res = request('/rest/file/nosuchfile'), "/ request with nosuchfile" );
is( $res->code, 404, "nosuchfile == 404" );
