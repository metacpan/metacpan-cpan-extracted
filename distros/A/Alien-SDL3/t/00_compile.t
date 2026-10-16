use v5.40;
use blib;
use Test2::V0;
use Alien::SDL3;
use feature 'try';
#
try { require Affix } catch ($e) {
    skip_all 'Needs Affix'
}
my $sdl3  = Alien::SDL3->new;
my $built = $sdl3->has_snapshot;    # a snapshot was written: the core package must then resolve
isa_ok $sdl3, ['Alien::SDL3'],           'isa Alien::SDL3';
isa_ok $sdl3, ['Alien::Xrepo::Runtime'], 'isa Alien::Xrepo::Runtime';

# Surface whatever the build recorded for packages it could not produce, so a smoker's
# log shows the failure instead of it hiding inside the snapshot.
my $errors = $sdl3->snapshot_errors;
diag "$_ failed to install: $errors->{$_}" for sort keys %$errors;

#~ is [ $sdl3->package_names ], [ 'libsdl3', 'libsdl3_image', 'libsdl3_ttf', 'libsdl3_mixer' ], 'package_names lists the SDL3 family';
#
# Only the core library is required to be present. The companion libraries (image, ttf,
# mixer) are best-effort: a build where one failed still provides the SDL3 core API, so
# report the gap and skip its checks rather than failing the suite. The core, once a
# snapshot has been written, must resolve -- a built dist that cannot find it is broken.
my ($core) = $sdl3->package_names;
#
for my $name ( $sdl3->package_names ) {
    my $alt  = $sdl3->alt($name);
    my $info = $alt->package_info;
    unless ($info) {
        diag "$name is missing";
        if ( $name eq $core ) {
            ok !$built, "$name (core) resolved" if $built;
        }
        else {
            diag "$name is optional; skipping its checks";
        }
        next;
    }
    diag sprintf '%-16s v%-9s %-8s',  $name, $info->version, $info->kind;
    diag sprintf '  installdir : %s', $info->installdir // '(none)';
    diag sprintf '  libpath    : %s', $info->libpath    // '(none)';
    diag sprintf '  dynamic    : %s', join( '; ', @{ $info->libfiles    // [] } ) || '(none)';
    diag sprintf '  includes   : %s', join( '; ', @{ $info->includedirs // [] } ) || '(none)';
    diag sprintf '  cflags     : %s', $alt->cflags;
    diag sprintf '  libs       : %s', $alt->libs;
}
#
done_testing;
