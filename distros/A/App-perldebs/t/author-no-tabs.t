
BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        print qq{1..0 # SKIP these tests are for testing by the author\n};
        exit;
    }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/perldebs',                               'lib/App/perldebs.pm',
    't/author-critic.t',                          't/author-no-tabs.t',
    't/author-pod-coverage.t',                    't/author-pod-syntax.t',
    't/cucumber.t',                               't/features/cpanfile_parsing.feature',
    't/features/cpanfile_parsing.feature~',       't/features/step_definitions/basic.pl~',
    't/features/step_definitions/basic_steps.pl', 't/features/step_definitions/basic_steps.pl~',
    't/release-changes_has_content.t'
);

notabs_ok($_) foreach @files;
done_testing;
