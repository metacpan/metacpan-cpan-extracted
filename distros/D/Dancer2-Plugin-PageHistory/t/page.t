use strict;
use warnings;
use Test::More;
use Test::Exception;
use Dancer2::Plugin::PageHistory::Page;

my $page;

throws_ok(
    sub { $page = Dancer2::Plugin::PageHistory::Page->new },
    qr/Either 'request' or 'path' must be supplied as arg to new/,
    "Page->new with no args"
);

throws_ok(
    sub { $page = Dancer2::Plugin::PageHistory::Page->new( path => {} ) },
    qr/did not pass type constraint|is not a string/,
    "Page->new bad type for path"
);

throws_ok(
    sub {
        $page = Dancer2::Plugin::PageHistory::Page->new(
            path         => '/',
            query_string => {},
        );
    },
    qr/did not pass type constraint|is not a string/,
    "Page->new bad query"
);

throws_ok(
    sub {
        $page = Dancer2::Plugin::PageHistory::Page->new(
            path       => '/',
            attributes => ''
        );
    },
    qr/did not pass type constraint|is not a HashRef/,
    "Page->new bad attributes"
);

throws_ok(
    sub {
        $page = Dancer2::Plugin::PageHistory::Page->new(
            path  => '/',
            title => {}
        );
    },
    qr/did not pass type constraint|is not a string/,
    "Page->new bad title"
);

lives_ok(
    sub {
        $page = Dancer2::Plugin::PageHistory::Page->new( path => '/some/path', );
    },
    "Page->new path=>/home/path"
);

isa_ok( $page, "Dancer2::Plugin::PageHistory::Page", "page class" );

can_ok( $page,
    qw( attributes path query_string title uri has_attributes has_title) );

cmp_ok( $page->path, "eq", "/some/path", "path is OK" );

cmp_ok( $page->uri, "eq", "/some/path", "uri is OK" );

ok( !$page->has_attributes, "has_attributes false" );

ok( !$page->has_title, "has_title false" );

lives_ok(
    sub {
        $page = Dancer2::Plugin::PageHistory::Page->new(
            attributes   => { foo => "bar" },
            path         => '/some/path',
            query_string => 'a=123&b=456',
            title        => "Some page",
        );
    },
    "Page->new path=>/home/path"
);

cmp_ok( $page->path, "eq", "/some/path", "path is OK" );

like( $page->uri, qr|^/some/path\?|, "path in uri is OK" );

like( $page->uri, qr|a=123|, "query param a in uri is OK" );

like( $page->uri, qr|b=456|, "query param b in uri is OK" );

ok( $page->has_attributes, "has_attributes true" );

is_deeply( $page->attributes, { foo => "bar" }, "attribues is OK" );

ok( $page->has_title, "has_title true" );

cmp_ok( $page->title, "eq", "Some page", "title is OK" );

cmp_ok( $page->query_string, "eq", 'a=123&b=456', "query is OK" );

done_testing;
