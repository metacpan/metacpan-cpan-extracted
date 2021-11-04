package App::gimpgitbuild::Command::cleanbuild;
$App::gimpgitbuild::Command::cleanbuild::VERSION = '0.30.2';
use strict;
use warnings;
use autodie;
use 5.014;

use App::gimpgitbuild -command;

use App::gimpgitbuild::API::Worker ();

sub description
{
    return "clean the GIMP build checkouts";
}

sub abstract
{
    return shift->description();
}

sub opt_spec
{
    return ();


}

sub execute
{
    my ( $self, $opt, $args ) = @_;

    my $worker = App::gimpgitbuild::API::Worker->new(
        { _mode => 'clean', _process_executor => 'perl', } );

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

version 0.30.2

=begin foo return (
        [ "output|o=s", "Output path" ],
        [ "title=s",    "Chart Title" ],
        [ 'exec|e=s@',  "Execute command on the output" ]
    );
=end foo

=head1 NAME

gimpgitbuild cleanbuild - clean the build checkouts / working copies.


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
