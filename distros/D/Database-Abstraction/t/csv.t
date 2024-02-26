#!perl -w

use strict;
use FindBin qw($Bin);

use lib 't/lib';
use Test::Most tests => 11;

use_ok('Database::test1');

my $test1 = new_ok('Database::test1' => ["$Bin/../data"]);

cmp_ok($test1->number('two'), '==', 2, 'CSV AUTOLOAD works found');
is($test1->number('four'), undef, 'CSV AUTOLOAD works not found');

my $res = $test1->fetchrow_hashref(entry => 'one');
cmp_ok($res->{'entry'}, 'eq', 'one', 'fetchrow_hashref');
cmp_ok($res->{'number'}, '==', 1, 'fetchrow_hashref');
$res = $test1->fetchrow_hashref(number => 1);
cmp_ok($res->{'entry'}, 'eq', 'one', 'fetchrow_hashref');
cmp_ok($res->{'number'}, '==', 1, 'fetchrow_hashref');

my @rc = $test1->entry(distinct => 1);
cmp_ok(scalar(@rc), '==', 3, 'getting all the distinct entries works');

@rc = $test1->entry();
if($ENV{'TEST_VERBOSE'}) {
	use Data::Dumper;
	diag(Data::Dumper->new([\@rc])->Dump());
}
cmp_ok(scalar(@rc), '==', 3, 'getting all the entries works');

@rc = $test1->selectall_hash();
if($ENV{'TEST_VERBOSE'}) {
	use Data::Dumper;
	diag(Data::Dumper->new([\@rc])->Dump());
}

cmp_ok(scalar(@rc), '==', 3, 'selectall_hashref returns all entries');
