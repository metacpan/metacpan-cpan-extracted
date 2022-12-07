use strict;
use warnings;
use Affix;
$|++;
#
CORE::say 'MessageBoxA(...) = ' .
    wrap( 'C:\Windows\System32\user32.dll', 'MessageBoxA', [ UInt, Str, Str, UInt ] => Int )
    ->( 0, 'JAPH!', 'Hello, World', 0 );
