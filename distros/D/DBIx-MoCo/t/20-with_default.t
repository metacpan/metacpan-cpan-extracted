#!/usr/bin/env perl
use strict;
use warnings;
use FindBin::libs;

ThisTest->runtests;

package ThisTest;
use base qw/Test::Class/;

use Cache::Memory;
use File::Spec;
use Test::More;

use Blog::Entry;

sub startup : Test(startup) {
    $DBIx::MoCo::DataBase::DEBUG = 1;
    open STDERR, '>', File::Spec->devnull;

    Blog::Entry->has_many(
        bookmarks => 'Blog::Bookmark',
        {
            key  => 'entry_id',
            with => [qw/user entry/],
        }
    );
}

sub setup : Test(setup => 1) {
    ok not Blog::Entry->cache_object;
    DBIx::MoCo->start_session;
}

sub teardown : Test(teardown) {
    DBIx::MoCo->end_session;
}

sub with : Test(7) {
    ok( DBIx::MoCo->is_in_session );

    my $entry = Blog::Entry->retrieve(2);

    my $bookmarks = $entry->bookmarks;
    is $bookmarks->size, 2;

    my $cnt_before = $DBIx::MoCo::DataBase::SQL_COUNT;
    isa_ok $bookmarks->first->user, 'Blog::User';
    isa_ok $bookmarks->first->entry, 'Blog::Entry';
    is_deeply [qw/2 3/], [ $bookmarks->map_user->map_user_id ];
    is_deeply [qw/reikon cinnamon/], [ $bookmarks->map_user->map_name ];

    ## No additional SQL were executed
    is $cnt_before, $DBIx::MoCo::DataBase::SQL_COUNT;
}

sub without : Test(4) {
    my $entry = Blog::Entry->retrieve(2);

    my $bookmarks = $entry->bookmarks({ without => [qw/user/] });
    is $bookmarks->size, 2;

    ## Some additional SQLs will be executed
    my $cnt_before = $DBIx::MoCo::DataBase::SQL_COUNT;
    isa_ok $bookmarks->first->user, 'Blog::User';
    isa_ok $bookmarks->first->entry, 'Blog::Entry';
    ok $cnt_before < $DBIx::MoCo::DataBase::SQL_COUNT;
}

__END__
