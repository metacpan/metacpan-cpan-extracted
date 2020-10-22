package Acme::CPANAuthors::Israeli;
$Acme::CPANAuthors::Israeli::VERSION = '0.0400';
use warnings;
use strict;


use Acme::CPANAuthors::Register (
    AMOSS     => 'Amos Shapira',
    EILARA    => 'Ran Eilam',
    FELIXL    => 'Felix Liberman',
    GENIE     => 'Goldin Evgeny',
    ISAAC     => 'Issac Goldstand',
    MIGO      => 'Mikhael Goikhman',
    NUFFIN    => 'Yuval Kogman',
    PETERG    => 'Peter Gordon',
    PRILUSKYJ => 'Jaime Prilusky',
    RAZINF    => 'Oded S. Resnik',
    REUVEN    => 'Reuven M. Lerner',
    ROMM      => 'Roman Parparov',
    SEMUELF   => 'Shmuel Fomberg',
    SHLOMIF   => 'Shlomi Fish',
    SHLOMOY   => 'Shlomo Yona',
    SMALYSHEV => 'Stanislav Malyshev',
    SZABGAB   => 'Gabor Szabo',
    YOSEFM    => 'Yosef Meller',
    SCHOP     => 'Ariel Brosh (R.I.P.)',
);



1;    # End of Acme::CPANAuthors::Israeli

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::Israeli - We are Israeli CPAN Authors

=head1 VERSION

version 0.0400

=head1 SYNOPSIS

    use Acme::CPANAuthors;
    use Acme::CPANAuthors::Israeli;

    my $authors = Acme::CPANAuthors->new('Israeli');

    my $number = $authors->count;
    my @ids = $authors->id();
    my @distors = $authors->distributions('NUFFIN');
    my $url = $authors->avatar_url('SZABGAB');

=head1 DESCRIPTION

This class provides a hash of Pause IDs/names of Israeli CPAN authors.

=head1 MAINTENANCE

If you are an Israeli CPAN author and are not listed here, please contact
me.

=head1 SEE ALSO

L<Acme::CPANAuthors> - the driver for this class.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Acme-CPANAuthors-Israeli>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANAuthors-Israeli>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Acme-CPANAuthors-Israeli>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/Acme-CPANAuthors-Israeli>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Acme-CPANAuthors-Israeli>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Acme::CPANAuthors::Israeli>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-acme-cpanauthors-israeli at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Acme-CPANAuthors-Israeli>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-Acme-CPANAuthors-Israeli>

  git clone git://github.com/shlomif/perl-Acme-CPANAuthors-Israeli.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-Acme-CPANAuthors-Israeli/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
