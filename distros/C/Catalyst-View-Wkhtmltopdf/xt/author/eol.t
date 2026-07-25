use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Catalyst/Helper/View/Wkhtmltopdf.pm',
    'lib/Catalyst/View/Wkhtmltopdf.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-pdf.t',
    't/lib/App.pm',
    't/lib/App/Controller/Root.pm',
    't/lib/App/View/TT.pm',
    't/lib/App/View/Wkhtmltopdf.pm',
    't/lib/App/root/base.tt'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
