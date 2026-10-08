use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Alien::Xrepo::Runtime;
use Config ();
#
class Alien::SDL3 v3.4.18 : isa(Alien::Xrepo::Runtime) {

    # SDL3 is bound as a family: core + the common extension libraries. Each is installed
    # separately (as a SHARED library; xrepo builds SDL3 static by default, and Affix/FFI::Platypus
    # need a real .dll/.so/.dylib) and exposed via the Alien::Build-style `alt()` accessor or a
    # package-name argument.
    #
    # recipes/ is a small local xmake-repo tree (local overrides of libsdl3, libsdl3_image,
    # libsdl3_ttf and libsdl3_mixer); registering it here means the runtime description also
    # carries everything the engine needs to reproduce the build.
    method recipe {
        return {
            name     => 'Alien-SDL3',
            packages => [
                { name => 'libsdl3',       kind => 'shared' },
                { name => 'libsdl3_image', kind => 'shared' },
                { name => 'libsdl3_ttf',   kind => 'shared' },
                { name => 'libsdl3_mixer', kind => 'shared' }
            ],

            # Ask for system packages explicitly: package-manager copies of SDL3 and friends (apt, brew,
            # vcpkg, ...) are preferred over building the pinned sources, and anything the system does not
            # provide still falls back to a source build. Note this is deliberately not a hard requirement
            # -- recipes/packages/l/libsdl3/xmake.lua gates the system path on SDL3 >= 3.4.18, so an older
            # copy (eg Ubuntu's 3.4.2 or vcpkg's 3.4.16) is skipped rather than mixed with the 3.4.18
            # headers the extension libraries build against, and on Windows the extension recipes re-check
            # that same verdict so the family never splits across sources.
            defaults    => { system => 1 },
            local_repos => ['recipes']
        };
    }

    # An Alien hands the running Perl a library it must `dlopen`, so the xmake target
    # architecture has to follow $Config{archname} and not the host machine. The gap is
    # real on windows-11-arm, where an x64 Strawberry Perl runs under emulation: left to
    # itself xmake picks the ARM64 host arch, and x64 perl.exe cannot load an arm64 DLL.
    # Setting -a here keeps target arch, the prebuilt DLL flavour, and the Perl in step.
    # Returns () when archname is unrecognised, so xmake keeps its usual host default.
    method install_opts {
        my $arch = $Config::Config{archname} // '';
        return ( arch => 'arm64' )  if $arch =~ /(?:^|-)(?:arm64|aarch64)(?:-|$)/i;
        return ( arch => 'x86_64' ) if $arch =~ /\bx86_64\b|\bamd64\b|(?:^|-)x64(?:-|$)/i;
        return ( arch => 'x86' )    if $arch =~ /\bi[3-6]86\b|(?:^|-)x86(?:-|$)/i;
        return ();
    }
};
#
1;
