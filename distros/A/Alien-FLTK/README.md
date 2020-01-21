[![Build Status](https://travis-ci.org/sanko/alien-fltk.svg?branch=master)](https://travis-ci.org/sanko/alien-fltk) [![MetaCPAN Release](https://badge.fury.io/pl/Alien-FLTK.svg)](https://metacpan.org/release/Alien-FLTK)
# NAME

Alien::FLTK - Build and use the stable 1.3.x branch of the Fast Light Toolkit

# Description

This distribution builds and installs libraries for the (stable) `1.3.x`
branch of the FLTK GUI toolkit.

# Synopsis

    use Alien::FLTK;
    use ExtUtils::CBuilder;
    my $AF  = Alien::FLTK->new();
    my $CC  = ExtUtils::CBuilder->new();
    my $SRC = 'hello_world.cxx';
    open(my $FH, '>', $SRC) || die '...';
    syswrite($FH, <<'') || die '...'; close $FH;
      #include <FL/Fl.H>
      #include <FL/Fl_Window.H>
      #include <FL/Fl_Box.H>
      int main(int argc, char **argv) {
        Fl_Window *window = new Fl_Window(300,180);
        Fl_Box *box = new Fl_Box(FL_UP_BOX, 20, 40, 260, 100, "Hello, World!");
        box->labelfont(FL_BOLD + FL_ITALIC);
        box->labelsize(36);
        box->labeltype(FL_SHADOW_LABEL);
        window->end();
        window->show(argc, argv);
        return Fl::run();
    }

    my $OBJ = $CC->compile('C++'                => 1,
                           source               => $SRC,
                           include_dirs         => [$AF->include_dirs()],
                           extra_compiler_flags => $AF->cxxflags()
    );
    my $EXE =
        $CC->link_executable(
         objects            => $OBJ,
         extra_linker_flags => '-L' . $AF->library_path . ' ' . $AF->ldflags()
        );
    print system('./' . $EXE) ? 'Aww...' : 'Yay!';
    END { unlink grep defined, $SRC, $OBJ, $EXE; }

# Constructor

There are no per-object configuration options as of this version, but there
may be in the future, so any new code using [Alien::FLTK](https://metacpan.org/pod/Alien%3A%3AFLTK) should
create objects with the `new` constructor.

    my $AF = Alien::FLTK->new( );

# Methods

After creating a new [Alien::FLTK](https://metacpan.org/pod/Alien%3A%3AFLTK) object, use the following
methods to gather information:

## `include_dirs`

    my @include_dirs = $AF->include_dirs( );

Returns a list of the locations of the headers installed during the build
process and those required for compilation.

## `library_path`

    my $lib_path = $AF->library_path( );

Returns the location of the private libraries we made and installed
during the build process.

## `cflags`

    my $cflags = $AF->cflags( );

Returns additional C compiler flags to be used.

## `cxxflags`

    my $cxxflags = $AF->cxxflags( );

Returns additional flags to be used to when compiling C++ using FLTK.

## `ldflags`

    my $ldflags = $AF->ldflags( qw[gl images] );

Returns additional linker flags to be used. This method can automatically add
appropriate flags based on how you plan on linking to fltk. Acceptable
arguments are:

- `gl`

    Include flags to use GL.

    _This is an experimental option. Depending on your system, this may also
    include OpenGL or MesaGL._

- `images`

    Include flags to use extra image formats (PNG, JPEG).

# Notes

## Requirements

Prerequisites differ by system...

- Win32

    The fltk libs and [Alien::FLTK](https://metacpan.org/pod/Alien%3A%3AFLTK) both build right out of the box
    with MinGW. Further testing is needed for other setups.

- X11/\*nix

    X11-based systems require several development packages. On Debian, these may
    be installed with:

        > sudo apt-get install libx11-dev
        > sudo apt-get install libxi-dev

    Additionally, the optional XCurser lib may be installed with:

        > sudo apt-get install libxcursor-dev

- Darwin/OSX

    Uh, yeah, I have no idea.

## Installation

The distribution is based on [Module::Build](https://metacpan.org/pod/Module%3A%3ABuild), so use the
following procedure:

    > perl Build.PL
    > ./Build
    > ./Build test
    > ./Build install

## Support Links

- Issue Tracker

    http://github.com/sanko/alien-fltk/issues

    Please only report [Alien::FLTK](https://metacpan.org/pod/Alien%3A%3AFLTK) related bugs to this tracker.
    For [FLTK](https://metacpan.org/pod/FLTK) issues, use http://github.com/sanko/fltk-perl/issues/

- Commit Log

    http://github.com/sanko/alien-fltk/commits/master

- Homepage:

    http://sanko.github.com/fltk-perl/ is the homepage of the [FLTK](https://metacpan.org/pod/FLTK)
    project.

- License:

    http://www.perlfoundation.org/artistic\_license\_2\_0

    See the [License and Legal](#license-and-legal) section of this document.

- Mailing List

    Once I find someone to host a list for the [FLTK](https://metacpan.org/pod/FLTK) project, I'll use it
    for [Alien::FLTK](https://metacpan.org/pod/Alien%3A%3AFLTK) too.

- Repository

    http://github.com/sanko/alien-fltk/ and you are invited to fork it.

## Examples

Please see the [Synopsis](https://metacpan.org/pod/Alien%3A%3AFLTK#Synopsis) and the files in the
`/examples/`.

## Bugs

Numerous, I'm sure.

## To Do

Please see [Alien::FLTK::Todo](https://metacpan.org/pod/Alien%3A%3AFLTK%3A%3ATodo)

# See Also

[FLTK](https://metacpan.org/pod/FLTK), [Alien::FLTK2](https://metacpan.org/pod/Alien%3A%3AFLTK2)

# Acknowledgments

- The FLTK Team - http://www.fltk.org/

# Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

# License and Legal

Copyright (C) 2009-2020 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of The Artistic License 2.0. See the `LICENSE` file included with
this distribution or http://www.perlfoundation.org/artistic\_license\_2\_0.  For
clarification, see http://www.perlfoundation.org/artistic\_2\_0\_notes.

When separated from the distribution, all POD documentation is covered by the
Creative Commons Attribution-Share Alike 3.0 License. See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

[Alien::FLTK](https://metacpan.org/pod/Alien%3A%3AFLTK) is based in part on the work of the FLTK project.
See http://www.fltk.org/.
