#!perl -w

use strict;
use Data::Dumper;
use FindBin qw($Bin);

use lib 't/lib';
use Test::Most tests => 9;

use_ok('Database::test2');

my $directory = File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');
my $test2 = new_ok('Database::test2' => [directory => $directory]);

cmp_ok($test2->number('third'), 'eq', '3rd', 'PSV AUTOLOAD works found');
is($test2->number('four'), undef, 'PSV AUTOLOAD works not found');

my $res = $test2->fetchrow_hashref(entry => 'first');
cmp_ok($res->{'entry'}, 'eq', 'first', 'fetchrow_hashref');
cmp_ok($res->{'number'}, 'eq', '1st', 'fetchrow_hashref');

my @rc = $test2->entry(unique => 1);
cmp_ok(scalar(@rc), '==', 3, 'getting all the distinct entries works');

@rc = $test2->entry();
if($ENV{'TEST_VERBOSE'}) {
	diag(Data::Dumper->new([\@rc])->Dump());
}
cmp_ok(scalar(@rc), '==', 3, 'getting all the entries works');

@rc = $test2->selectall_hash();
if($ENV{'TEST_VERBOSE'}) {
	diag(Data::Dumper->new([\@rc])->Dump());
}

cmp_ok(scalar(@rc), '==', 3, 'selectall_hash returns all entries');
