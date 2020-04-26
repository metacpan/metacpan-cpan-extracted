
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
    'bin/git-got',
    'bin/got',
    'bin/got-complete',
    'lib/App/GitGot.pm',
    'lib/App/GitGot/Command.pm',
    'lib/App/GitGot/Command/add.pm',
    'lib/App/GitGot/Command/chdir.pm',
    'lib/App/GitGot/Command/checkout.pm',
    'lib/App/GitGot/Command/clone.pm',
    'lib/App/GitGot/Command/do.pm',
    'lib/App/GitGot/Command/fetch.pm',
    'lib/App/GitGot/Command/fork.pm',
    'lib/App/GitGot/Command/gc.pm',
    'lib/App/GitGot/Command/lib.pm',
    'lib/App/GitGot/Command/list.pm',
    'lib/App/GitGot/Command/milk.pm',
    'lib/App/GitGot/Command/move.pm',
    'lib/App/GitGot/Command/mux.pm',
    'lib/App/GitGot/Command/push.pm',
    'lib/App/GitGot/Command/readd.pm',
    'lib/App/GitGot/Command/remove.pm',
    'lib/App/GitGot/Command/status.pm',
    'lib/App/GitGot/Command/tag.pm',
    'lib/App/GitGot/Command/that.pm',
    'lib/App/GitGot/Command/this.pm',
    'lib/App/GitGot/Command/update.pm',
    'lib/App/GitGot/Command/update_status.pm',
    'lib/App/GitGot/Outputter.pm',
    'lib/App/GitGot/Outputter/dark.pm',
    'lib/App/GitGot/Outputter/light.pm',
    'lib/App/GitGot/Repo.pm',
    'lib/App/GitGot/Repo/Git.pm',
    'lib/App/GitGot/Repositories.pm',
    'lib/App/GitGot/Types.pm',
    't/00-compile.t',
    't/01-run.t',
    't/02-add.t',
    't/03-chdir.t',
    't/04-clone.t',
    't/05-fork.t',
    't/06-list.t',
    't/07-remove.t',
    't/08-status.t',
    't/09-update.t',
    't/10-gc.t',
    't/11-push.t',
    't/12-fetch.t',
    't/13-do.t',
    't/14-move.t',
    't/15-tags.t',
    't/16-checkout.t',
    't/author-eol.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/lib/Test/App/GitGot/Repo.pm',
    't/lib/Test/App/GitGot/Repo/Git.pm',
    't/lib/Test/BASE.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
