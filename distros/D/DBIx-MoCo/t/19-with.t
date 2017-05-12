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
}

sub setup : Test(setup => 1) {
    ok not Blog::Entry->cache_object;
    DBIx::MoCo->start_session;
}

sub teardown : Test(teardown) {
    DBIx::MoCo->end_session;
}

sub with : Tests {
    my $entry = Blog::Entry->retrieve(2);
    is $entry->bookmarks->size, 2;
    is $entry->bookmarks({ with => 'user' })->size, 2;

    ok not $entry->bookmarks->first->{user};

    my $bookmarks = $entry->bookmarks({ with => 'user' });

    my $cnt_before = $DBIx::MoCo::DataBase::SQL_COUNT;
    isnt $cnt_before, 0;
    ok $bookmarks->first->user;
    isa_ok $bookmarks->first->user, 'Blog::User';
    is_deeply [qw/2 3/], [ $bookmarks->map_user->map_user_id ];
    is_deeply [qw/reikon cinnamon/], [ $bookmarks->map_user->map_name ];

    ## No additional SQL executed
    is $cnt_before, $DBIx::MoCo::DataBase::SQL_COUNT;
}

sub with_multi : Tests {
    my $entry = Blog::Entry->retrieve(2);

    my $bookmark = $entry->bookmarks({ with => [qw/user entry/] })->first;

    my $cnt_before = $DBIx::MoCo::DataBase::SQL_COUNT;
    isnt $cnt_before, 0;

    isa_ok $bookmark->user,  'Blog::User';
    isa_ok $bookmark->entry, 'Blog::Entry';
    is $bookmark->user->name, 'reikon';
    is $bookmark->entry->title, 'jkondo-2';

    ## No additional SQL executed
    is $cnt_before, $DBIx::MoCo::DataBase::SQL_COUNT;
}

sub search : Tests {
    $DBIx::MoCo::DataBase::SQL_COUNT = 0;

    my $bookmarks = Blog::Bookmark->search(
        where => [ "entry_id = ?", 2 ],
        order => "entry_id asc",
    );
    is $bookmarks->size, 2;

    for (@$bookmarks) {
        isa_ok $_->user,  'Blog::User';
        isa_ok $_->entry, 'Blog::Entry';
    }

    my $cnt_without = $DBIx::MoCo::DataBase::SQL_COUNT;

    DBIx::MoCo->end_session;
    DBIx::MoCo->start_session;
    $DBIx::MoCo::DataBase::SQL_COUNT = 0;

    $bookmarks = Blog::Bookmark->search(
        where => [ "entry_id = ?", 2 ],
        order => "entry_id asc",
        with  => [qw/entry user/]
    );
    for (@$bookmarks) {
        isa_ok $_->user,  'Blog::User';
        isa_ok $_->entry, 'Blog::Entry';
    }

    ok $DBIx::MoCo::DataBase::SQL_COUNT < $cnt_without;
}

sub sql_counts : Tests {
    DBIx::MoCo->cache_object( undef ); ## Turning off explicitly
    my $entry = Blog::Entry->retrieve(2);

    ## not prefetched
    $DBIx::MoCo::DataBase::SQL_COUNT = 0;
    my $bookmarks = $entry->bookmarks;
    $bookmarks->each(sub { $_->user->name; $_->entry->title; });

    my $count_not_prefetched = $DBIx::MoCo::DataBase::SQL_COUNT;

    ## prefetched
    $DBIx::MoCo::DataBase::SQL_COUNT = 0;
    $bookmarks = $entry->bookmarks({ with => [ qw/user entry/] });
    $bookmarks->each(sub { $_->user->name; $_->entry->title; });

    ok $DBIx::MoCo::DataBase::SQL_COUNT < $count_not_prefetched;
}

sub cache : Tests {
    DBIx::MoCo->cache_object( Cache::Memory->new );

    my $test = sub {
        my $entry = Blog::Entry->retrieve(2);
        my $bookmarks = $entry->bookmarks({ with => 'user' });
        is_deeply [qw/2 3/],             [ $bookmarks->map_user->map_user_id ];
        is_deeply [qw/reikon cinnamon/], [ $bookmarks->map_user->map_name    ];
    };

    $DBIx::MoCo::DataBase::SQL_COUNT = 0;
    $test->();
    ok $DBIx::MoCo::DataBase::SQL_COUNT > 0;

    my $cnt_before = $DBIx::MoCo::DataBase::SQL_COUNT;
    $test->() for 1..3;
    is $DBIx::MoCo::DataBase::SQL_COUNT, $cnt_before;

    DBIx::MoCo->cache_object( undef );
}

__END__
