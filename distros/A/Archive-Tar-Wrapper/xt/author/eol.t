use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Archive/Tar/Wrapper.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/001Basic.t',
    't/002Mult.t',
    't/003Dirs.t',
    't/004Utf8.t',
    't/005Cwd.t',
    't/006DirPerms.t',
    't/007bzip.t',
    't/009compressed.t',
    't/010openbsd.t',
    't/011remdots.t',
    't/012tarinfo.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
