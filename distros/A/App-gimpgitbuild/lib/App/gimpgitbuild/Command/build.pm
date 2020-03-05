package App::gimpgitbuild::Command::build;
$App::gimpgitbuild::Command::build::VERSION = '0.10.2';
use strict;
use warnings;
use 5.014;

use App::gimpgitbuild -command;

use Path::Tiny qw/ path tempdir tempfile cwd /;

use App::gimpgitbuild::API::GitBuild ();
use Git::Sync::App                   ();

sub description
{
    return "build gimp from git";
}

sub abstract
{
    return shift->description();
}

sub opt_spec
{
    return ();


}

sub _do_system
{
    my ($args) = @_;

    my $cmd = $args->{cmd};
    print "Running [@$cmd]\n";
    if ( system(@$cmd) )
    {
        die "Running [@$cmd] failed!";
    }
}

sub _check
{
    return ( length( $ENV{SKIP_CHECK} ) ? "true" : "make check" );
}

sub _git_build
{
    my $args = shift;
    my $id   = $args->{id};

    my $KEY = "GIMPGITBUILD__SKIP_BUILDS_RE";
    if ( exists $ENV{$KEY} )
    {
        my $re = $ENV{$KEY};
        if ( $id =~ /$re/ )
        {
            return;
        }
    }
    $args->{branch} //= 'master';
    $args->{tag}    //= 'false';

    my $git_co = $args->{git_co};
    if ( !-e "$args->{git_co}" )
    {
        path( $args->{git_co} )->parent->mkpath;
        _do_system( { cmd => [qq#git clone "$args->{url}" "$git_co"#] } );
    }

    # See:
    # https://github.com/libfuse/libfuse/issues/212
    # Ubuntu/etc. places it under $prefix/lib/$arch by default.
    my $UBUNTU_MESON_LIBDIR_OVERRIDE = "-D libdir=lib";
    my $meson1 =
qq#mkdir -p "build" && cd build && meson --prefix="$args->{prefix}" $UBUNTU_MESON_LIBDIR_OVERRIDE .. && ninja -j4 && ninja -j4 test && ninja -j4 install#;
    my $autoconf1 =
qq#NOCONFIGURE=1 ./autogen.sh && ./configure --prefix="$args->{prefix}" && make -j4 && @{[_check()]} && make install#;
    _do_system(
        {
            cmd => [
qq#cd "$git_co" && git checkout "$args->{branch}" && ($args->{tag} || $^X -MGit::Sync::App -e "Git::Sync::App->new->run" -- sync origin "$args->{branch}") && #
                    . ( $args->{use_meson} ? $meson1 : $autoconf1 )
            ]
        }
    );
    return;
}

sub execute
{
    my ( $self, $opt, $args ) = @_;

    my $output_fn = $opt->{output};
    my $exe       = $opt->{exec} // [];

    my $fh  = \*STDIN;
    my $obj = App::gimpgitbuild::API::GitBuild->new;

    my $HOME = $obj->home_dir;
    my $env  = $obj->new_env;
    $ENV{PATH}            = $env->{PATH};
    $ENV{PKG_CONFIG_PATH} = $env->{PKG_CONFIG_PATH};
    $ENV{XDG_DATA_DIRS}   = $env->{XDG_DATA_DIRS};
    my $base_src_dir = $obj->base_git_clones_dir;

    my $GNOME_GIT = 'https://gitlab.gnome.org/GNOME';
    _git_build(
        {
            id        => "babl",
            git_co    => "$base_src_dir/babl/git/babl",
            url       => "$GNOME_GIT/babl",
            prefix    => $obj->babl_p,
            use_meson => 1,
        }
    );
    _git_build(
        {
            id        => "gegl",
            git_co    => "$base_src_dir/gegl/git/gegl",
            url       => "$GNOME_GIT/gegl",
            prefix    => $obj->gegl_p,
            use_meson => 1,
        }
    );
    _git_build(
        {
            id        => "libmypaint",
            git_co    => "$base_src_dir/libmypaint/git/libmypaint",
            url       => "https://github.com/mypaint/libmypaint.git",
            prefix    => $obj->mypaint_p,
            use_meson => 0,
            branch    => "v1.3.0",
            tag       => "true",
        }
    );
    _git_build(
        {
            id        => "mypaint-brushes",
            git_co    => "$base_src_dir/libmypaint/git/mypaint-brushes",
            url       => "https://github.com/Jehan/mypaint-brushes.git",
            prefix    => $obj->mypaint_p,
            use_meson => 0,
            branch    => "v1.3.x",
        }
    );

# autoconf_git_build "$base_src_dir/git/gimp" "$GNOME_GIT"/gimp "$HOME/apps/gimp-devel"
    _git_build(
        {
            id        => "gimp",
            git_co    => "$base_src_dir/git/gimp",
            url       => "$GNOME_GIT/gimp",
            prefix    => $obj->gimp_p,
            use_meson => 1,
        }
    );

    use Term::ANSIColor qw/ colored /;
    print colored( [ $ENV{HARNESS_SUMMARY_COLOR_SUCCESS} || 'bold green' ],
        "\n== Success ==\n\n" );
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 VERSION

version 0.10.2

=begin foo return (
        [ "output|o=s", "Output path" ],
        [ "title=s",    "Chart Title" ],
        [ 'exec|e=s@',  "Execute command on the output" ]
    );
=end foo

=head1 NAME

gimpgitbuild build - command line utility to automatically build GIMP and its dependencies from git.


=end foo

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
