use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Data/Scan.pm',
    'lib/Data/Scan/Impl/Printer.pm',
    'lib/Data/Scan/Printer.pm',
    'lib/Data/Scan/Role/Consumer.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/printer.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
