
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
    'bin/provis',
    'lib/App/Provision/Cpanm.pm',
    'lib/App/Provision/Cpanmupdate.pm',
    'lib/App/Provision/Cpanupdate.pm',
    'lib/App/Provision/Curl.pm',
    'lib/App/Provision/Foundation.pm',
    'lib/App/Provision/Git.pm',
    'lib/App/Provision/Homebrew.pm',
    'lib/App/Provision/Mysql.pm',
    'lib/App/Provision/Perlbrew.pm',
    'lib/App/Provision/Repoupdate.pm',
    'lib/App/Provision/Sequelpro.pm',
    'lib/App/Provision/Sourcetree.pm',
    'lib/App/Provision/Ssh.pm',
    'lib/App/Provision/Tiny.pm',
    'lib/App/Provision/Wget.pm',
    't/00-compile.t',
    't/01-methods.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
