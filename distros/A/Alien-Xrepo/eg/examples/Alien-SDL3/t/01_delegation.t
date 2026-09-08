use v5.40;
use blib;
use Test2::V0;
use Alien::SDL3;
#
my $sdl3 = Alien::SDL3->new;

# Not yet resolvable: Runtime accessors are lazy, so a cold checkout (no
# snapshot, store empty or xrepo unreachable) yields safe defaults.
SKIP: {
    my $info = $sdl3->package_info;
    skip 'packages resolved (snapshot or store); delegation already serves paths' => 21 if $info;
    for my $pkg ( $sdl3->package_names ) {
        is $sdl3->libpath($pkg),      undef, "$pkg libpath is undef before resolution";
        is $sdl3->version($pkg),      undef, "$pkg version is undef before resolution";
        is $sdl3->kind($pkg),         undef, "$pkg kind is undef before resolution";
        is $sdl3->cflags($pkg),       '',    "$pkg cflags is empty before resolution";
        is $sdl3->package_info($pkg), undef, "$pkg package_info is undef before resolution";
    }
    is [ $sdl3->bin_dir ], [], 'bin_dir is empty before resolution';
}

# Resolved state (post-Build.PL snapshot, or a store that already has the family).
SKIP: {
    my $info = $sdl3->package_info;
    skip 'packages not installed; run `perl Build.PL` first' => 19 unless $info;
    for my $pkg ( $sdl3->package_names ) {
        my $alt = $sdl3->alt($pkg);
        ok $alt->libpath, "$pkg alt libpath resolved";
        ok $alt->version, "$pkg alt version resolved";
        is $alt->kind, 'library', "$pkg alt kind is library";
        like $alt->cflags, qr{-I}, "$pkg alt cflags has an include flag";
    }

    # A non-primary package returns a delegate whose pkg_name is the single name;
    # the primary resolves to $self, so its pkg_name is the full list.
    is $sdl3->alt('libsdl3_image')->pkg_name, 'libsdl3_image', 'alt(secondary) pkg_name is the single name';
    is $sdl3->alt('libsdl3_ttf')->pkg_name,   'libsdl3_ttf',   'alt(ttf) pkg_name is the single name';
    is $sdl3->alt('libsdl3_mixer')->pkg_name, 'libsdl3_mixer', 'alt(mixer) pkg_name is the single name';
}
#
done_testing;
