use strict;
use warnings;

use lib './t/lib';
use Test::Clipboard;
my %map = qw(
    linux Xclip
    freebsd Xclip
    netbsd Xclip
    openbsd Xclip
    dragonfly Xclip
    Win32 Win32
    cygwin Win32
    darwin MacPasteboard
);

use_ok 'Clipboard';

# Preferentially use Clipboard::WaylandClipboard if we see WAYLAND_DISPLAY
if (exists($ENV{WAYLAND_DISPLAY}) && length($ENV{WAYLAND_DISPLAY}))
{
    use_ok 'Clipboard::WaylandClipboard';
    foreach my $os (sort keys %map) {
      $map{$os} = 'WaylandClipboard' if ($map{$os} ne 'Win32');
    }
} else {
    use_ok 'Clipboard::Xclip';
}

if ( exists $ENV{SSH_CONNECTION} && Clipboard::Xclip::xclip_available() )
{
    $map{Win32}  = 'Xclip';
    $map{cygwin} = 'Xclip';
}

is( Clipboard->find_driver($_), $map{$_}, $_ ) for keys %map;

my $drv = Clipboard->find_driver($^O);
ok( exists $INC{"Clipboard/$drv.pm"}, "Driver-check ($drv)" );

eval {
    local %ENV = %ENV;
    delete $ENV{DISPLAY};
    delete $ENV{WAYLAND_DISPLAY};
    Clipboard->find_driver('NonOS');
};
like(
    $@,
    qr/is not yet supported/,
    'find_driver correctly fails with no DISPLAY'
);

SKIP:
{
    if ( not $ENV{AUTHOR_TESTING} )
    {
        skip 'Author test', 2;
    }
    my $display_drv = do
    {
        local %ENV = %ENV;
        $ENV{DISPLAY} = ':0.0';
        Clipboard->find_driver('NonOS');
    };
    is $display_drv, 'Xsel', 'driver is Xclip on unknown OS with DISPLAY set';
    is( $Clipboard::driver, "Clipboard::$drv", "Actually loaded $drv" );
    my $silence_stupid_warning = $Clipboard::driver;
}
