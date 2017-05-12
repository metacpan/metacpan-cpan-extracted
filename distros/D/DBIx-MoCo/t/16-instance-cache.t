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
use Blog::Entry;
use DBIx::MoCo::Cache;

sub regist : Test(startup) {
    DBIx::MoCo->cache_object( DBIx::MoCo::Cache->new );
    Blog::Entry->icache_expiration(1);
    Blog::Entry->has_a(
        user => 'Blog::User',
        {
            key => 'user_id',
        },
    );
    Blog::Entry->has_many(
        bookmarks => 'Blog::Bookmark',
        {
            key => 'entry_id',
        }
    );
}

sub has_a_cache : Tests {
    my $cs = Blog::Entry->cache_status;
    my $e = Blog::Entry->retrieve(1);
    ok ($e, 'retrieve entry');
    my $u = $e->user;
    my $c1 = $cs->{retrieve_count};
    my $c2 = $cs->{retrieve_icache_count};
    ok ($u, 'e->user');
    is_deeply ($u, $e->user, 'same instance');
    is ($c1+1, $cs->{retrieve_count}, 'ret count');
    is ($c2+1, $cs->{retrieve_icache_count}, 'icache count');
    is_deeply ($u, $e->user, 'same instance');
    is ($c1+2, $cs->{retrieve_count}, 'ret count');
    is ($c2+2, $cs->{retrieve_icache_count}, 'icache count');
    sleep(2);
    is_deeply ($u, $e->user, 'same instance');
    is ($c1+3, $cs->{retrieve_count}, 'ret count');
    is ($c2+2, $cs->{retrieve_icache_count}, 'icache count');
}

sub has_many_cache : Tests {
    my $e = Blog::Entry->retrieve(1);
    my $cs = Blog::Entry->cache_status;
    ok ($e, 'retrieve entry');
    my $bs = $e->bookmarks;
    my $c1 = $cs->{has_many_count};
    my $c2 = $cs->{has_many_icache_count};
    ok ($bs, 'bookmarks');
    is ($bs, $e->bookmarks, 'same instance');
    is ($c1+1, $cs->{has_many_count}, 'has many count');
    is ($c2+1, $cs->{has_many_icache_count}, 'icache count');
    is ($bs, $e->bookmarks, 'same instance');
    is ($c1+2, $cs->{has_many_count}, 'has many count');
    is ($c2+2, $cs->{has_many_icache_count}, 'icache count');
    sleep(2);
    isnt ($bs, $e->bookmarks, 'same instance');
    is ($c1+3, $cs->{has_many_count}, 'has many count');
    is ($c2+2, $cs->{has_many_icache_count}, 'icache count');

    my $bs10 = $e->bookmarks(0,10);
    isnt ($bs, $bs10, 'isnt in offset cond');
    is ($c1+4, $cs->{has_many_count}, 'has many count');
    is ($c2+3, $cs->{has_many_icache_count}, 'icache count');
    is ($bs10, $e->bookmarks(0,10), 'cache bs10');
    is ($c1+5, $cs->{has_many_count}, 'has many count');
    is ($c2+4, $cs->{has_many_icache_count}, 'icache count');
    sleep(2);
    isnt ($bs10, $e->bookmarks(0,10), 'cache bs10');
    is ($c1+6, $cs->{has_many_count}, 'has many count');
    is ($c2+4, $cs->{has_many_icache_count}, 'icache count');
}

sub has_many_cache2 : Tests {
    my $e = Blog::Entry->retrieve(1);
    $e->flush_icache;
    $e->flush_has_many_keys('bookmarks');
    my $cs = Blog::Entry->cache_status;
    ok ($e, 'retrieve entry');
    my $bs = $e->bookmarks(0,1);
    my $c1 = $cs->{has_many_count};
    my $c2 = $cs->{has_many_icache_count};
    ok ($bs, 'bookmarks');
    is ($bs, $e->bookmarks(0,1), 'same instance');
    is ($c1+1, $cs->{has_many_count}, 'has many count');
    is ($c2+1, $cs->{has_many_icache_count}, 'icache count');
    is ($bs, $e->bookmarks(0,1), 'same instance');
    is ($c1+2, $cs->{has_many_count}, 'has many count');
    is ($c2+2, $cs->{has_many_icache_count}, 'icache count');
    my $bs2 = $e->bookmarks(0,2);
    isnt ($bs, $bs2, 'isnt in offset cond');
    is ($c1+3, $cs->{has_many_count}, 'has many count');
    is ($c2+2, $cs->{has_many_icache_count}, 'icache count');
    is ($bs2, $e->bookmarks(0,2), 'cache bs10');
    is ($c1+4, $cs->{has_many_count}, 'has many count');
    is ($c2+3, $cs->{has_many_icache_count}, 'icache count');
}

1;
