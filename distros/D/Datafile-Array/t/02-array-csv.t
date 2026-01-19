# t/02-array-csv.t
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

use Datafile::Array qw(readarray writearray);

mkdir "$Bin/data"  if ! -d "$Bin/data";
my $csv_file = "$Bin/data/array_csv.txt";

my $csv_content = <<'CSV';
id;name;note
1;Alice;"Hello, world"
2;Bob;"Line1
Line2"
3;"Charlie;X";"Quoted; field"
CSV

open my $fh, '>:encoding(UTF-8)', $csv_file or BAIL_OUT("Cannot create test file: $!");
print $fh $csv_content;
close $fh or BAIL_OUT("Cannot close test file: $!");

my @records;
my @fields;

my ($rc, $msgs) = readarray($csv_file, \@records, \@fields, {
    delimiter  => ';',
    csvquotes  => 1,
    has_headers => 1,
});
is($rc, 3, "Read 3 CSV records");
is($records[0]{name}, 'Alice', "Simple field");
is($records[1]{note}, "Line1\nLine2", "Multi-line field preserved");
is($records[2]{name}, 'Charlie;X', "Quoted delimiter preserved");

unlink $csv_file;
done_testing;
