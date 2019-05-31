package App::Deps::Verify::App::VerifyDeps::Command::plinst;
$App::Deps::Verify::App::VerifyDeps::Command::plinst::VERSION = '0.8.3';
use App::Deps::Verify::App::VerifyDeps -command;

use strict;
use warnings;

use Path::Tiny qw/ path /;
use App::Deps::Verify ();

sub abstract { "install perl5 dependencies from CPAN" }

sub description { return abstract(); }

sub opt_spec
{
    return (
        [ "input|i=s\@", "the input files" ],
        [ "notest",      "speed up installation by skipping the tests" ],
    );
}

sub validate_args
{
    my ( $self, $opt, $args ) = @_;

    # no args allowed but options!
    $self->usage_error("No args allowed") if @$args;
}

sub execute
{
    my ( $self, $opt, $args ) = @_;

    exit(
        system(
            "cpanm",
            ( $opt->{notest} ? ('--notest') : () ),
            "--",
            grep { /\A[A-Za-z0-9_:]+\z/ }
                @{ App::Deps::Verify->new->list_perl5_modules_in_yamls(
                    +{ filenames => [ @{ $opt->{input} }, ] }
                )->{perl5_modules}
                }
        )
    );

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Deps::Verify::App::VerifyDeps::Command::plinst

=head1 VERSION

version 0.8.3

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-Deps-Verify>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/App-Deps-Verify>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-Deps-Verify>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/App-Deps-Verify>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/App-Deps-Verify>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-Deps-Verify>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-Deps-Verify>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-Deps-Verify>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::Deps::Verify>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-deps-verify at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-Deps-Verify>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-App-Deps-Verify>

  git clone https://github.com/shlomif/perl-App-Deps-Verify.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/app-deps-verify/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
