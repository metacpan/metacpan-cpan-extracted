use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 7;
use Test::Deep;

use Blog;

my $store = Blog->connect(':memory:');

my $author = Blog::Model::Author->new( name => 'yanick', bio => 'necrohacker' );
$author->save($store);

my $entry = $store->create( 'Entry', url => '/first', author => $author );

cmp_deeply $entry->pack => superhashof({
    __CLASS__ => 'Blog::Model::Entry',
    url       => '/first',
    author    => 'yanick',
});

is $store->create( 'Entry', url => '/first', author => 'yanick' )->author->bio
    => 'necrohacker', 'expansion happens';


subtest 'cascade_save' => sub {
    $store->create( Entry => (
        url => '/second', author => Blog::Model::Author->new(
            name => 'bob',
        ),
    ));

    ok !$store->get( 'Author' => 'bob' ), "author is not auto-saved";
    
    $store->create( Entry2 => (
        url => '/second', author => Blog::Model::Author->new(
            name => 'bob',
        ),
    ));

    ok $store->get( 'Author' => 'bob' ), "author is auto-saved";

};


subtest 'cascade_delete' => sub {
    my $author = $store->create( Author => ( name => 'charles', bio => 'foo' ) );

    my $entry = $store->create( Entry => (
        url => '/third', author => $author 
    )  );

    ok $store->get( 'Entry' => '/third' ), "entry is there";

    $entry->delete;

    ok !$store->get( 'Entry' => '/third' ), "entry is gone";

    ok $store->get( 'Author' => 'charles' ), "... but author lives on";

    $entry = $store->create( Entry2 => (
        url => '/third', author => $author 
    )  );

    ok $store->get( 'Entry2' => '/third' ), "entry is there";

    $entry->delete;

    ok !$store->get( 'Entry2' => '/third' ), "entry is gone";

    ok !$store->get( 'Author' => 'charles' ), "...and author is gone";

};

subtest 'delete previous version' => sub {
    my $author = $store->create( Author => ( name => 'david' ) );

    my $entry = $store->create( Entry2 => (
        url => '/dpv', author => $author 
    )  );

    ok $store->get( 'Author' => 'david' ), "david is there";

    $entry->author(
        Blog::Model::Author->new( name => 'Eleonor' )
    );

    ok $store->get( 'Author' => 'david' ), "david is still there";
    ok !$store->get( 'Author' => 'Eleonor' ), "Eleonor not saved yet";

    $entry->save;

    ok !$store->get( 'Author' => 'david' ), "david is gone";
    ok $store->get( 'Author' => 'Eleonor' ), "Eleonor not saved";

    is $entry->author->name => 'Eleonor', "Eleonor is the author";
};

subtest 'attribute as hashref' => sub {
    my $entry = $store->create( 'Entry2' => (
        url => '/attribute_as_hashref',
        author => {
            name => 'Freya',
            bio  => 'are you a Freya of the dark?',
        },
    ));

    like $entry->author->bio => qr/dark/, "expanded as object";
    like $store->get( 'Author' => 'Freya' )->bio => qr/dark/, "expanded as object";

};

subtest 'array of models' => sub {
    my $entry = $store->create( Entry2 => (
            url => 'array of models',
            tags => [ { tag => 'foo' }, { tag => 'bar' } ],
    ));

    my @tags = $store->search( 'Tag' )->all;
    is scalar(@tags) => 2, '2 tags';

    is_deeply [ sort map { $_->tag } @tags ], [ qw/ bar foo / ], "right tags";

};
