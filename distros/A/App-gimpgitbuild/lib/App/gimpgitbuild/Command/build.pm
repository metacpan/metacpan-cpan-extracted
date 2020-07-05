package App::gimpgitbuild::Command::build;
$App::gimpgitbuild::Command::build::VERSION = '0.26.0';
use strict;
use warnings;
use autodie;
use 5.014;

use App::gimpgitbuild -command;

use File::Which qw/ which /;

use App::gimpgitbuild::API::GitBuild ();
use App::gimpgitbuild::API::Worker   ();
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
    return ( [ "mode=s", "Mode (e.g: \"clean\")" ],
        [ "process-exe=s", qq#Process executor (= "sh" or "perl")#, ] );


}

sub _which_xvfb_run
{
    my $path = which('xvfb-run');
    if ( not defined($path) )
    {
        die
"Cannot find xvfb-run ! It is required for tests to succeed: see https://gitlab.gnome.org/GNOME/gimp/-/issues/2884";
    }
    return;
}

sub _ascertain_lack_of_gtk_warnings
{
    my $path = which('gvim');
    if ( defined($path) )
    {
        my $stderr = `"$path" -u NONE -U NONE -f /dev/null +q 2>&1`;
        if ( $stderr =~ /\S/ )
        {
            die
"There may be gtk warnings (e.g: in KDE Plasma 5 on Fedora 32 ). Please fix them.";
        }
    }
    return;
}

sub execute
{
    my ( $self, $opt, $args ) = @_;

    my $mode = ( $opt->{mode} || 'build' );
    if ( not( ( $mode eq 'clean' ) or ( $mode eq 'build' ) ) )
    {
        die "Unsupported mode '$mode'!";
    }

    my $_process_executor = ( $opt->{process_exe} || 'perl' );
    if (
        not(   ( $_process_executor eq 'sh' )
            or ( $_process_executor eq 'perl' ) )
        )
    {
        die "Unsupported process-exe '$_process_executor'!";
    }

    my $worker = App::gimpgitbuild::API::Worker->new(
        { _mode => $mode, _process_executor => $_process_executor, } );

    my $env = App::gimpgitbuild::API::GitBuild->new()->new_env();
    $ENV{PATH}            = $env->{PATH};
    $ENV{PKG_CONFIG_PATH} = $env->{PKG_CONFIG_PATH};
    $ENV{XDG_DATA_DIRS}   = $env->{XDG_DATA_DIRS};
    _which_xvfb_run();
    _ascertain_lack_of_gtk_warnings();

    $worker->_run_the_mode_on_all_repositories();

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

version 0.26.0

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
