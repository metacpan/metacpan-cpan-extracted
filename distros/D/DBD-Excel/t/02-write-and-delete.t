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
my $excel_file = File::Spec->catfile($data_dir, '02-test-data.xls');

my $dbh = DBI->connect("dbi:Excel:file=$excel_file");

{
    # add new row sheet "products"
    my $sth = $dbh->prepare('INSERT INTO products VALUES (?,?,?,?)');
    $sth->execute(5, 'test5 title', 'test5 description', 666);
}

{
    # check if new row is present
    my $record_count = count_records($dbh, 'products');
    my $expected_records = 5;
    is($record_count, $expected_records, 'Number of records is correct');
}

{
    # remove records #5 again
    my $sth = $dbh->prepare('DELETE FROM products WHERE product_id = ?');
    $sth->execute(5);
    
    my $record_count = count_records($dbh, 'products');
    my $expected_records = 4;
    is($record_count, $expected_records, 'Number of records is correct');
}

$dbh->disconnect;

done_testing();



sub count_records {
    my $dbh = shift or die("Missing database handle");
    my $table = shift or die("Missing table name");
    
    die("Invalid table name: $table") if $table !~ m/^[a-zA-z_]+$/;
    
    my $sth = $dbh->prepare('SELECT * FROM ' . $table);
    $sth->execute();
    
    # Count number of records
    my $record_count = 0;
    while (my $row = $sth->fetchrow_hashref) {
        $record_count++;
    }
    
    return $record_count;
}