#!/usr/bin/perl -w 

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally
    
use Test::More tests => 5;

use_ok('Data::TagDB::Migration');

my $db = Data::TagDB::Migration->create_memory_database;
isa_ok($db, 'Data::TagDB');

my $tag = $db->tag_by_id(uuid => '8be115d2-dc2f-4a98-91e1-a6e3075cbc31');
isa_ok($tag, 'Data::TagDB::Tag');

my $cache = $db->create_cache;
isa_ok($cache, 'Data::TagDB::Cache');

$cache->add($tag);

$db->disconnect;
ok('Still alive');

exit 0;
