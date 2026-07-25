use strict;
use warnings;

# This test was generated with Dist::Zilla::Plugin::Test::MixedScripts v0.2.4.

use Test2::Tools::Basic 1.302200;

use Test::MixedScripts qw( file_scripts_ok );

my @scxs = (  );

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

file_scripts_ok($_, { scripts => \@scxs } ) for @files;

done_testing;
