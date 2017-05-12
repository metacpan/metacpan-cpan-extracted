#!/usr/bin/env perl
use strict;

use Test::More tests => 22;

BEGIN {
    use lib qw( ../../CatalystX-CRUD/trunk/lib );
    use_ok('CatalystX::CRUD::Model::RDBO');
    use_ok('CatalystX::CRUD::Object::RDBO');
    use_ok('Rose::DBx::TestDB');
    use_ok('Rose::DB::Object');
}

use lib qw( t/lib );
use Catalyst::Test 'MyApp';
use Data::Dump qw( dump );
use HTTP::Request::Common;

diag( "testing against Catalyst-Runtime version "
        . $Catalyst::Runtime::VERSION );

ok( my $res = request('/foo/test'), "get /foo/test" );

#dump $res->headers;

is( $res->headers->{status}, 200, "get 200" );

ok( $res = request('/foo/1/read'), "get /foo/1/read" );

is( $res->headers->{status}, 200, "get 200" );

ok( $res = request('/foo/1/bars/2/add'), "GET /foo/1/bars/2/add" );

is( $res->headers->{status}, 405, "cannot GET add related" );

# add a new foobar
ok( $res = request( POST( '/foo/1/bars/2/add', [] ) ),
    "POST /foo/1/bars/2/add" );

is( $res->headers->{status}, 204, "POST add related OK" );

# remove an old foobar
ok( $res = request( POST( '/foo/1/bars/1/remove', [] ) ),
    "POST /foo/1/bars/1/remove" );

is( $res->headers->{status}, 204, "POST remove related OK" );

ok( $res = request('/foo/search?id=1&cxc-order=id'),
    "search id=1 with order" );

is_deeply(
    eval $res->content,
    {   limit           => 50,
        offset          => 0,
        plain_query     => { id => [1] },
        plain_query_str => "(id='1')",
        query           => [ "id", 1 ],
        sort_by         => "t1.id ASC",
        sort_order      => [ { id => "ASC" } ],
    },
    "search query with order dir assumed"
);

#dump $res;

ok( $res = request('/foo/search?id=1&cxc-sort=id&cxc-dir=desc'),
    "search id=1 with sort/dir" );

#dump $res;

is_deeply(
    eval $res->content,
    {   limit           => 50,
        offset          => 0,
        plain_query     => { id => [1] },
        plain_query_str => "(id='1')",
        query           => [ "id", 1 ],
        sort_by         => "t1.id DESC",
        sort_order      => [ { id => "DESC" } ],
    },
    "search query with explicit order/dir"
);

ok( $res = request('/foo/search?id=1'), "search id=1 with no sort" );
is_deeply(
    eval $res->content,
    {   limit           => 50,
        offset          => 0,
        plain_query     => { id => [1] },
        plain_query_str => "(id='1')",
        query           => [ "id", 1 ],
        sort_by         => "t1.id DESC",
        sort_order      => [ { id => "DESC" } ],
    },
    "search query with default PK order"
);

# test multiple sort
ok( $res = request('/foo/search?id=1&cxc-order=id+desc+name+asc'),
    "search id=1 with 2-column sort" );

#dump $res->content;

is_deeply(
    eval $res->content,
    {   limit           => 50,
        offset          => 0,
        plain_query     => { id => [1] },
        plain_query_str => "(id='1')",
        query           => [ "id", 1 ],
        sort_by         => "t1.id DESC, t1.name ASC",
        sort_order      => [ { id => "DESC" }, { name => "ASC" } ],
    },
    "multi-sort content"
);

