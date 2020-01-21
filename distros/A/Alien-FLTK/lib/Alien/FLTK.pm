package Alien::FLTK;
{ $Alien::FLTK::VERSION = 'v1.3.5'; }
use strict;
use warnings;
use File::ShareDir qw[dist_dir];
use File::Spec::Functions qw[catdir canonpath];
use JSON::Tiny qw[decode_json];
use File::Slurp qw[read_file];
use lib '../../blib/lib', '../blib/lib', 'blib/lib', 'lib';

sub new {
    my ( $class, $overrides ) = @_;    # XXX - overrides are unsupported
    return
        bless decode_json(
        read_file( canonpath( catdir( dist_dir('Alien-FLTK'), 'config.json' ) ) ) ), shift;
}

sub include_dirs {
    my ($self) = @_;
    return canonpath( catdir( dist_dir('Alien-FLTK'), 'include' ) );
}

sub library_path {
    my ($self) = @_;
    return canonpath( catdir( dist_dir('Alien-FLTK'), 'lib' ) );
}
sub cflags   { +shift->{cflags} }
sub cxxflags { +shift->{cxxflags} }

sub ldflags {
    my ( $self, @args ) = @_;
    return +shift->{ join '_', 'ldflags', sort @args };
}
1;

=pod

=head1 NAME

Alien::FLTK - Build and use the stable 1.3.x branch of the Fast Light Toolkit

=head1 Description

This distribution builds and installs libraries for the (stable) C<1.3.x>
branch of the FLTK GUI toolkit.

=head1 Synopsis

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

=head1 Constructor

There are no per-object configuration options as of this version, but there
may be in the future, so any new code using L<Alien::FLTK|Alien::FLTK> should
create objects with the C<new> constructor.

    my $AF = Alien::FLTK->new( );

=head1 Methods

After creating a new L<Alien::FLTK|Alien::FLTK> object, use the following
methods to gather information:

=head2 C<include_dirs>

    my @include_dirs = $AF->include_dirs( );

Returns a list of the locations of the headers installed during the build
process and those required for compilation.

=head2 C<library_path>

    my $lib_path = $AF->library_path( );

Returns the location of the private libraries we made and installed
during the build process.

=head2 C<cflags>

    my $cflags = $AF->cflags( );

Returns additional C compiler flags to be used.

=head2 C<cxxflags>

    my $cxxflags = $AF->cxxflags( );

Returns additional flags to be used to when compiling C++ using FLTK.

=head2 C<ldflags>

    my $ldflags = $AF->ldflags( qw[gl images] );

Returns additional linker flags to be used. This method can automatically add
appropriate flags based on how you plan on linking to fltk. Acceptable
arguments are:

=over

=item C<gl>

Include flags to use GL.

I<This is an experimental option. Depending on your system, this may also
include OpenGL or MesaGL.>

=item C<images>

Include flags to use extra image formats (PNG, JPEG).

=back

=head1 Notes

=head2 Requirements

Prerequisites differ by system...

=over

=item Win32

The fltk libs and L<Alien::FLTK|Alien::FLTK> both build right out of the box
with MinGW. Further testing is needed for other setups.

=item X11/*nix

X11-based systems require several development packages. On Debian, these may
be installed with:

    > sudo apt-get install libx11-dev
    > sudo apt-get install libxi-dev

Additionally, the optional XCurser lib may be installed with:

    > sudo apt-get install libxcursor-dev

=item Darwin/OSX

Uh, yeah, I have no idea.

=back

=head2 Installation

The distribution is based on L<Module::Build|Module::Build>, so use the
following procedure:

  > perl Build.PL
  > ./Build
  > ./Build test
  > ./Build install

=head2 Support Links

=over

=item * Issue Tracker

http://github.com/sanko/alien-fltk/issues

Please only report L<Alien::FLTK|Alien::FLTK> related bugs to this tracker.
For L<FLTK|FLTK> issues, use http://github.com/sanko/fltk-perl/issues/

=item * Commit Log

http://github.com/sanko/alien-fltk/commits/master

=item * Homepage:

http://sanko.github.com/fltk-perl/ is the homepage of the L<FLTK|FLTK>
project.

=item * License:

http://www.perlfoundation.org/artistic_license_2_0

See the L<License and Legal|/"License and Legal"> section of this document.

=item * Mailing List

Once I find someone to host a list for the L<FLTK|FLTK> project, I'll use it
for L<Alien::FLTK|Alien::FLTK> too.

=item * Repository

http://github.com/sanko/alien-fltk/ and you are invited to fork it.

=back

=head2 Examples

Please see the L<Synopsis|Alien::FLTK/"Synopsis"> and the files in the
C</examples/>.

=head2 Bugs

Numerous, I'm sure.

=head2 To Do

Please see L<Alien::FLTK::Todo|Alien::FLTK::Todo>

=head1 See Also

L<FLTK|FLTK>, L<Alien::FLTK2|Alien::FLTK2>

=head1 Acknowledgments

=over

=item The FLTK Team - http://www.fltk.org/

=back

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2009-2020 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the terms of The Artistic License 2.0. See the F<LICENSE> file included with
this distribution or http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all POD documentation is covered by the
Creative Commons Attribution-Share Alike 3.0 License. See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

L<Alien::FLTK|Alien::FLTK> is based in part on the work of the FLTK project.
See http://www.fltk.org/.

=cut
