use strict;
use warnings;

use lib './t/lib';
use Test::Clipboard;
use Test::MockClipboard;
$Clipboard::driver = 'PhonyClipboard';
my $str = 'Semirobotic Invasion';
Clipboard->copy($str);
is($PhonyClipboard::board, $str, 'copy');
is(Clipboard->paste, $str, 'paste');
