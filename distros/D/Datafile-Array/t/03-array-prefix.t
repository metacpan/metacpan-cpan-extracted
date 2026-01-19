# t/03-array-prefix.t
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

use Datafile::Array qw(readarray writearray);

mkdir "$Bin/data"  if ! -d "$Bin/data";
my $prefix_file = "$Bin/data/array_prefix.txt";

my @records = (
    { name => 'Alice', score => 95 },
    { name => 'Bob',   score => 87 },
);

my @fields = qw(name score);

writearray($prefix_file, \@records, \@fields, {
    delimiter => "\t",
    prefix    => 1,
    header    => 1,
});

my @read;
my @f;

my ($rc) = readarray($prefix_file, \@read, \@f, {
    delimiter   => "\t",
    prefix      => 1,
    has_headers => 1,
});

is($rc, 2, "Read prefixed file");
is($read[0]{name}, 'Alice', "Data correct after prefix");

unlink $prefix_file;
done_testing;
