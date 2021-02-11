use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/CGI/Application/Plugin/TT/LastModified.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-compile.t',
    't/auto-last-modified.t',
    't/last-modified.t',
    't/lib/TestApp/AutoLastModified.pm',
    't/lib/TestApp/LastModified.pm',
    't/lib/TestApp/Plain.pm',
    't/lib/TestApp/base.pm',
    't/plain.t',
    't/templates/bottom.html',
    't/templates/index.html',
    't/templates/top.html'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
