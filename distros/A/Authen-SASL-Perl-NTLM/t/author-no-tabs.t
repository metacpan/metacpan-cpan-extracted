
BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for testing by the author' );
    }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.14

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Authen/SASL/Perl/NTLM.pm', 't/author-critic.t',
    't/author-no-tabs.t',           't/ntlm_client.t',
    't/release-pod-coverage.t',     't/release-pod-syntax.t'
);

notabs_ok($_) foreach @files;
done_testing;
