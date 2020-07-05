package App::gimpgitbuild::API::GitBuild;
$App::gimpgitbuild::API::GitBuild::VERSION = '0.26.0';
use strict;
use warnings;
use 5.014;

use Moo;

has home_dir         => ( is => 'lazy' );
has install_base_dir => ( is => 'lazy' );

sub _build_home_dir
{
    return $ENV{HOME};
}

sub _build_install_base_dir
{
    my $self = shift;
    return $ENV{GIMPGITBUILD__BASE_INSTALL_DIR}
        // ( $self->home_dir . "/apps/graphics" );
}

sub mypaint_p
{
    my $self = shift;
    return $self->install_base_dir . "/libmypaint";
}

sub babl_p
{
    my $self = shift;
    return $self->install_base_dir . "/babl";
}

sub gimp_p
{
    my $self = shift;
    return $self->install_base_dir . "/gimp-devel";
}

sub gegl_p
{
    my $self = shift;
    return $self->install_base_dir . "/gegl";
}

sub base_git_clones_dir
{
    my $self = shift;

    return $ENV{GIMPGITBUILD__BASE_CLONES_DIR}
        // ( $self->home_dir . "/Download/unpack/graphics/gimp" );
}

sub new_env
{
    my $self            = shift;
    my $gegl_p          = $self->gegl_p;
    my $gimp_p          = $self->gimp_p;
    my $babl_p          = $self->babl_p;
    my $mypaint_p       = $self->mypaint_p;
    my $PKG_CONFIG_PATH = join(
        ":",
        (
            map {
                my $p = $_;
                map { "$p/$_/pkgconfig" } qw# share lib64 lib  #
            } ( $babl_p, $gegl_p, $mypaint_p )
        ),
        ( $ENV{PKG_CONFIG_PATH} // '' )
    );
    my $LD_LIBRARY_PATH = join(
        ":",
        (
            map {
                my $p = $_;
                map { "$p/$_" } qw# lib64 lib  #
            } ( $gimp_p, $babl_p, $gegl_p, $mypaint_p )
        ),
        ( $ENV{LD_LIBRARY_PATH} // '' )
    );
    my $xdg_prefix =
"$gegl_p/share:$mypaint_p/share:$mypaint_p/share/pkgconfig:$babl_p/share";
    my $XDG_DATA_DIRS = (
        exists( $ENV{XDG_DATA_DIRS} )
        ? "$xdg_prefix:$ENV{XDG_DATA_DIRS}"
        : $xdg_prefix
    );
    return +{
        LD_LIBRARY_PATH => $LD_LIBRARY_PATH,
        PATH            => "$gegl_p/bin:$ENV{PATH}",
        PKG_CONFIG_PATH => $PKG_CONFIG_PATH,
        XDG_DATA_DIRS   => $XDG_DATA_DIRS,
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::gimpgitbuild::API::GitBuild - common API

=head1 VERSION

version 0.26.0

=head1 METHODS

=head2 babl_p

The BABL install prefix.

=head2 gegl_p

The GEGL install prefix.

=head2 gimp_p

The GIMP install prefix.

=head2 mypaint_p

The libmypaint install prefix.

=head2 new_env

Returns a hash reference of new environment variables to override.

=head2 install_base_dir

Can be overrided by setting the C<GIMPGITBUILD__BASE_INSTALL_DIR> environment
variable.

=head2 base_git_clones_dir

The base filesystem directory path for the git repository clones.
Can be overrided by setting the C<GIMPGITBUILD__BASE_CLONES_DIR> environment
variable.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-gimpgitbuild>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-gimpgitbuild>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-gimpgitbuild>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-gimpgitbuild>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-gimpgitbuild>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::gimpgitbuild>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-gimpgitbuild at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-gimpgitbuild>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/App-gimpgitbuild>

  git clone git://github.com/shlomif/App-gimpgitbuild.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/App-gimpgitbuild/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Shlomi Fish.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
