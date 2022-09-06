use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Data/Record/Serialize/Encode/csv.pm',
    'lib/Data/Record/Serialize/Encode/csv_stream.pm',
    'lib/Data/Record/Serialize/Role/Encode/CSV.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/data/encoders/data.csv',
    't/encoders/csv.t',
    't/encoders/csv_stream.t'
);

notabs_ok($_) foreach @files;
done_testing;
