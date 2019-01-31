use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/sky',
    'lib/App/Sky.pm',
    'lib/App/Sky/CmdLine.pm',
    'lib/App/Sky/Config/Validate.pm',
    'lib/App/Sky/Exception.pm',
    'lib/App/Sky/Manager.pm',
    'lib/App/Sky/Module.pm',
    'lib/App/Sky/Results.pm',
    't/00-compile.t',
    't/config-validate.t',
    't/data/sample-configs/shlomif1/config.yaml',
    't/manager.t',
    't/module.t',
    't/style-trailing-space.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
