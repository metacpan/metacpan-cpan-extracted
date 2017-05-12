#!/usr/bin/env perl
use strict;
use warnings;
use FindBin::libs;

ThisTest->runtests;

package ThisTest;
use base qw/Test::Class/;
use Test::More;

use Cache::Memory;
use Blog::Entry;

sub retrieve_multi : Test(23) {
    my $entries = Blog::Entry->retrieve_multi(
        { entry_id => 1 },
        { entry_id => 2 },
        { entry_id => 3 },
        { entry_id => 4 },
    );

    ok     $entries;
    isa_ok $entries, 'DBIx::MoCo::List',
    is     $entries->size, 4;

    for my $entry (@$entries) {
        ok $entry;
        isa_ok $entry, 'Blog::Entry';
        ok $entry->uri;
        ok $entry->user_id;
        ok $entry->body;
    }
}

sub null : Test(5) {
    my $zero = Blog::Entry->retrieve_multi(
        { entry_id => 99 },
        { entry_id => 100 },
    );

    ok     $zero;
    isa_ok $zero, 'DBIx::MoCo::List';
    is     $zero->size, 0;

    my $entries = Blog::Entry->retrieve_multi(
        { entry_id => 1 },
        { entry_id => 100 },
        { entry_id => 2 },
    );

    is $entries->size, 2;
    is_deeply [ qw/1 2/ ], [ $entries->map_entry_id ];
}

sub list_context : Test(3) {
    my @queries = (
        { entry_id => 1 },
        { entry_id => 2 },
        { entry_id => 3 },
        { entry_id => 4 },
    );
    my @entries = Blog::Entry->retrieve_multi(@queries);

    is @entries, 4;
    ok not ref @entries;

    my $entries = Blog::Entry->retrieve_multi(@queries);
    is_deeply $entries, \@entries;
}

sub ordering : Test(3) {
    my @queries = (
        { entry_id => 1 },
        { entry_id => 2 },
        { entry_id => 3 },
        { entry_id => 4 },
    );

    my $sorted = Blog::Entry->retrieve_multi(@queries);
    is_deeply [ qw/1 2 3 4/ ], [ $sorted->map_entry_id ];

    my $reverse = Blog::Entry->retrieve_multi(reverse @queries);
    is_deeply [ qw/4 3 2 1/ ], [ $reverse->map_entry_id ];

    my $random = Blog::Entry->retrieve_multi(
        { entry_id => 2 },
        { entry_id => 1 },
        { entry_id => 4 },
        { entry_id => 3 },
    );
    is_deeply [ qw/2 1 4 3/ ], [ $random->map_entry_id ];
}

sub cache : Tests {
    ## It is easier to manage whole caches than Cache::FastMmap.
    my $cache_orig = Blog::Entry->cache_object;
    my $cache = Cache::Memory->new(
        namescape       => __PACKAGE__,
        default_expires => '600 sec'
    );
    Blog::Entry->cache_object($cache);
    my $cache_st = Blog::Entry->cache_status;

    ## This callback is called anytime a 'get' is issued for data that does not exist in the cache.
    my $cache_miss_count = 0;
    $cache->set_load_callback(
        sub {
            $cache_miss_count++;
            return;
        }
    );
    is $cache->count, 0;
    is $cache_miss_count, 0;
    is $cache_st->{retrieve_count}, 0;
    is $cache_st->{retrieve_cache_count}, 0;

    ## 2 objects will be retrieved from the storage.
    my $entries = Blog::Entry->retrieve_multi(
        { entry_id => 1 },
        { entry_id => 3 },
    );
    is $entries->size, 2;
    is $cache_miss_count, 2;
    is_deeply [qw/1 3/], [ $entries->map_entry_id ];
    is $cache->count, 4; # ((by primary key) + (by unique key)) * 2
    is $cache_st->{retrieve_count}, 2;
    is $cache_st->{retrieve_cache_count}, 0;

    ## Early 2 objects will be retrieved from the cache, Other 2 will be from storage.
    $entries = Blog::Entry->retrieve_multi(
        { entry_id => 1 },
        { entry_id => 2 },
        { entry_id => 3 },
        { entry_id => 4 },
    );
    is $entries->size, 4;
    is $cache_miss_count, 4;
    is_deeply [qw/1 2 3 4/], [ $entries->map_entry_id ];
    is $cache->count, 8; # ((by primary key) + (by unique key)) * 4
    is $cache_st->{retrieve_count}, 6;
    is $cache_st->{retrieve_cache_count}, 2;

    ## All objects will be found in the cache
    $entries = Blog::Entry->retrieve_multi(
        { entry_id => 2 },
        { entry_id => 1 },
        { entry_id => 4 },
        { entry_id => 3 },
    );
    is $entries->size, 4;
    is $cache_miss_count, 4;  ## not incremented
    is_deeply [qw/2 1 4 3/], [ $entries->map_entry_id ];
    is $cache->count, 8; ## not incremented
    is $cache_st->{retrieve_count}, 10;
    is $cache_st->{retrieve_cache_count}, 6;

    ## Null cache is now deprecated
    $entries = Blog::Entry->retrieve_multi(
        { entry_id => 99 },
        { entry_id => 100 },
    );
    is $entries->size, 0;
    is $cache_miss_count, 6;
    is $cache->count, 8; ## not incremented
    is $cache_st->{retrieve_count}, 12;
    is $cache_st->{retrieve_cache_count}, 6;

    ## Querying again, null objects will NOT be retrieved from the cache.
    $entries = Blog::Entry->retrieve_multi(
        { entry_id => 99 },
        { entry_id => 100 },
    );
    is $entries->size, 0;
    is $cache_miss_count, 8;
    is $cache->count, 8; ## not incremented
    is $cache_st->{retrieve_count}, 14;
    is $cache_st->{retrieve_cache_count}, 6;

    Blog::Entry->cache_object($cache_orig);
}

sub pk_is_zero : Tests {
    my $entry = Blog::Entry->create(
        entry_id => 0,
        user_id  => 1,
        uri      => 'http://b.hatena.ne.jp/',
        title    => 'zero primary',
        body     => '',
    );

    my $entries = Blog::Entry->retrieve_multi(
        { entry_id => 0 },
        { entry_id => 1 }
    );
    is $entries->size, 2;

    $entry->delete;
}

__END__
