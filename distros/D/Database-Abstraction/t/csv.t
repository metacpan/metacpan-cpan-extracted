#!perl -w

use strict;
use FindBin qw($Bin);

use lib 't/lib';
use Test::Most tests => 20;
use Test::NoWarnings;

use_ok('Database::test1');

my $test1 = new_ok('Database::test1' => ["$Bin/../data"]);

cmp_ok($test1->number('two'), '==', 2, 'CSV AUTOLOAD works found');
is($test1->number('four'), undef, 'CSV AUTOLOAD works not found');

my $res = $test1->fetchrow_hashref(entry => 'one');
cmp_ok($res->{'entry'}, 'eq', 'one', 'fetchrow_hashref');
cmp_ok($res->{'number'}, '==', 1, 'fetchrow_hashref');
$res = $test1->fetchrow_hashref('one');
cmp_ok($res->{'entry'}, 'eq', 'one', 'fetchrow_hashref - key is entry');
cmp_ok($res->{'number'}, '==', 1, 'fetchrow_hashref - key is entry');
$res = $test1->fetchrow_hashref(number => 1);
cmp_ok($res->{'entry'}, 'eq', 'one', 'fetchrow_hashref');
cmp_ok($res->{'number'}, '==', 1, 'fetchrow_hashref');

my @rc = $test1->entry(distinct => 1);
cmp_ok(scalar(@rc), '==', 4, 'getting all the distinct entries works');

@rc = $test1->entry();
if($ENV{'TEST_VERBOSE'}) {
	use Data::Dumper;
	diag(Data::Dumper->new([\@rc])->Dump());
}
cmp_ok(scalar(@rc), '==', 4, 'getting all the entries works');

@rc = $test1->selectall_hash();
if($ENV{'TEST_VERBOSE'}) {
	use Data::Dumper;
	diag(Data::Dumper->new([\@rc])->Dump());
}

cmp_ok(scalar(@rc), '==', 4, 'selectall_hashref returns all entries');

my $entry = $test1->entry(number => 2);

if($ENV{'TEST_VERBOSE'}) {
	use Data::Dumper;
	diag(Data::Dumper->new([\@rc])->Dump());
}

cmp_ok($entry, 'eq', 'two', 'look up a key');

@rc = $test1->execute("SELECT number FROM test1 WHERE entry IS NOT NULL AND entry NOT LIKE '#%'");

if($ENV{'TEST_VERBOSE'}) {
	use Data::Dumper;
	diag(Data::Dumper->new([\@rc])->Dump());
}

cmp_ok(scalar(@rc), '==', 4, 'execute() returns all entries');

dies_ok(sub { my $foo = $test1->foo('one') }, 'AUTOLOAD dies on invalid column');
like($@, qr/There is no column foo in test1/, 'Correct test message for invalid column in AUTOLOAD');

my $unknown;
lives_ok(sub { $unknown = $test1->number('empty') }, 'AUTOLOAD survives empty column');
ok(!defined($unknown));
