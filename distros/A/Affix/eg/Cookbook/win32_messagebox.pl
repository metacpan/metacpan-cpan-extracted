use utf8;
use Affix;

# Send a Unicode string to the Windows API MessageBoxW function.
use constant MB_OK                   => 0x00000000;
use constant MB_DEFAULT_DESKTOP_ONLY => 0x00020000;
#
affix 'user32', [ MessageBoxW => 'MessageBox' ] => [ Pointer [Void], WStr, WStr, UInt ] => Int;
MessageBox( undef, "Keep your stick on the ice.", "🏒", MB_OK | MB_DEFAULT_DESKTOP_ONLY );
