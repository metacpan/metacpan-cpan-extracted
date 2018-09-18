use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/deps-app',
    'lib/App/Deps/Verify.pm',
    'lib/App/Deps/Verify/App/VerifyDeps.pm',
    'lib/App/Deps/Verify/App/VerifyDeps/Command/verify.pm',
    't/00-compile.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
