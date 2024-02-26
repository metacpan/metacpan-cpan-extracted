#!perl -w

use strict;
use FindBin qw($Bin);

use lib 't/lib';
use Test::Most tests => 7;

use_ok('Database::test3');

my $test3 = new_ok('Database::test3' => ["$Bin/../data"]);

cmp_ok($test3->fr('2'), 'eq', 'Deux', 'XML AUTOLOAD works found');
is($test3->fr('4'), undef, 'XML AUTOLOAD works not found');

my @rc = $test3->entry(distinct => 1);
cmp_ok(scalar(@rc), '==', 2, 'getting all the distinct entries works');

@rc = $test3->entry();
if($ENV{'TEST_VERBOSE'}) {
	use Data::Dumper;
	diag(Data::Dumper->new([\@rc])->Dump());
}
cmp_ok(scalar(@rc), '==', 2, 'getting all the entries works');

@rc = $test3->selectall_hash();
if($ENV{'TEST_VERBOSE'}) {
	use Data::Dumper;
	diag(Data::Dumper->new([\@rc])->Dump());
}

cmp_ok(scalar(@rc), '==', 2, 'selectall_hashref returns all entries');
