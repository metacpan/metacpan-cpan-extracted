use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Alien::Xrepo::Runtime;
use Config ();
#
class Alien::SDL3 v3.4.20 : isa(Alien::Xrepo::Runtime) {

    # SDL3 is bound as a family: core + the common extension libraries. Each is installed
    # separately (as a SHARED library; xrepo builds SDL3 static by default, and Affix/FFI::Platypus
    # need a real .dll/.so/.dylib) and exposed via the Alien::Build-style `alt()` accessor or a
    # package-name argument.
    #
    # recipes/ is a small local xmake-repo tree (local overrides of libsdl3, libsdl3_image,
    # libsdl3_ttf and libsdl3_mixer); registering it here means the runtime description also
    # carries everything the engine needs to reproduce the build.
    method recipe {

        # install_opts() is only the runtime's dynamic-resolution ambient; the build engine reads the
        # recipe's `defaults`. Folding install_opts() in here is what actually hands -a (and the Windows
        # toolchain below) to `perl Build`, keeping the built profile and dynamic resolution in step.
        my %defaults = ( system => 1, $self->install_opts );

        # ALIEN_SDL3_XMAKE_DEBUG=1 forwards -v/-D to `xrepo install` (Alien::Xrepo's
        # verbose/diagnosis, which needs v1.0.9+) so a package that fails to build prints
        # its whole install.txt instead of only the tail. That is what turns an opaque
        # `=> install libsdl3 .. failed` into the real error. Off by default: the
        # diagnostic detail is large and is only wanted while debugging a build.
        if ( $ENV{ALIEN_SDL3_XMAKE_DEBUG} ) {
            $defaults{verbose}   = 1;
            $defaults{diagnosis} = 1;
        }
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
            defaults    => \%defaults,
            local_repos => ['recipes']
        };
    }

    # An Alien hands the running Perl a library it must `dlopen`, so the xmake target
    # architecture has to follow $Config{archname} and not the host machine. The gap is
    # real on windows-11-arm, where an x64 Strawberry Perl runs under emulation: left to
    # itself xmake picks the ARM64 host arch, and x64 perl.exe cannot load an arm64 DLL.
    # Setting -a here keeps target arch, the prebuilt DLL flavour, and the Perl in step.
    # Returns () when archname is unrecognised, so xmake keeps its usual host default.
    #
    # Windows also needs its toolchain pinned. xmake's `windows` platform lists
    # msvc/clang/... in set_toolchains() but never gcc, so on a Strawberry Perl host --
    # gcc, nothing named `cl` on PATH -- xmake aborts the throwaway project with
    # "toolchain not found!" before a single package is even fetched (CPAN smoker
    # reports on MSWin32-x64-multi-thread). Pinning the toolchain to the compiler Perl
    # itself was built with keeps the prebuilt DLL flavour, the import library on_test
    # links against, and the library FFI dlopens all in agreement. An MSVC-built Perl
    # (cc=cl) is left untouched: the platform default already finds msvc.
    #
    # The platform itself needs pinning too, for the same reason the arch does: -p is
    # what the recipes branch on, and without it xmake invents one from the shell.
    # A package's target plat is `config.get("plat") or os.subhost()`
    # (core/package/package.lua targetplat()), so a bare `xmake require` inherits
    # "msys" when the caller runs under an MSYS shell -- git-bash, which is how the
    # Windows CI legs drive the build and what Strawberry users routinely use. msys is
    # a windows platform (platforms/msys/xmake.lua: set_os("windows")), but it is not
    # the *name* "windows", so every is_plat("windows") in the recipes reads false:
    # the family skips the official prebuilt archives, pulls egl/opengl headers, cmake
    # and freetype in, and compiles SDL3 from source -- slow, dependent on the runner
    # image, and on some images it dies outright with
    # `package(libsdl3): links not found!`. Pinning windows keeps the target plat on
    # the platform the Alien is actually installing for; the toolchain pin above is
    # what makes that combination work with a gcc-built Perl.
    method install_opts {
        my %opts;
        my $arch = $Config::Config{archname} // '';
        if    ( $arch =~ /(?:^|-)(?:arm64|aarch64)(?:-|$)/i )        { $opts{arch} = 'arm64' }
        elsif ( $arch =~ /\bx86_64\b|\bamd64\b|(?:^|-)x64(?:-|$)/i ) { $opts{arch} = 'x86_64' }
        elsif ( $arch =~ /\bi86pc\b/i ) {

            # Solaris calls the machine "i86pc" for both word sizes, so a 64-bit
            # Perl's archname ("i86pc-solaris-64") matches neither branch above
            # nor the i[3-6]86 one below. Left unrecognised, xmake keeps its host
            # default -- which it also reads as "i386" -- and its gcc toolchain
            # then appends -m32 to everything it compiles: the wrong word size
            # for the -m64 Perl that has to dlopen the result. It first bites
            # while libsdl3_ttf builds its freetype dependency, whose cmake build
            # still comes out 64-bit while its on_test link check is -m32:
            #   ld: ... libfreetype.a(ftinit.c.o): wrong ELF class: ELFCLASS64
            # Trust the Perl this Alien feeds over the machine string.
            my $is64 = ( $Config::Config{ptrsize} // 0 ) == 8 || $arch =~ /-64(?:-|$)/;
            $opts{arch} = $is64 ? 'x86_64' : 'x86';
        }
        elsif ( $arch =~ /\bi[3-6]86\b|(?:^|-)x86(?:-|$)/i ) { $opts{arch} = 'x86' }
        if    ( $^O eq 'MSWin32' ) {
            my $cc       = $Config::Config{cc} // '';
            my $gcc_like = ( $Config::Config{gccversion} // '' ) || $cc =~ /\b(?:gcc|clang|g\+\+)\b/i;
            $opts{toolchain} = 'gcc' if $gcc_like;
            $opts{plat}      = 'windows';
        }
        return %opts;
    }
};
#
1;
