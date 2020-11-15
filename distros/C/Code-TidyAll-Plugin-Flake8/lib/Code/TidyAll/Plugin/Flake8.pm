package Code::TidyAll::Plugin::Flake8;
$Code::TidyAll::Plugin::Flake8::VERSION = '0.4.0';
use Moo;
use String::ShellQuote qw/ shell_quote /;

use vars qw/ $_check /;

BEGIN
{
    my $code = <<'EOF';
from flake8.main import application

def _py_check(fn):
    app = application.Application()
    app.run([fn])
    return ((app.result_count > 0) or app.catastrophic_failure)
EOF
    ## no critic
    if ( ( eval "use Inline Python => \$code" ) and !$@ )
    {
        ## use critic
        $_check = sub { return _py_check(shift); };
    }
    else
    {
        $_check = sub {
            my $cmd = shell_quote( 'flake8', shift );
            return scalar `$cmd`;
        };
    }
}
extends 'Code::TidyAll::Plugin';

sub validate_file
{
    my ( $self, $fn ) = @_;
    if ( my $error = $_check->($fn) )
    {
        die qq#flake8 validation failed for the file "$fn" ; error="$error"#;
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Plugin::Flake8 - run flake8 using Code::TidyAll

=head1 VERSION

version 0.4.0

=head1 SYNOPSIS

In your C<.tidyallrc>:

    [Flake8]
    select = **/*.py

=head1 DESCRIPTION

This speeds up the flake8 python tool ( L<http://flake8.pycqa.org/en/latest/>
) checking by caching results using L<Code::TidyAll> .

It was originally written for use by PySolFC
( L<http://pysolfc.sourceforge.net/> ), an open suite of card solitaire
games.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Code-TidyAll-Plugin-Flake8>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Code-TidyAll-Plugin-Flake8>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Code-TidyAll-Plugin-Flake8>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/C/Code-TidyAll-Plugin-Flake8>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Code-TidyAll-Plugin-Flake8>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Code::TidyAll::Plugin::Flake8>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-code-tidyall-plugin-flake8 at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Code-TidyAll-Plugin-Flake8>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-Code-TidyAll-Plugin-Flake8>

  git clone https://github.com/shlomif/perl-Code-TidyAll-Plugin-Flake8.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/code-tidyall-plugin-flake8/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
