#!/usr/bin/perl
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Cache::Ehcache;

my $cache = Cache::Ehcache->new( namespace => 'cache_ehcache' );

print "Set cacahe\n";

$cache->set( 'foo', 'bar' );

print "Get cacahe\n";
print $cache->get('foo') . "\n";

print "Delete cacahe\n";
$cache->delete('foo');
print $cache->get('foo') . "\n";

print "Delete cacahe\n";
$cache->delete('baz');

print "Clear cacahe\n";
$cache->clear;

exit;
