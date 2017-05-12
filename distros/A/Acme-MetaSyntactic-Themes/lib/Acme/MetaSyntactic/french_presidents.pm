package Acme::MetaSyntactic::french_presidents;
use strict;
use Acme::MetaSyntactic::MultiList;
our @ISA = qw( Acme::MetaSyntactic::MultiList );
our $VERSION = '1.000';

=encoding iso-8859-1

=head1 NAME

Acme::MetaSyntactic::french_presidents - The presidents of France theme

=head1 DESCRIPTION

Presidents of the various French republics.

This list is based on the official Élysée list, available at:
L<http://www.elysee.fr/president/la-presidence/les-presidents-depuis-1848/histoire-des-presidents-de-la-republique/les-anciens-presidents-de-la-republique.483.html>
The typograpical errors in the names have been corrected, though.

=head1 FRENCH PRESIDENTS

=cut

{
    my %data;
    my $republic;
    for ( split /\n/ => <<'=cut' ) {

=head2 The Fifth Republic

=over 4

=item François Hollande (2012-)

=item Nicolas Sarkozy (2007-2012)

=item Jacques Chirac (1995-2007)

=item François Mitterrand (1981-1995)

=item Valéry Giscard d'Estaing (1974-1981)

=item Alain Poher (1974, interim from 02/04/1974 to 19/05/1974)

=item Georges Pompidou (1969-1974)

=item Alain Poher (1969, interim from 28/04/1969 to 20/06/1969)

=item Charles de Gaulle (1959-1969)

=back

=head2 The Fourth Republic

=over 4

=item René Coty (1954-1959)

=item Vincent Auriol (1947-1954)

=back

=head2 The Third Republic

=over 4

=item Albert Lebrun (1932-1940)

=item Paul Doumer (1931-1932)

=item Gaston Doumergue (1924-1931)

=item Alexandre Millerand (1920-1924)

=item Paul Deschanel (18 fév-20 sept 1920)

=item Raymond Poincaré (1913-1920)

=item Armand Fallières (1906-1913)

=item Émile Loubet (1899-1906)

=item Félix Faure (1895-1899)

=item Jean Casimir-Perier (1894-1895)

=item Marie François Sadi Carnot (1887-1894)

=item Jules Grévy (1879-1887)

=item Patrice de Mac Mahon (1873-1879)

=item Adolphe Thiers (1871-1873)

=back

=head2 The Second Republic

=over 4

=item Louis-Napoléon Bonaparte (1848-1851)

=back

=cut

        /^=head2 The (.*)/ && do {
            $republic = lc $1;
            $republic =~ s/\W+/_/g;
        };
        /^=item (.*) \(/ && do {
            my $item = Acme::MetaSyntactic::RemoteList::tr_accent("$1");
            $item =~ s/\W+/_/g;
            $data{$republic} .= "$item ";
        };
    }
    __PACKAGE__->init( { names => \%data, default => ':all' } );
}

=head1 CONTRIBUTOR

Philippe Bruhat (BooK)

=head1 CHANGES

=over 4

=item *

2012-05-07 - v1.000

Introduced in Acme-MetaSyntactic-Themes version 1.000
(the day after the election of François Hollande).

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

