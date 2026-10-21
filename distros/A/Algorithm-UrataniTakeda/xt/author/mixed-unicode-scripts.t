use strict;
use warnings;

# This test was generated with Dist::Zilla::Plugin::Test::MixedScripts v0.2.4.

use Test2::Tools::Basic 1.302200;

use Test::MixedScripts qw( file_scripts_ok );

my @scxs = (  );

my @files = (
    'lib/Algorithm/UrataniTakeda.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-search.t',
    't/02-errors.t',
    't/03-defects.t',
    't/04-memo-bounded.t',
    't/05-build-cost.t'
);

file_scripts_ok($_, { scripts => \@scxs } ) for @files;

done_testing;
