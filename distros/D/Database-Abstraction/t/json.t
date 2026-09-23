#!perl -w

use strict;
use warnings;
use FindBin qw($Bin);

use lib 't/lib';
use Test::Most;
use Test::Needs 'JSON::MaybeXS';

plan tests => 9;

use Database::test_json;

my $directory = File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');
my $db = new_ok('Database::test_json' => [directory => $directory]);

cmp_ok($db->number('third'), 'eq', '3rd', 'JSON AUTOLOAD returns correct value');
is($db->number('four'), undef, 'JSON AUTOLOAD returns undef for missing key');

my $res = $db->fetchrow_hashref(entry => 'first');
cmp_ok($res->{'entry'}, 'eq', 'first', 'fetchrow_hashref entry column');
cmp_ok($res->{'number'}, 'eq', '1st', 'fetchrow_hashref number column');

my @rc = $db->entry(unique => 1);
cmp_ok(scalar(@rc), '==', 4, 'distinct entry values returns 4');

@rc = $db->entry();
cmp_ok(scalar(@rc), '==', 4, 'all entry values returns 4');

@rc = $db->selectall_hash();
cmp_ok(scalar(@rc), '==', 4, 'selectall_hash returns all 4 rows');

my @perls = $db->perl('5.42.3');
cmp_ok(scalar(@perls), '>=', 1, 'perl() AUTOLOAD returns at least one entry for version 5.42.3');
