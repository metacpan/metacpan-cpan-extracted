use strict;
use warnings;
use Test::More;
use Test::Exception;
use Dancer::Plugin::PageHistory::Page;
use Dancer::Plugin::PageHistory::PageSet;

my ( $data, $page, $pages );

# new, methods & (fallback|current|previous)_page tests

lives_ok( sub { $pages = Dancer::Plugin::PageHistory::PageSet->new },
    "PageSet->new with no args" );

isa_ok( $pages, "Dancer::Plugin::PageHistory::PageSet", "pages class" )
  or diag explain $pages;

can_ok( $pages, qw(max_items pages latest_page previous_page methods add) );

lives_ok( sub { $page = $pages->latest_page }, "get latest_page" );

ok( !defined $page, "latest_page is undef" );

lives_ok( sub { $page = $pages->previous_page }, "get previous_page" );

ok( !defined $page, "previous_page is undef" );

lives_ok(
    sub {
        $pages =
          Dancer::Plugin::PageHistory::PageSet->new( fallback_page => undef );
    },
    "PageSet->new with fallback_page undef"
);

lives_ok( sub { $page = $pages->latest_page }, "get latest_page" );

ok( !defined $page, "latest_page is undef" );

lives_ok( sub { $page = $pages->previous_page }, "get previous_page" );

ok( !defined $page, "previous_page is undef" );

lives_ok(
    sub {
        $pages =
          Dancer::Plugin::PageHistory::PageSet->new(
            fallback_page => { path => '/foo' } );
    },
    "PageSet->new with fallback_page { path => '/foo' }"
);

lives_ok( sub { $page = $pages->latest_page }, "get latest_page" );

cmp_ok( $page->path, "eq", "/foo", "latest_page is expected fallback page" );

lives_ok( sub { $page = $pages->previous_page }, "get previous_page" );

cmp_ok( $page->path, "eq", "/foo", "previous_page is expected fallback page" );

lives_ok(
    sub { $page = Dancer::Plugin::PageHistory::Page->new( path => '/bar' ) },
    "create page object" );

lives_ok(
    sub {
        $pages =
          Dancer::Plugin::PageHistory::PageSet->new( fallback_page => $page );
    },
    "PageSet->new with fallback_page as Page object"
);

lives_ok( sub { $page = $pages->latest_page }, "get latest_page" );

cmp_ok( $page->path, "eq", "/bar", "latest_page is expected fallback page" );

lives_ok( sub { $page = $pages->previous_page }, "get previous_page" );

cmp_ok( $page->path, "eq", "/bar", "previous_page is expected fallback page" );

throws_ok(
    sub {
        $pages =
          Dancer::Plugin::PageHistory::PageSet->new( fallback_page => [] );
    },
    qr/coercion.+failed/,
    "PageSet->new with fallback_page as empty list"
);

throws_ok(
    sub {
        $pages =
          Dancer::Plugin::PageHistory::PageSet->new( fallback_page => "foo" );
    },
    qr/coercion.+failed/,
    "PageSet->new with fallback_page as scalar"
);

# sprinkle some pages into new that require coercion + set max_items and
# some methods

$data = {
    default => [
        {
            'attributes' => { 'foo' => 'bar' },
            'path'       => '/some/path',
            'query' => { 'a' => 123, 'b' => 456 },
            'title' => 'Some page'
        },
        { 'path' => '/another/path', 'title' => 'Another page' },
    ],
    bananas =>
      [ { 'path' => '/another/banana', 'title' => 'Another banana' }, ],
};

lives_ok(
    sub {
        $pages = Dancer::Plugin::PageHistory::PageSet->new(
            max_items => 3,
            methods   => [ 'default', 'bananas', 'apples' ],
            pages     => $data
        );
    },
    "PageSet->new with args"
);

can_ok( $pages, qw(default bananas apples) );

is_deeply(
    [ sort $pages->types ],
    [qw/bananas default/],
    "check pages types"
) or diag explain $pages->types;

my $count = 0;
foreach my $type ( $pages->types ) {
    foreach my $page ( @{ $pages->pages->{$type} } ) {
        isa_ok(
            $page,
            "Dancer::Plugin::PageHistory::Page",
            "$type " . $page->path
        ) && $count++
    }
}
cmp_ok( $count, "==", 3, "found 3 pages" );

cmp_ok( @{$pages->apples}, '==', 0, "zero pages of apples via method" );
cmp_ok( @{$pages->bananas}, '==', 1, "one page of bananas via method" );

cmp_ok( $pages->bananas->[0]->path, "eq", "/another/banana", "path is good" );

cmp_ok( $pages->latest_page('bananas')->path,
    "eq", "/another/banana", "bananas latest_page path" );

ok( !defined $pages->previous_page('bananas'), "bananas previous_page undef" );

cmp_ok( $pages->latest_page('default')->path,
    "eq", "/some/path", "default latest_page path" );

cmp_ok( $pages->previous_page('default')->path,
    "eq", "/another/path", "default previous_page path" );

cmp_ok( $pages->latest_page->path, "eq", "/some/path", "latest_page path" );

cmp_ok( $pages->previous_page->path,
    "eq", "/another/path", "previous_page path" );

# add

throws_ok( sub { $pages->add }, qr/must include a defined path/,
    "add nothing" );

throws_ok(
    sub { $pages->add( type => "foo" ) },
    qr/must include.+path/,
    "add with type but no path"
);

throws_ok(
    sub { $pages->add( type => "foo", path => undef ) },
    qr/must include.+path/,
    "add with type and undef path"
);

cmp_ok( @{$pages->default}, "==", 2, "2 pages in default" );

lives_ok( sub { $pages->add( path => "/3" ) }, "add page /3" );

cmp_ok( @{$pages->default}, "==", 3, "3 pages in default" );

lives_ok( sub { $pages->add( path => "/2" ) }, "add page /2" );

cmp_ok( @{$pages->default}, "==", 3, "3 pages in default" );

lives_ok( sub { $pages->add( path => "/1" ) }, "add page /1" );

cmp_ok( @{$pages->default}, "==", 3, "3 pages in default" );

cmp_ok( $pages->latest_page->path, "eq", "/1", "check latest_page" );

cmp_ok( $pages->previous_page->path, "eq", "/2", "check previous_page" );

cmp_ok( $pages->page_index(2)->path, "eq", "/3", "check page at index 2" );

done_testing;
