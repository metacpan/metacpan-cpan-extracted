[![Actions Status](https://github.com/sanko/alien-csfml/actions/workflows/linux.yaml/badge.svg)](https://github.com/sanko/alien-csfml/actions) [![Actions Status](https://github.com/sanko/alien-csfml/actions/workflows/windows.yaml/badge.svg)](https://github.com/sanko/alien-csfml/actions) [![Actions Status](https://github.com/sanko/alien-csfml/actions/workflows/osx.yaml/badge.svg)](https://github.com/sanko/alien-csfml/actions) [![Actions Status](https://github.com/sanko/alien-csfml/actions/workflows/freebsd.yaml/badge.svg)](https://github.com/sanko/alien-csfml/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Alien-CSFML.svg)](https://metacpan.org/release/Alien-CSFML)
# NAME

Alien::CSFML - Build and provide access to the official binding of SFML for the
C language

# Description

This distribution builds and installs CSFML; the official binding of SFML for
the C language. Its API is as close as possible to the C++ API (but in C style,
of course), which makes it a perfect tool for building SFML bindings for other
languages that don't directly support C++ libraries.

# Synopsis

    use Alien::CSFML;
    use ExtUtils::CBuilder;
    my $SF  = Alien::CSFML->new( 'C++' => 1 );
    my $CC  = ExtUtils::CBuilder->new( quiet => 0 );
    my $SRC = 'hello_world.cxx';
    open( my $FH, '>', $SRC ) || die '...';
    syswrite( $FH, <<'')      || die '...'; close $FH;
    #include <SFML/Graphics.hpp>
    int main() {
        sf::RenderWindow window(sf::VideoMode(200, 200), "SFML works!");
        sf::CircleShape shape(100.f);
        shape.setFillColor(sf::Color::Green);
        while (window.isOpen()) {
            sf::Event event;
            while (window.pollEvent(event)) {
                if (event.type == sf::Event::Closed)
                    window.close();
            }
            window.clear();
            window.draw(shape);
            window.display();
        }
        return 0;
    }

    my $OBJ = $CC->compile( 'C++' => 1, source => $SRC, include_dirs => [ $SF->include_dirs ] );
    my $EXE = $CC->link_executable(
        objects            => $OBJ,
        extra_linker_flags => ' -lstdc++ ' . $SF->ldflags(qw[graphics system window])
    );
    print system(
        (
            $^O eq 'MSWin32' ? '' :
                'LD_LIBRARY_PATH=' . join( ':', '.', $SF->library_path(1) ) . ' '
        ) .
            './' . $EXE
    ) ? 'Aww...' : 'Yay!';
    END { unlink grep defined, $SRC, $OBJ, $EXE; }

# Constructor

    my $AS = Alien::CSFML->new( );

Per-object configuration options are set in the constructor and include:

- `C++`

    Specifies that the source file is a C++ source file and sets appropriate
    compile and linker flags.

# Methods

After creating a new [Alien::CSFML](https://metacpan.org/pod/Alien%3A%3ACSFML) object, use the following
methods to gather information:

## `include_dirs`

    my @include_dirs = $AS->include_dirs( );

Returns a list of the locations of the headers installed during the build
process and those required for compilation.

## `library_path`

    my $lib_path = $AS->library_path( );

Returns the location of the private libraries we made and installed during the
build process.

## `cflags`

    my $cflags = $AS->cflags( );

Returns additional C compiler flags to be used.

## `cxxflags`

    my $cxxflags = $AS->cxxflags( );

Returns additional flags to be used to when compiling C++.

## `ldflags`

    my $ldflags = $AS->ldflags( );

Returns additional linker flags to be used.

    my $ldflags = $AS->ldflags(qw[audio window system]);

By default, all modules are linked but you may request certain modules
individually with the following values:

- `audio` - hardware-accelerated spatialised audio playback and recording
- `graphics` - hardware acceleration of 2D graphics including sprites, polygons and text rendering
- `network` - TCP and UDP network sockets, data encapsulation facilities, HTTP and FTP classes
- `system` - vector and Unicode string classes, portable threading and timer facilities
- `window` - window and input device management including support for joysticks, OpenGL context management

Dependencies are also automatically returned for each module type.

# Installation

The distribution is based on [Module::Build::Tiny](https://metacpan.org/pod/Module%3A%3ABuild%3A%3ATiny), so use
the following procedure:

    > perl Build.PL
    > ./Build
    > ./Build test
    > ./Build install

## Dependencies

On Windows and macOS, all the required dependencies are provided alongside SFML
so you won't have to download/install anything else. Building will work out of
the box.

On Linux however, nothing is provided. SFML relies on you to install all of its
dependencies on your own. Here is a list of what you need to install before
building SFML:

- freetype
- x11
- xrandr
- udev
- opengl
- flac
- ogg
- vorbis
- vorbisenc
- vorbisfile
- openal
- pthread

The exact name of the packages may vary from distribution to distribution. Once
those packages are installed, don't forget to install their development headers
as well.

On a Debian based system, you'd try something like:

     sudo apt-get update
     sudo apt-get install libxrandr-dev libxcursor-dev libudev-dev libopenal-dev libflac-dev libvorbis-dev libgl1-mesa-dev libegl1-mesa-dev libdrm-dev libgbm-dev

On FreeBSD, I tossed this into my Github Action and it works out alright:

    env ASSUME_ALWAYS_YES=YES pkg install -y git cmake-core ninja xorgproto libX11 libXrandr
    env ASSUME_ALWAYS_YES=YES pkg install -y flac libogg libvorbis freetype2 openal-soft libglvnd
    env ASSUME_ALWAYS_YES=YES pkg install -y libXcursor

# See Also

[Alien::SFML](https://metacpan.org/pod/Alien%3A%3ASFML)

[https://www.sfml-dev.org/learn.php](https://www.sfml-dev.org/learn.php)

# Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

# License and Legal

Copyright (C) 2022 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of The Artistic License 2.0. See the `LICENSE` file included with
this distribution or http://www.perlfoundation.org/artistic\_license\_2\_0.  For
clarification, see http://www.perlfoundation.org/artistic\_2\_0\_notes.
