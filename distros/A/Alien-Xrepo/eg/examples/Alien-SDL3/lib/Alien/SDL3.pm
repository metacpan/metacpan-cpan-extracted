use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Alien::Xrepo::Runtime;

class Alien::SDL3 : isa(Alien::Xrepo::Runtime) {

    # Bind to the SDL3 family: core + the common extension libraries. Each is
    # installed separately and exposed via the Alien::Build-style `alt()` accessor
    # (e.g. `Alien::SDL3->alt('libsdl3_ttf')->cflags`) or a package-name argument.
    method pkg_name {
        return [ { name => 'libsdl3' }, { name => 'libsdl3_image' }, { name => 'libsdl3_ttf' }, { name => 'libsdl3_mixer' } ];
    }
}
#
1;
