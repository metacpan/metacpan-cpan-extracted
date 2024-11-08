#!perl -w

use strict;
use FindBin qw($Bin);

use lib 't/lib';
use Test::Most tests => 6;
use Test::NoWarnings;

use_ok('Database::test5');

my $test5 = new_ok('Database::test5' => [directory => "$Bin/../data"]);

cmp_ok($test5->Name(101), 'eq', 'John Doe', 'CSV AUTOLOAD works found');

my $res = $test5->fetchrow_hashref(entry => '102');

if($ENV{'TEST_VERBOSE'}) {
	use Data::Dumper;
	diag(Data::Dumper->new([\$res])->Dump());
}

cmp_ok($res->{'ID'}, '==', '102', 'fetchrow_hashref');
cmp_ok($res->{'Age'}, '==', 35, 'fetchrow_hashref');
