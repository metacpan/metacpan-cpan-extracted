use strict;
use warnings;
use Test::More;
use Test::Exception;
use Dancer::Plugin::PageHistory::Page;

my $page;

throws_ok(
    sub { $page = Dancer::Plugin::PageHistory::Page->new },
    qr/Missing required arguments: path/,
    "Page->new with no args"
);

throws_ok(
    sub { $page = Dancer::Plugin::PageHistory::Page->new( path => {} ) },
    qr/did not pass type constraint/,
    "Page->new bad type for path"
);

throws_ok(
    sub {
        $page = Dancer::Plugin::PageHistory::Page->new(
            path  => '/',
            query => ''
        );
    },
    qr/did not pass type constraint/,
    "Page->new bad query"
);

throws_ok(
    sub {
        $page = Dancer::Plugin::PageHistory::Page->new(
            path       => '/',
            attributes => ''
        );
    },
    qr/did not pass type constraint/,
    "Page->new bad attributes"
);

throws_ok(
    sub {
        $page = Dancer::Plugin::PageHistory::Page->new(
            path  => '/',
            title => {}
        );
    },
    qr/did not pass type constraint/,
    "Page->new bad title"
);

lives_ok(
    sub {
        $page = Dancer::Plugin::PageHistory::Page->new( path => '/some/path', );
    },
    "Page->new path=>/home/path"
);

isa_ok( $page, "Dancer::Plugin::PageHistory::Page", "page class" );

can_ok( $page, qw(attributes path query title uri has_attributes has_title ) );

cmp_ok( $page->path, "eq", "/some/path", "path is OK" );

cmp_ok( $page->uri, "eq", "/some/path", "uri is OK" );

ok( !$page->has_attributes, "has_attributes false" );

ok( !$page->has_title, "has_title false" );

lives_ok(
    sub {
        $page = Dancer::Plugin::PageHistory::Page->new(
            attributes => { foo => "bar" },
            path       => '/some/path',
            query => { a => 123, b => 456 },
            title => "Some page",
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

is_deeply( $page->query, { a => 123, b => 456 }, "query is OK" );

done_testing;
