#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use File::Temp qw(tempfile);

use_ok('DNSQuery::Cache');

# Test basic cache operations
subtest 'Basic cache operations' => sub {
    my $cache = DNSQuery::Cache->new(max_size => 5);
    
    # Test set and get
    $cache->set('key1', 'value1', 10);
    is($cache->get('key1'), 'value1', 'Set and get value');
    
    # Test non-existent key
    is($cache->get('nonexistent'), undef, 'Non-existent key returns undef');
    
    # Test size
    is($cache->size(), 1, 'Cache size is 1');
    
    # Test delete
    $cache->delete('key1');
    is($cache->get('key1'), undef, 'Deleted key returns undef');
    is($cache->size(), 0, 'Cache size is 0 after delete');
};

# Test TTL expiration
subtest 'TTL expiration' => sub {
    my $cache = DNSQuery::Cache->new();
    
    # Set with 1 second TTL
    $cache->set('key1', 'value1', 1);
    is($cache->get('key1'), 'value1', 'Value exists before expiration');
    
    # Wait for expiration
    sleep 2;
    is($cache->get('key1'), undef, 'Value expired after TTL');
};

# Test LRU eviction
subtest 'LRU eviction' => sub {
    my $cache = DNSQuery::Cache->new(max_size => 3);
    
    $cache->set('key1', 'value1', 60);
    $cache->set('key2', 'value2', 60);
    $cache->set('key3', 'value3', 60);
    
    is($cache->size(), 3, 'Cache at max size');
    
    # Access key1 to make it more recent
    $cache->get('key1');
    
    # Add key4, should evict key2 (least recently used)
    $cache->set('key4', 'value4', 60);
    
    is($cache->size(), 3, 'Cache still at max size');
    is($cache->get('key1'), 'value1', 'Recently accessed key1 still exists');
    is($cache->get('key2'), undef, 'LRU key2 was evicted');
    is($cache->get('key4'), 'value4', 'New key4 exists');
};

# Test statistics
subtest 'Cache statistics' => sub {
    my $cache = DNSQuery::Cache->new();
    
    $cache->set('key1', 'value1', 60);
    
    # Hit
    $cache->get('key1');
    
    # Miss
    $cache->get('nonexistent');
    
    my $stats = $cache->get_stats();
    
    is($stats->{hits}, 1, 'Hit count is 1');
    is($stats->{misses}, 1, 'Miss count is 1');
    is($stats->{size}, 1, 'Cache size is 1');
    ok($stats->{hit_rate} > 0, 'Hit rate calculated');
};

# Test clear
subtest 'Clear cache' => sub {
    my $cache = DNSQuery::Cache->new();
    
    $cache->set('key1', 'value1', 60);
    $cache->set('key2', 'value2', 60);
    
    is($cache->size(), 2, 'Cache has 2 entries');
    
    $cache->clear();
    
    is($cache->size(), 0, 'Cache cleared');
    is($cache->get('key1'), undef, 'Key1 gone after clear');
};

# Test persistence
subtest 'Cache persistence' => sub {
    my ($fh, $filename) = tempfile(UNLINK => 1);
    close $fh;
    
    # Create cache with persistence
    my $cache1 = DNSQuery::Cache->new(
        persist => 1,
        cache_file => $filename,
    );
    
    $cache1->set('key1', 'value1', 3600);
    $cache1->set('key2', 'value2', 3600);
    
    # Force save
    undef $cache1;
    
    # Load from disk
    my $cache2 = DNSQuery::Cache->new(
        persist => 1,
        cache_file => $filename,
    );
    
    is($cache2->get('key1'), 'value1', 'Value persisted to disk');
    is($cache2->get('key2'), 'value2', 'Second value persisted to disk');
};

done_testing();
