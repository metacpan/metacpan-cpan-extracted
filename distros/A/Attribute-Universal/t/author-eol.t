
BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for testing by the author' );
    }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Attribute/Universal.pm', 't/00-check-deps.t',
    't/00-compile.t',             't/author-critic.t',
    't/author-eol.t',             't/author-no-tabs.t',
    't/collect.t',                't/content.t',
    't/foobar.pm',                't/hash.t',
    't/import.t',                 't/phases.t',
    't/release-cpan-changes.t',   't/release-fixme.t',
    't/release-kwalitee.t',       't/release-pod-coverage.t',
    't/release-pod-syntax.t',     't/simple.t',
    't/types.t'
);

eol_unix_ok( $_, { trailing_whitespace => 1 } ) foreach @files;
done_testing;
