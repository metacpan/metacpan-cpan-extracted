package Acme::MetaSyntactic::oulipo;
use strict;
use Acme::MetaSyntactic::List;
our @ISA     = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.003';
use utf8;

=encoding utf-8

=head1 NAME

Acme::MetaSyntactic::oulipo - The Oulipo theme

=head1 DESCRIPTION

This theme contains the initials of the members of the French literary
group Oulipo, created by Raymond Queneau (RQ) and François Le Lionnais
(FLL) in 1960. These initials are commonly used in place of a member's
full name.

See the official Oulipo web site at L<http://www.oulipo.net/>.

=cut

__PACKAGE__->init(
    { names => join ' ',
        map   join( '', /\b([A-Z])/g ),
        grep  /^[A-Z]/,
        split /\n/, << '=cut' } );

=head2 Members

=over 4

=item *

Noël ARNAUD (1919-2003), founding member.

=item *

Michèle AUDIN (1954-), joined in 2009.

=item *

Valérie BEAUDOUIN (1968-), joined in 2003.

=item *

Marcel BÉNABOU (1939-), joined in 1970.

=item *

Jacques BENS (1931-2001), founding member.

=item *

Claude BERGE (1926-2002), founding member.

=item *

Eduardo BERTI (1964-), joined in 2014.

=item *

André BLAVIER (1922-2001), foreign correspondent.

=item *

Paul BRAFFORT (1923-), joined in 1961.

=item *

Italo CALVINO (1923-1985), joined in 1974.

=item *

François CARADEC (1924-2008), joined in 1983.

=item *

Bernard CERQUIGLINI (1947-), joined in 1995.

=item *

Ross CHAMBERS (1932-), joined in 1961.

=item *

Stanley CHAPMAN (1925-2009), joined in 1961.

=item *

Marcel DUCHAMP (1887-1968), joined in 1962.

=item *

Jacques DUCHATEAU (1929-), founding member.

=item *

Luc ETIENNE (1908-1984), joined in 1970.

=item *

Frédéric FORTE (1973-), joined in 2005.

=item *

Paul FOURNEL (1947-), joined in 1972.

=item *

Anne F. GARRÉTA (1962-), joined in 2000.

=item *

Michelle GRANGAUD (1941-), joined in 1995.

=item *

Jacques JOUET (1947-), joined in 1983.

=item *

LATIS (1913-1973), founding member.

=item *

François LE LIONNAIS (1901-1984), founder.

=item *

Hervé LE TELLIER (1957-), joined in 1992.

=item *

Étienne LÉCROART (1960-), joined in 2012.

=item *

Jean LESCURE (1912-2005), founding member.

=item *

Daniel LEVIN BECKER (1984-), joined in 2009.

=item *

Pablo MARTÍN SÁNCHEZ (1977-), joined in 2014.

=item *

Harry MATHEWS (1930-), joined in 1973.

=item *

Michèle MÉTAIL (1950-), joined in 1975.

=item *

Ian MONK (1960-), joined in 1998.

=item *

Oskar PASTIOR (1927-2006), joined in 1992.

=item *

Georges PEREC (1936-1982), joined in 1967.

=item *

Raymond QUENEAU (1903-1976), founder.

=item *

Jean QUEVAL (1913-1990), founding member.

=item *

Pierre ROSENSTIEHL (1933-), joined in 1992.

=item *

Jacques ROUBAUD (1932-), joined in 1966.

=item *

Olivier SALON (1955-), joined in 2000.

=item *

Albert-Marie SCHMIDT (1901-1966), founding member.

=back

=cut

=head1 CONTRIBUTOR

Philippe "BooK" Bruhat, co-creator (with Estelle Souche) of
the first Oulipo web site, back in 1995.

=head1 CHANGES

=over 4

=item *

2014-09-15 - v1.003

Updated with two new members,
added the date each member joined the group,
in Acme-MetaSyntactic-Themes version 1.042.

=item *

2012-10-08 - v1.002

Updated with a new member,
added the list of Oulipo member names (with activity dates),
in Acme-MetaSyntactic-Themes version 1.022.

=item *

2012-05-14 - v1.001

Updated with an C<=encoding> pod command
in Acme-MetaSyntactic-Themes version 1.001.

=item *

2012-05-07 - v1.000

Updated with the new Oulipo members since 2007, and
received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2005-06-27

Introduced in Acme-MetaSyntactic version 0.28.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

1;

