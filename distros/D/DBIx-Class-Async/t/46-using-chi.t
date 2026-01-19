#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use lib 't/lib';
use CHI;
use IO::Async::Loop;
use DBIx::Class::Async;

my $tmp  = tempdir(CLEANUP => 1);
my $loop = IO::Async::Loop->new;

my $cache = CHI->new(
    driver   => 'File',
    root_dir => $tmp,
    depth    => 2,
);

my $db = DBIx::Class::Async->new(
    schema_class => 'TestSchema',
    connect_info => ["dbi:SQLite:dbname=$tmp/test.db", '', ''],
    cache        => $cache,
    cache_ttl    => 60,
    loop         => $loop,
);

sub run_test {
    return $db->deploy->then(sub {
        return $db->create('User', { name => 'Test User', active => 1, email => 't@ex.com' });
    })->then(sub {
        return $db->search('User', { active => 1 }, { cache => 1 });
    })->then(sub {
        my $rows = shift;
        is($db->stats->{cache_misses}, 1, "First search is a MISS");
        return $db->search('User', { active => 1 }, { cache => 1 });
    })->then(sub {
        is($db->stats->{cache_hits}, 1, "Second search is a HIT");
        return $db->update('User', 1, { name => 'Updated Name' });
    })->then(sub {
        return $db->search('User', { active => 1 }, { cache => 1 });
    })->then(sub {
        my $rows = shift;
        is($rows->[0]{name}, 'Updated Name', "Got fresh data");
        is($db->stats->{cache_misses}, 2, "Third search is a MISS");
        return Future->done;
    });
}

my $f = run_test()->on_ready(sub { $loop->stop });

$loop->run;

ok($f->is_ready, "Test sequence finished within timeout");

done_testing;
