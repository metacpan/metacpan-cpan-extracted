use v5.40;
use Affix;
#
say 'MessageBoxA(...) = ' . wrap( 'user32', 'MessageBoxA', [ UInt, String, String, UInt ] => Int )->( 0, 'JAPH!', 'Hello, World', 0 );
