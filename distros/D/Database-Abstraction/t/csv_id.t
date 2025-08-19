#!perl -w

use strict;
use FindBin qw($Bin);

use File::Spec;
use Test::Most tests => 11;
use Test::NoWarnings;

use lib 't/lib';
use_ok('Database::test5');

my $directory = File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');
my $test5 = new_ok('Database::test5' => [directory => $directory]);

cmp_ok($test5->Name(101), 'eq', 'John Doe', 'CSV AUTOLOAD works found');

my $res = $test5->fetchrow_hashref(entry => '102');

if($ENV{'TEST_VERBOSE'}) {
	use Data::Dumper;
	diag(Data::Dumper->new([\$res])->Dump());
}

cmp_ok($res->{'ID'}, '==', '102', 'fetchrow_hashref');
cmp_ok($res->{'Age'}, '==', 35, 'fetchrow_hashref');

# Test fetching all records
my @all_records = $test5->selectall_hash();
diag(Data::Dumper->new([\@all_records])->Dump()) if($ENV{'TEST_VERBOSE'});
cmp_ok($test5->count(), '==', 5, 'count returns 5');
is(scalar @all_records, 5, 'Fetched all records');

# Test fetching a specific record
my $john_doe = $test5->fetchrow_hashref(id => 101);
is($john_doe->{'name'}, 'John Doe', 'Fetched John Doe');

# Test executing a simple query
my @young_people = $test5->execute(query => 'SELECT * FROM test5 WHERE age < 30');
is(scalar(@young_people), 2, 'Fetched young people');

# Test AUTOLOAD feature
my @names = $test5->name();
is(scalar(@names), 5, 'Fetched all names');
