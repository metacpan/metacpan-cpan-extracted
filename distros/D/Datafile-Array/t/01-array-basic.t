# t/01-array-basic.t
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

use Datafile::Array qw(readarray writearray);

mkdir "$Bin/data"  if ! -d "$Bin/data";
my $data_file = "$Bin/data/array_basic.txt";

# Write test data
my @records = (
    { id => 1, name => 'Alice', city => 'NY' },
    { id => 2, name => 'Bob',   city => 'LA' },
);

my @fields = qw(id name city);

my ($wc, $wmsgs) = writearray($data_file, \@records, \@fields, {
    delimiter => ';',
    header    => 1,
    comment   => 'Test data',
});

ok($wc == 2, "Wrote 2 records");

# Read back
my @read_records;
my @read_fields;

my ($rc, $rmsgs) = readarray($data_file, \@read_records, \@read_fields, {
    delimiter   => ';',
    has_headers => 1,
});

is($rc, 2, "Read 2 records");
is_deeply(\@read_fields, \@fields, "Fields match");
is_deeply(\@read_records, \@records, "Round-trip data matches");

unlink $data_file;
done_testing;
