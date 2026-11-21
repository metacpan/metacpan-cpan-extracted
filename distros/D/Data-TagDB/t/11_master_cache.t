#!/usr/bin/perl -w 

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally
    
use Test::More tests => 10;

use_ok('Data::TagDB::Migration');

my $db = Data::TagDB::Migration->create_memory_database;
isa_ok($db, 'Data::TagDB');

# Test with a pre allocated cache:
my $cache = $db->create_cache;
isa_ok($cache, 'Data::TagDB::Cache');

is($db->master_cache($cache), $cache, 'Set master cache');
is($db->master_cache, $cache, 'Get master cache (set)');

$cache = undef;

is($db->master_cache, undef, 'Get master cache (undef)');

# Test with a on the fly allocated cache:
$cache = $db->master_cache($db->create_cache);
isa_ok($cache, 'Data::TagDB::Cache');
is($db->master_cache, $cache, 'Get master cache (set)');

$cache = undef;

is($db->master_cache, undef, 'Get master cache (undef)');

$db->disconnect;
ok('Still alive');

exit 0;
