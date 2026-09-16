use strict;
use warnings;
use Test::More;
use Test::Alien;
use Alien::ghostty;

alien_ok 'Alien::ghostty';

diag 'install_type: ' . Alien::ghostty->install_type;
diag 'version:      ' . (Alien::ghostty->version // 'undef');
diag 'cflags:       ' . Alien::ghostty->cflags;
diag 'libs:         ' . Alien::ghostty->libs;

like(Alien::ghostty->version, qr/^\d+\.\d+\.\d+/, 'version looks like a version');

SKIP: {
    skip 'system install', 2 unless Alien::ghostty->install_type eq 'share';
    my $dir = Alien::ghostty->dist_dir;
    ok(-f "$dir/include/ghostty/vt.h", 'header installed');
    my @dynamic = grep { -e } map { "$dir/lib/libghostty-vt.$_" } qw(so dylib);
    is_deeply(\@dynamic, [], 'no dynamic library in lib/, consumers link statically');
}

done_testing;
