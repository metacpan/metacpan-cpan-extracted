use Test::More tests => 16;
use strict;
use lib qw( lib t/lib );
use_ok('CatalystX::CRUD::Model::File');
use_ok('CatalystX::CRUD::Object::File');

use Catalyst::Test 'MyApp';
use Data::Dump qw( dump );
use HTTP::Request::Common;

ok( my $res = request('/search/search'), "response for /search/search" );

#dump( $response->headers );

is( $res->code, '200', "response Ok" );

ok( $res = request('/search/search?file=bar'), "?file=bar" );

#warn $res->content;

is_deeply(
    eval $res->content,
    {   limit           => 50,
        offset          => 0,
        plain_query     => { file => ["bar"] },
        plain_query_str => "(file='bar')",
        query           => [ "file", "bar" ],
        sort_by         => "file DESC",
        sort_order      => [ { file => "DESC" } ],
    },
    "?file=bar"
);

ok( $res = request('/search/search?file=bar&content=foo'),
    "?file=bar&content=foo" );

#warn $res->content;

is_deeply(
    eval $res->content,
    {   limit           => 50,
        offset          => 0,
        plain_query     => { content => ["foo"], file => ["bar"] },
        plain_query_str => "(file='bar') AND (content='foo')",
        query           => [ "AND", [ "file", "bar", "content", "foo" ] ],
        sort_by         => "file DESC",
        sort_order => [ { file => "DESC" } ],
    },
    "?file=bar&content=foo"
);

ok( $res
        = request(
        '/search/search?file=bar&file=foo&content=green&content=red'),
    '?file=bar&file=foo&content=green&content=red'
);

#warn $res->content;

is_deeply(
    eval $res->content,
    {   limit  => 50,
        offset => 0,
        plain_query =>
            { content => [ "green", "red" ], file => [ "bar", "foo" ] },
        plain_query_str =>
            "(file='bar' OR file='foo') AND (content='green' OR content='red')",
        query => [
            "AND",
            [   "OR", [ "file",    "bar",   "file",    "foo" ],
                "OR", [ "content", "green", "content", "red" ],
            ],
        ],
        sort_by    => "file DESC",
        sort_order => [ { file => "DESC" } ],
    },
    '?file=bar&file=foo&content=green&content=red'
);

ok( $res = request(
        '/search/search?file=bar&file=foo&content=green&content=red&cxc-op=OR'
    ),
    '?file=bar&file=foo&content=green&content=red&cxc-op=OR'
);

#warn $res->content;

is_deeply(
    eval $res->content,
    {   limit  => 50,
        offset => 0,
        plain_query =>
            { content => [ "green", "red" ], file => [ "bar", "foo" ] },
        plain_query_str =>
            "(file='bar' OR file='foo') OR (content='green' OR content='red')",
        query => [
            "OR",
            [   "OR", [ "file",    "bar",   "file",    "foo" ],
                "OR", [ "content", "green", "content", "red" ],
            ],
        ],
        sort_by    => "file DESC",
        sort_order => [ { file => "DESC" } ],
    },
    '?file=bar&file=foo&content=green&content=red&cxc-op=OR'
);

ok( $res = request(
        POST(
            '/search/search',
            [   'cxc-query' =>
                    "(file='bar' OR file='foo') OR (content='green' OR content='red')"
            ]
        )
    ),
    qq/?cxc-query="(file='bar' OR file='foo') OR (content='green' OR content='red')"/
);

#warn $res->content;

is_deeply(
    eval $res->content,
    {   limit       => 50,
        offset      => 0,
        plain_query => {
            "cxc-query" => [
                "(file='bar' OR file='foo') OR (content='green' OR content='red')",
            ],
        },
        plain_query_str =>
            "(file='bar' OR file='foo') OR (content='green' OR content='red')",
        query => [
            "OR",
            [   "OR", [ "file",    "bar",   "file",    "foo" ],
                "OR", [ "content", "green", "content", "red" ],
            ],
        ],
        sort_by    => "file DESC",
        sort_order => [ { file => "DESC" } ],
    },
    '?cxc-query=content = green OR red OR file = bar OR foo'
);

# multiple column search
ok( $res = request(
        POST(
            '/search/search',
            [   'cxc-query' =>
                    "(file='bar' OR file='foo') OR (content='green' OR content='red')",
                'cxc-order' => 'file ASC file desc',
            ]
        )
    ),
    'multi-column sort POST'
);

#warn $res->content;

is_deeply(
    eval $res->content,
    {   limit       => 50,
        offset      => 0,
        plain_query => {
            "cxc-query" => [
                "(file='bar' OR file='foo') OR (content='green' OR content='red')",
            ],
        },
        plain_query_str =>
            "(file='bar' OR file='foo') OR (content='green' OR content='red')",
        query => [
            "OR",
            [   "OR", [ "file",    "bar",   "file",    "foo" ],
                "OR", [ "content", "green", "content", "red" ],
            ],
        ],
        sort_by    => "file ASC, file DESC",
        sort_order => [ { file => 'ASC' }, { file => "DESC" } ],
    },
    'multi-column sort'
);
