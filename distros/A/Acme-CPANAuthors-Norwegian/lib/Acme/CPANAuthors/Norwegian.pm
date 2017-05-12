package Acme::CPANAuthors::Norwegian;
use utf8; # encoding="utf-8"

use warnings;
use strict;

our $VERSION = '0.2';

use Acme::CPANAuthors::Register (
	AFF       => 'Andreas Faafeng',
	ALKNAFF   => 'Alain Knaff',
	ANDREMAR  => 'Andreas Marienborg',
	ARNE      => 'Arne Sommer',
	ARNESOND  => 'Dag Arneson',
	AVITARNET => 'David Peter Smith',
	CAFFIEND  => 'Andrew Robertson',
	COSIMO    => 'Cosimo Streppone',
	CRAFFI    => 'Chris Dagdigian',
	EARNESON  => 'Erik Arneson',
	EBHANSSEN => 'Eirik Berg Hanssen',
	GAFFER    => 'George A. Fitch III',
	GAFFIE    => 'Mario Gaffiero',
	GIRAFFED  => 'Bryan Henderson',
	JANL      => 'Nicolai Langfeldt',
	KIRILLM   => 'Кирилл Мязин',
	KJETIL    => 'Kjetil Skotheim',
	KJETILK   => 'Kjetil Kjernsmo',
	LARSNYG   => 'Lars Nygaard',
	MRAMBERG  => 'Marcus Ramberg',
	PEREINAR  => 'Per Einar Ellefsen',
	PJACKLAM  => 'Peter John Acklam',
	PRATZLAFF => 'Pete Ratzlaff',
	RGRAFF    => 'Robert Graff',
	SCHAFFTER => 'Gustav Schaffter',
	SJN       => 'Salve J. Nilsen',
	SLAFF     => 'Slavej Karadjov',
	TAFFY     => 'David Kr�ber',
	TECHIE    => 'Thomas Martinsen',
	TERJE     => 'Terje Br�ten',
	TROHAU    => 'Trond Haugen',
);

1;
__END__

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::Norwegian - We are Norwegian CPAN authors

=head1 SYNOPSIS

    use Acme::CPANAuthors;

    my $authors  = Acme::CPANAuthors->new("Norwegian");

    my $number   = $authors->count;
    my @ids      = $authors->id;
    my @distros  = $authors->distributions("MRAMBERG");
    my $url      = $authors->avatar_url("SJN");
    my $kwalitee = $authors->kwalitee("COSIMO");
    my $name     = $authors->name("TAFFY");

See documentation for L<Acme::CPANAuthors> for more details.

=head1 DESCRIPTION

This class provides a hash of Norwegian CPAN authors' PAUSE ID and name to
the C<Acme::CPANAuthors> module.

=head1 MAINTENANCE

If you are a Norwegian CPAN author not listed here, please send me your ID/name
via email or RT so I can always keep this module up to date.


=head1 CONTAINED AUTHORS

Now B<32> Norwegian CPAN authors:

	AFF       => 'Andreas Faafeng',
	ALKNAFF   => 'Alain Knaff',
	ANDREMAR  => 'Andreas Marienborg',
	ARNE      => 'Arne Sommer',
	ARNESOND  => 'Dag Arneson',
	AVITARNET => 'David Peter Smith',
	CAFFIEND  => 'Andrew Robertson',
	COSIMO    => 'Cosimo Streppone',
	CRAFFI    => 'Chris Dagdigian',
	EARNESON  => 'Erik Arneson',
	EBHANSSEN => 'Eirik Berg Hanssen',
	GAFFER    => 'George A. Fitch III',
	GAFFIE    => 'Mario Gaffiero',
	GIRAFFED  => 'Bryan Henderson',
	JANL      => 'Nicolai Langfeldt',
	KIRILLM   => 'Кирилл Мязин',
	KJETIL    => 'Kjetil Skotheim',
	KJETILK   => 'Kjetil Kjernsmo',
	LARSNYG   => 'Lars Nygaard',
	MRAMBERG  => 'Marcus Ramberg',
	PEREINAR  => 'Per Einar Ellefsen',
	PJACKLAM  => 'Peter John Acklam',
	PRATZLAFF => 'Pete Ratzlaff',
	RGRAFF    => 'Robert Graff',
	SCHAFFTER => 'Gustav Schaffter',
	SJN       => 'Salve J. Nilsen',
	SLAFF     => 'Slavej Karadjov',
	TAFFY     => 'David Kr�ber',
	TECHIE    => 'Thomas Martinsen',
	TERJE     => 'Terje Br�ten',
	TROHAU    => 'Trond Haugen',

=head1 SEE ALSO

L<Acme::CPANAuthors> L<Acme::CPANAuthors::Russian> L<http://search.cpan.org/search?query=Acme%3A%3ACPANAuthors&mode=all>

=head1 AUTHOR

Anatoly Sharifulin, C<< <sharifulin at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-cpanauthors-Norwegian at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-CPANAuthors-Norwegian>.  We will be notified, and then you'll
automatically be notified of progress on your bug as we make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::CPANAuthors::Norwegian

You can also look for information at:

=over 5

=item * Github

L<http://github.com/sharifulin/acme-cpanauthors-Norwegian/tree/master>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-CPANAuthors-Norwegian>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-CPANAuthors-Norwegian>

=item * CPANTS: CPAN Testing Service

L<http://cpants.perl.org/dist/overview/Acme-CPANAuthors-Norwegian>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-CPANAuthors-Norwegian>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-CPANAuthors-Norwegian>

=back

=head1 COPYRIGHT & LICENSE

Copyright (C) 2009-2010 by Anatoly Sharifulin.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
