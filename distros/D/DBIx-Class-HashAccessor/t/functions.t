#!/usr/bin/env perl
use strict;
use warnings;

use lib 't/lib';
use Test::More;

use TestSchema;
my $schema = TestSchema->deploy_or_connect();

my $result = $schema->resultset('Data')->new({});

isa_ok($result,'TestSchema::Result::Data','New result given');

# basic accessor
ok($result->can('da'),'Result can accessor');
is($result->da('test',22),22,'Accessor set test');
is($result->da('test'),22,'Accessor get test');
ok($result->da_exists('test'),'Exist accessor test');
is($result->da_delete('test'),22,'Accessor delete test');
ok(!$result->da_exists('test'),'Not exist accessor test');

# hash accessors
is($result->da_hash('hash','key',33),33,'Hash accessor set test');
is($result->da_hash('hash','key'),33,'Hash accessor get test');
is($result->da_hash_delete('hash','key'),33,'Hash accessor delete test');
is($result->da_hash('hash','key'),undef,'Hash accessor delete test, checked deleted');

# array accessors
is_deeply([$result->da_push('array',1,2,3)],[1,2,3],'Array accessor push test');
is_deeply($result->da('array'),[1,2,3],'Accessor get push test result');
is($result->da_shift('array'),1,'Array accessor shift test');
is_deeply($result->da('array'),[2,3],'Accessor get shift test result');
ok($result->da_in('array',2),'Array accessor in test');
ok(!$result->da_in('array',4),'Array accessor not in test');
$result->da_in_delete('array',2);
is_deeply($result->da('array'),[3],'Accessor get in delete result');

# checking final state
ok($result->da_exists('hash'),'Final stage hash exists test');
ok($result->da_exists('array'),'Final stage array exists test');

done_testing;
