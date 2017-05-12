package Acme::CPANAuthors::Spanish;

use warnings;
use strict;
use utf8;

our $VERSION = '0.06';

use Acme::CPANAuthors::Register ( ALEXM     => 'Alex Muntada',
                                  AMONTERO  => 'Alberto Montero Asenjo',
                                  BRUNODIAZ => 'Bruno Díaz Brière',
                                  BREQUESEN => 'Bernat Requesens',
                                  CARLOSFB  => 'Carlos Fuentes',
                                  CASIANO   => 'Casiano Rodríguez-León',
                                  DIEGOK    => 'Diego Kuperman',
                                  ECASTILLA => 'Enrique Castilla Contreras',
                                  EDUSEGRE  => 'Eduardo Segredo González',
                                  EJDRS     => 'Evilio José del Río Silván',
                                  ENELL     => 'Enrique Nell',
                                  EXPLORER  => 'Joaquín Ferrero',
                                  FMERGES   => 'Florián Merges',
                                  FXN       => 'Xavier Noria',
                                  JAVIER    => 'Javier Arturo Rodríguez Gutiérrez',
                                  JFRAIRE   => 'Julio Fraire Domínguez',
                                  JLMARTIN  => 'José Luis Martínez Torres',
                                  JMERELO   => 'J. J. Merelo-Guervós',
                                  JOSERODR  => 'José A. Rodríguez',
                                  JREY      => 'José Rey',
                                  MRUIZ     => 'Míquel Ruiz Martín',
                                  NES       => 'Enrique F. Castañón',
                                  NITO      => 'Nito Martínez',
                                  PECO      => 'Juan José San Martín',
                                  RODRIGO   => 'Rodrigo de Oliveira González',
                                  RPORRES   => 'Rafael Porres Molina',
                                  SALVA     => 'Salvador Fandiño García',
                                  XCALBET   => 'Xavier Calbet',
                                );

__END__

=head1 NAME

Acme::CPANAuthors::Spanish - We are the Spanish CPAN Authors

=head1 SYNOPSIS

	use Acme::CPANAuthors;

	my $authors = Acme::CPANAuthors->new('Spanish');

	my $number   = $authors->count;
	my @ids      = $authors->ids();
	my @distros  = $authors->distributions('NITO');
	my $url      = $authors->avatar_url('ENELL');

=head1 DESCRIPTION

This class provides a hash of Spanish CPAN authors' PAUSE ID and name
to the Acme::CPANAuthors module.

=head1 MAINTENANCE

If you are an Spanish CPAN author not listed here, please send me your
ID/name via email or RT so we can always keep this module up to date.
If there's a mistake and you're listed here but are not Spanish
(or just don't want to be listed), sorry for the inconvenience:
please contact me and I'll remove the entry right away.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-cpanauthors-spanish@rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-CPANAuthors-Spanish>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::CPANAuthors::Spanish

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-CPANAuthors-Spanish>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-CPANAuthors-Spanish>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-CPANAuthors-Spanish>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-CPANAuthors-Spanish/>

=item * Github - get the source code

L<http://github.com/salva/p5-Acme-CPANAuthors-Spanish>

=back

=head1 COPYRIGHT & LICENSE

This module is in the public domain.

=cut

1; # End of Acme::CPANAuthors::Spanish
