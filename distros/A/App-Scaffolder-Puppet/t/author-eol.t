
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/App/Scaffolder/Command/puppetclass.pm',
    'lib/App/Scaffolder/Command/puppetmodule.pm',
    'lib/App/Scaffolder/Puppet.pm',
    'lib/App/Scaffolder/Puppet/Command.pm',
    't/00-compile.t',
    't/000-report-versions-tiny.t',
    't/app.scaffolder.command.puppetclass.t',
    't/app.scaffolder.command.puppetmodule.t',
    't/app.scaffolder.puppet.command.t',
    't/app.scaffolder.puppet.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/lib/App/Scaffolder/CommandTest/puppetclassTest.pm',
    't/lib/App/Scaffolder/CommandTest/puppetmoduleTest.pm',
    't/lib/App/Scaffolder/Puppet/CommandTest.pm',
    't/lib/App/Scaffolder/Puppet/TestBase.pm',
    't/lib/App/Scaffolder/PuppetTest.pm',
    't/release-cpan-changes.t',
    't/release-distmeta.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
