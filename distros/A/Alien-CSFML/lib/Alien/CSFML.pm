package Alien::CSFML;
{ $Alien::CSFML::VERSION = 'v0.0.2'; }
use strict;
use warnings;
use File::ShareDir        qw[dist_dir];
use File::Spec::Functions qw[catdir canonpath];

sub new {
    my ( $pkg, %overrides ) = @_;
    return bless { 'C++' => $overrides{'C++'} }, $pkg;
}

sub include_dirs {
    my ($s) = @_;
    return (
        canonpath( catdir( dist_dir('Alien-CSFML'), 'src' ) ),
        canonpath( catdir( dist_dir('Alien-CSFML'), 'sfml', 'include' ) ),
        ( $s->{'C++'} ? () : canonpath( catdir( dist_dir('Alien-CSFML'), 'csfml', 'include' ) ) )
    );
}

sub library_path {
    my ($s) = @_;
    return ( canonpath( catdir( dist_dir('Alien-CSFML'), 'sfml', 'lib' ) ),
        ( $s->{'C++'} ? () : canonpath( catdir( dist_dir('Alien-CSFML'), 'csfml', 'lib' ) ) ) );
}
sub cflags   {''}
sub cxxflags {''}

sub ldflags {
    my ( $s, @args ) = @_;
    @args = qw[graphics window audio network system] if !scalar @args;
    CORE::state $pre;
    $pre //= {    # Windows dependencies
        graphics => [
            ( ( $s->{'C++'} ? '' : 'c' ) . 'sfml-window' ),
            ( ( $s->{'C++'} ? '' : 'c' ) . 'sfml-system' ),
            qw[opengl32 freetype]
        ],
        window => [ ( ( $s->{'C++'} ? '' : 'c' ) . 'sfml-system' ), qw[opengl32 winmm gdi32] ],
        audio  => [
            ( ( $s->{'C++'} ? '' : 'c' ) . 'sfml-system' ),
            qw[openal32 flac vorbisenc vorbisfile vorbis ogg]
        ],
        network => [ ( ( $s->{'C++'} ? '' : 'c' ) . 'sfml-system' ), qw[ws2_32] ],
        system  => [qw[winmm]]
        }
        if $^O eq 'MSWin32';
    join ' ', ' -L' . canonpath( catdir( dist_dir('Alien-CSFML'), 'sfml', 'lib' ) ), (
        $s->{'C++'} ? '' : ' -L' . canonpath( catdir( dist_dir('Alien-CSFML'), 'csfml', 'lib' ) ) ),
        (
        map { '-l' . $_ } (
            ( grep {/^audio$/} @args ) ?
                ( @{ $pre->{audio} }, 'sfml-audio', ( $s->{'C++'} ? () : 'csfml-audio' ) ) :
                ()
        ), (
            ( grep {/^graphics$/} @args ) ?
                ( @{ $pre->{graphics} }, 'sfml-graphics', ( $s->{'C++'} ? () : 'csfml-graphics' ) )
            :
                ()
        ), (
            ( grep {/^network$/} @args ) ?
                ( @{ $pre->{network} }, 'sfml-network', ( $s->{'C++'} ? () : 'csfml-network' ) ) :
                ()
        ), (
            ( grep {/^system$/} @args ) ?
                ( @{ $pre->{system} }, 'sfml-system', ( $s->{'C++'} ? () : 'csfml-system' ) ) :
                ()
        ), (
            ( grep {/^window$/} @args ) ?
                ( @{ $pre->{window} }, 'sfml-window', ( $s->{'C++'} ? () : 'csfml-window' ) ) :
                ()
        ),
        );
}
1;

=pod

=encoding utf-8

=head1 NAME

Alien::CSFML - Build and provide access to the official binding of SFML for the
C language

=head1 Description

This distribution builds and installs CSFML; the official binding of SFML for
the C language. Its API is as close as possible to the C++ API (but in C style,
of course), which makes it a perfect tool for building SFML bindings for other
languages that don't directly support C++ libraries.

=head1 Synopsis

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

=head1 Constructor

    my $AS = Alien::CSFML->new( );

Per-object configuration options are set in the constructor and include:

=over

=item C<C++>

Specifies that the source file is a C++ source file and sets appropriate
compile and linker flags.

=back

=head1 Methods

After creating a new L<Alien::CSFML|Alien::CSFML> object, use the following
methods to gather information:

=head2 C<include_dirs>

    my @include_dirs = $AS->include_dirs( );

Returns a list of the locations of the headers installed during the build
process and those required for compilation.

=head2 C<library_path>

    my $lib_path = $AS->library_path( );

Returns the location of the private libraries we made and installed during the
build process.

=head2 C<cflags>

    my $cflags = $AS->cflags( );

Returns additional C compiler flags to be used.

=head2 C<cxxflags>

    my $cxxflags = $AS->cxxflags( );

Returns additional flags to be used to when compiling C++.

=head2 C<ldflags>

    my $ldflags = $AS->ldflags( );

Returns additional linker flags to be used.

    my $ldflags = $AS->ldflags(qw[audio window system]);

By default, all modules are linked but you may request certain modules
individually with the following values:

=over

=item C<audio> - hardware-accelerated spatialised audio playback and recording

=item C<graphics> - hardware acceleration of 2D graphics including sprites, polygons and text rendering

=item C<network> - TCP and UDP network sockets, data encapsulation facilities, HTTP and FTP classes

=item C<system> - vector and Unicode string classes, portable threading and timer facilities

=item C<window> - window and input device management including support for joysticks, OpenGL context management

=back

Dependencies are also automatically returned for each module type.

=head1 Installation

The distribution is based on L<Module::Build::Tiny|Module::Build::Tiny>, so use
the following procedure:

  > perl Build.PL
  > ./Build
  > ./Build test
  > ./Build install

=head2 Dependencies

On Windows and macOS, all the required dependencies are provided alongside SFML
so you won't have to download/install anything else. Building will work out of
the box.

On Linux however, nothing is provided. SFML relies on you to install all of its
dependencies on your own. Here is a list of what you need to install before
building SFML:

=over

=item freetype

=item x11

=item xrandr

=item udev

=item opengl

=item flac

=item ogg

=item vorbis

=item vorbisenc

=item vorbisfile

=item openal

=item pthread

=back

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

=head1 See Also

L<Alien::SFML|Alien::SFML>

L<https://www.sfml-dev.org/learn.php>

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2022 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the terms of The Artistic License 2.0. See the F<LICENSE> file included with
this distribution or http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

=for stopwords
macOS FreeBSD
freetype xrandr udev opengl OpenGL
flac ogg vorbis vorbisenc vorbisfile
openal pthread
spatialised

=cut
