#!perl -T
use strict;
use warnings;
use File::Spec;

use lib File::Spec->catdir('t', 'lib');

ThisTest->runtests;

# ThisTest
package ThisTest;
use base qw/Test::Class/;
use Test::More;
use DBIx::MoCo::Join;
use Blog::BookmarkEntry;
use Data::Dumper;

sub use_test : Tests {
    use_ok 'DBIx::MoCo::Join';
    use_ok 'Blog::BookmarkEntry';
}

sub methods : Tests {
    isa_ok (DBIx::MoCo::Join->schema, 'DBIx::MoCo::Schema');
    is_deeply (DBIx::MoCo::Join->primary_keys, []);
    is_deeply (DBIx::MoCo::Join->unique_keys, []);
    is (DBIx::MoCo::Join->columns, undef);
    is (DBIx::MoCo::Join->cache, undef);
}

sub bookmark_entry : Tests {
    my $bookmarks = Blog::BookmarkEntry->search(
        where => "uri like 'http://test.com%'",
        order => 'uri',
    );
    ok $bookmarks;
    isa_ok $bookmarks, 'DBIx::MoCo::List';
    my $b = $bookmarks->first;
    ok $b;
    is $b->title, 'jkondo-1';
    is $b->uri, 'http://test.com/entry-1';
    my $u = $b->user;
    ok $u;
    is $u->name, 'jkondo';
    eval {$b->param(title => 'wanna change')};
    ok $@, 'fail change';
    is_deeply $b->primary_keys, [];
}

1;
