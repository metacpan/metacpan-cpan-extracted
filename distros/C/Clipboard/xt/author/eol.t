use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Clipboard.pm',
    'lib/Clipboard/MacPasteboard.pm',
    'lib/Clipboard/WaylandClipboard.pm',
    'lib/Clipboard/Win32.pm',
    'lib/Clipboard/Xclip.pm',
    'lib/Clipboard/Xsel.pm',
    'scripts/clipaccumulate',
    'scripts/clipbrowse',
    'scripts/clipedit',
    'scripts/clipfilter',
    'scripts/clipjoin',
    't/drivers.t',
    't/lib/Test/Clipboard.pm',
    't/lib/Test/MockClipboard.pm',
    't/mock.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
