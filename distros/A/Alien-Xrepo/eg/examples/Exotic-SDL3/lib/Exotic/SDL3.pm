use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Alien::Xrepo::Runtime;
class Exotic::SDL3 v1.0.0 : isa(Alien::Xrepo::Runtime) {

    # SDL3 is bound as a family: core + the common extension libraries. Each is installed
    # separately (as a SHARED library; xrepo builds SDL3 static by default, and Affix/FFI::Platypus
    # need a real .dll/.so/.dylib) and exposed via the Alien::Build-style `alt()` accessor or a
    # package-name argument.
    #
    # recipes/ is a small local xmake-repo tree (the libsdl3_ttf override); registering it here
    # means the runtime description also carries everything the engine needs to reproduce the
    # build.
    method recipe {
        return {
            name     => 'Exotic-SDL3',
            packages => [
                { name => 'libsdl3',       kind => 'shared' },
                { name => 'libsdl3_image', kind => 'shared' },
                { name => 'libsdl3_ttf',   kind => 'shared' },
                { name => 'libsdl3_mixer', kind => 'shared' }
            ],
            local_repos => ['recipes']
        };
    }
    }
    #
    1;
