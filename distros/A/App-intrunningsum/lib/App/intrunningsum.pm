package App::intrunningsum;
$App::intrunningsum::VERSION = '0.0.2';
use strict;
use warnings;

use Math::GMP ();

sub new
{
    my $class = shift;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

sub _init
{
    my ($self, $args) = @_;

    return;
}

sub run
{
    my $s = Math::GMP->new('0');

    while (my $l = <ARGV>)
    {
        chomp$l;
        print (($s += Math::GMP->new($l)), "\n");
    }

    return;
}

1;

__END__

=pod

=head1 NAME

App::intrunningsum - running sum of decimal big integers from stdin or files

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    $ (echo 2 ; echo 3) | intrunningsum
    2
    5

=head1 DESCRIPTION

Performs an arithmetic sum of decimal integers in the files given as command
line arguments and STDIN, and displays the intermediate results at each line.

=head1 VERSION

=head1 METHODS

=head2 new

Constructor - for internal use.

=head2 run

Run the app - for internal use.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/app-intrunningsum/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-intrunningsum>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/App-intrunningsum>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-intrunningsum>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/App-intrunningsum>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/App-intrunningsum>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-intrunningsum>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-intrunningsum>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-intrunningsum>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::intrunningsum>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-intrunningsum at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-intrunningsum>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/App-intsum>

  git clone https://github.com/shlomif/App-intsum.git

=cut
