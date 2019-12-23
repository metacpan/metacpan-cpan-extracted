use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/AWS/Lambda/Quick.pm',
    'lib/AWS/Lambda/Quick/CreateZip.pm',
    'lib/AWS/Lambda/Quick/Processor.pm',
    'lib/AWS/Lambda/Quick/Upload.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/02zip.t',
    't/03process.t',
    't/lib/TestHelper/CreateTestFiles.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
