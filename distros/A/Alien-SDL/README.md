# Alien::SDL [![Build Status](https://travis-ci.org/PerlGameDev/Alien-SDL.svg?branch=master)](https://travis-ci.org/PerlGameDev/Alien-SDL)

NAME
    Alien::SDL - building, finding and using SDL binaries

VERSION
    Version 1.444

SYNOPSIS
    Alien::SDL tries (in given order) during its installation:

    * When given `--with-sdl-config' option use specified sdl-config script
    to locate SDL libs.
         perl Build.PL --with-sdl-config=/opt/sdl/bin/sdl-config

        or using default script name 'sdl-config' by running:

         perl Build.PL --with-sdl-config

        IMPORTANT NOTE: Using --with-sdl-config avoids considering any other
        build methods; no prompt with other available build options.

    * Locate an already installed SDL via 'sdl-config' script.
    * Check for SDL libs in directory specified by SDL_INST_DIR variable. In
    this case the module performs SDL library detection via
    '$SDL_INST_DIR/bin/sdl-config' script.
         SDL_INST_DIR=/opt/sdl perl ./Build.PL

    * Download prebuilt SDL binaries (if available for your platform).
    * Build SDL binaries from source codes (if possible on your system).

    Later you can use Alien::SDL in your module that needs to link agains
    SDL and/or related libraries like this:

        # Sample Makefile.pl
        use ExtUtils::MakeMaker;
        use Alien::SDL;

        WriteMakefile(
          NAME         => 'Any::SDL::Module',
          VERSION_FROM => 'lib/Any/SDL/Module.pm',
          LIBS         => Alien::SDL->config('libs', [-lAdd_Lib]),
          INC          => Alien::SDL->config('cflags'),
          # + additional params
        );

DESCRIPTION
    Please see Alien for the manifesto of the Alien namespace.

    In short `Alien::SDL' can be used to detect and get configuration
    settings from an installed SDL and related libraries. Based on your
    platform it offers the possibility to download and install prebuilt
    binaries or to build SDL & co. from source codes.

    The important facts:

    * The module does not modify in any way the already existing SDL
    installation on your system.
    * If you reinstall SDL libs on your system you do not need to reinstall
    Alien::SDL (providing that you use the same directory for the new
    installation).
    * The prebuild binaries and/or binaries built from sources are always
    installed into perl module's 'share' directory.
    * If you use prebuild binaries and/or binaries built from sources it
    happens that some of the dynamic libraries (*.so, *.dll) will not
    automaticly loadable as they will be stored somewhere under perl
    module's 'share' directory. To handle this scenario Alien::SDL offers
    some special functionality (see below).

METHODS
  config()
    This function is the main public interface to this module. Basic
    functionality works in a very similar maner to 'sdl-config' script:

        Alien::SDL->config('prefix');   # gives the same string as 'sdl-config --prefix'
        Alien::SDL->config('version');  # gives the same string as 'sdl-config --version'
        Alien::SDL->config('libs');     # gives the same string as 'sdl-config --libs'
        Alien::SDL->config('cflags');   # gives the same string as 'sdl-config --cflags'

    On top of that this function supports special parameters:

        Alien::SDL->config('ld_shared_libs');

    Returns a list of full paths to shared libraries (*.so, *.dll) that will
    be required for running the resulting binaries you have linked with SDL
    libs.

        Alien::SDL->config('ld_paths');

    Returns a list of full paths to directories with shared libraries (*.so,
    *.dll) that will be required for running the resulting binaries you have
    linked with SDL libs.

        Alien::SDL->config('ld_shlib_map');

    Returns a reference to hash of value pairs '<libnick>' =>
    '<full_path_to_shlib'>, where '<libnick>' is shortname for SDL related
    library like: SDL, SDL_gfx, SDL_net, SDL_sound ... + some non-SDL
    shortnames e.g. smpeg, jpeg, png.

    NOTE: config('ld_<something>') return an empty list/hash if you have
    decided to use SDL libraries already installed on your system. This
    concerns 'sdl-config' detection and detection via
    '$SDL_INST_DIR/bin/sdl-config'.

  check_header()
    This function checks the availability of given header(s) when using
    compiler options provided by "Alien::SDL->config('cflags')".

        Alien::SDL->check_header('SDL.h');
        Alien::SDL->check_header('SDL.h', 'SDL_net.h');

    Returns 1 if all given headers are available, 0 otherwise.

  get_header_version()
    Tries to find a header file specified as a param in SDL prefix direcotry
    and based on "#define" macros inside this header file tries to get a
    version triplet.

        Alien::SDL->get_header_version('SDL_mixer.h');
        Alien::SDL->get_header_version('SDL_version.h');
        Alien::SDL->get_header_version('SDL_gfxPrimitives.h');
        Alien::SDL->get_header_version('SDL_image.h');
        Alien::SDL->get_header_version('SDL_mixer.h');
        Alien::SDL->get_header_version('SDL_net.h');
        Alien::SDL->get_header_version('SDL_ttf.h');
        Alien::SDL->get_header_version('smpeg.h');

    Returns string like '1.2.3' or undef if not able to find and parse
    version info.

BUGS
    Please post issues and bugs at
    http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-SDL

AUTHOR
        Kartik Thakore
        CPAN ID: KTHAKORE
        Thakore.Kartik@gmail.com
        http://yapgh.blogspot.com

ACKNOWLEDGEMENTS
        kmx - complete redesign between versions 0.7.x and 0.8.x

COPYRIGHT
    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

    The full text of the license can be found in the LICENSE file included
    with this module.

