#!perl

use strict;
use warnings;
use Test::More;
use DBI;
use File::Basename;
use File::Spec;

# Path to test data
my $module_dir = File::Spec->catdir(File::Basename::dirname(__FILE__), '..');
my $data_dir = File::Spec->catdir($module_dir, 't', 'data');
my $excel_file = File::Spec->catfile($data_dir, 'test-data.xls');

my $dbh = DBI->connect("dbi:Excel:file=$excel_file");

# read sheet "products"
my $sth = $dbh->prepare('SELECT * FROM products');
$sth->execute();

# Number of expected records
my $expected_records = 4;

# Count number of records
my $record_count = 0;
while (my $row = $sth->fetchrow_hashref) {
    $record_count++;
    # option: check actual record content
}

$dbh->disconnect;

is($record_count, $expected_records, 'Number of records is correct');

done_testing();