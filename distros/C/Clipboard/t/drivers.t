use Test::Clipboard;
use strict; # XXX make Test::Clipboard do this
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
is(Clipboard->find_driver($_), $map{$_}, $_) for keys %map;
my $drv = Clipboard->find_driver($^O);
ok(exists $INC{"Clipboard/$drv.pm"}, "Driver-check ($drv)");
eval { Clipboard->find_driver('NonOS') };
like($@, qr/is not yet supported/, 'find_driver correctly fails');

is($Clipboard::driver, "Clipboard::$drv", "Actually loaded $drv");
my $silence_stupid_warning = $Clipboard::driver;
