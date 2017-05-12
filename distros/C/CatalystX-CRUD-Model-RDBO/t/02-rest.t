#!/usr/bin/env perl
use strict;

use Test::More tests => 25;

BEGIN {
    use lib qw( ../../CatalystX-CRUD/trunk/lib );
    use_ok('CatalystX::CRUD::Model::RDBO');
    use_ok('CatalystX::CRUD::Object::RDBO');
    use_ok('Rose::DBx::TestDB');
    use_ok('Rose::DB::Object');
}

SKIP: {
    # if we do not have required modules, skip everything
    eval { require CatalystX::CRUD::Controller::REST; use JSON; };
    if ($@) {
        warn "$@";
        skip "CatalystX::CRUD::Controller::REST not installed", 21;
    }

    use lib qw( t/lib );
    use Catalyst::Test 'MyApp';
    use Data::Dump qw( dump );
    use HTTP::Request::Common;

    diag( "testing against Catalyst-Runtime version "
            . $Catalyst::Runtime::VERSION );

    my $res;

    ok( $res = request('/rest/foo/1'), "GET /rest/1" );
    is( $res->code, 200, "get 200" );
    is_deeply(
        decode_json( $res->content ),
        { "name" => "blue", "id" => 1 },
        "get foo/1"
    );

    ok( $res = request('/rest/foo/1/bars/2'), "GET /foo/1/bars/2" );
    is( $res->code, 404, "GET related does not yet exist" );
    is_deeply(
        decode_json( $res->content ),
        { error => "No such bars with id '2'" },
        "GET related 404 error"
    );

    # add a new foobar
    ok( $res = request( POST( '/rest/foo/1/bars/2', [] ) ),
        "POST /foo/1/bars/2/add" );

    is( $res->code, 204, "POST add related OK" );

    ok( $res = request('/rest/foo/1/bars/2'), "GET /foo/1/bars/2" );
    is( $res->code, 200, "GET related now exists" );

    #diag( dump decode_json( $res->content ) );
    is_deeply(
        decode_json( $res->content ),
        [ { id => 2, name => 'red' } ],
        "GET related 200"
    );

    # remove an old foobar
    ok( $res = request(
            POST( '/rest/foo/1/bars/1', [ 'x-tunneled-method' => 'DELETE' ] )
        ),
        "DELETE /foo/1/bars/1"
    );

    is( $res->code, 204, "DELETE related foobar" );

    ok( $res = request('/rest/foo/search?id=1&cxc-order=id'),
        "search id=1 with order" );

    #diag( dump decode_json( $res->content ) );

    is_deeply(
        decode_json( $res->content ),
        {   count => 1,
            query => {
                limit           => 50,
                offset          => 0,
                plain_query     => { id => [1] },
                plain_query_str => "(id='1')",
                where           => "(id='1')",
                sort_by         => "t1.id ASC",
                sort_order      => [ { id => "ASC" } ],
            },
            results => [ { id => 1, name => "blue" } ],
        },
        "search query with order dir assumed"
    );

    #dump $res;

    ok( $res = request('/rest/foo/search?id=1&cxc-sort=id&cxc-dir=desc'),
        "search id=1 with sort/dir" );

    #diag( dump decode_json( $res->content ) );

    is_deeply(
        decode_json( $res->content ),
        {   count => 1,
            query => {
                limit           => 50,
                offset          => 0,
                plain_query     => { id => [1] },
                plain_query_str => "(id='1')",
                where           => "(id='1')",
                sort_by         => "t1.id DESC",
                sort_order      => [ { id => "DESC" } ],
            },
            results => [ { id => 1, name => "blue" } ],
        },
        "search query with explicit order/dir"
    );

    ok( $res = request('/rest/foo/search?id=1'), "search id=1 with no sort" );

    #diag( dump decode_json( $res->content ) );

    is_deeply(
        decode_json( $res->content ),
        {   count => 1,
            query => {
                limit           => 50,
                offset          => 0,
                plain_query     => { id => [1] },
                plain_query_str => "(id='1')",
                where           => "(id='1')",
                sort_by         => "t1.id DESC",
                sort_order      => [ { id => "DESC" } ],
            },
            results => [ { id => 1, name => "blue" } ],
        },
        "search query with default PK order"
    );

    # test multiple sort
    ok( $res = request('/rest/foo/search?id=1&cxc-order=id+desc+name+asc'),
        "search id=1 with 2-column sort" );

    #diag( dump decode_json( $res->content ) );

    is_deeply(
        decode_json( $res->content ),
        {   count => 1,
            query => {
                limit           => 50,
                offset          => 0,
                plain_query     => { id => [1] },
                plain_query_str => "(id='1')",
                where           => "(id='1')",
                sort_by         => "t1.id DESC, t1.name ASC",
                sort_order      => [ { id => "DESC" }, { name => "ASC" } ],
            },
            results => [ { id => 1, name => "blue" } ],
        },
        "multi-sort content"
    );

}
