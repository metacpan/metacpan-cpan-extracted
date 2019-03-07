use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/spread-revolutionary-date',
    'lib/App/SpreadRevolutionaryDate.pm',
    'lib/App/SpreadRevolutionaryDate/Config.pm',
    'lib/App/SpreadRevolutionaryDate/Freenode.pm',
    'lib/App/SpreadRevolutionaryDate/Freenode/Bot.pm',
    'lib/App/SpreadRevolutionaryDate/Mastodon.pm',
    'lib/App/SpreadRevolutionaryDate/Twitter.pm',
    't/00-compile.t',
    't/config.t',
    't/locale.t',
    't/objects.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
