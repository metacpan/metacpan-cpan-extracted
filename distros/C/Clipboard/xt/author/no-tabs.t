use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Clipboard.pm',
    'lib/Clipboard/MacPasteboard.pm',
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

notabs_ok($_) foreach @files;
done_testing;
