package Acme::MetaSyntactic::muses;
use strict;
use Acme::MetaSyntactic::Locale;
our @ISA = qw( Acme::MetaSyntactic::Locale );
our $VERSION = 1.001;
__PACKAGE__->init();
1;

=head1 NAME

Acme::MetaSyntactic::muses - Greek Muses

=head1 DESCRIPTION

The nine muses from Greek mythology.

=head1 CONTRIBUTORS

Abigail, Philippe Bruhat (BooK)

=head1 CHANGES

=over 4

=item *

2012-05-21 - v1.001

Made multilingual. Added translations for I<de>, I<en>, I<eo>, I<es>,
I<fr>, I<it>, I<la> (the default), I<nl>, I<pl>, I<pt>.

Published in Acme-MetaSyntactic-Themes version 1.002.

=item *

2012-05-14 - v1.000

Introduced in Acme-MetaSyntactic-Themes version 1.001.

=item *

2005-10-24

Submitted by Abigail.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# default
la
# names de
Kalliope Klio Erato Euterpe Melpomene Polyhymnia Terpsichore Thalia  Urania
# names en
Calliope Clio Erato Euterpe Melpomene Polyhymnia Terpsichore Thalia  Urania
# names eo
Kaliopo  Klio Erato Euterpo Melpomeno Polimnio   Terpsihoro  Talio   Uranio
# names es
Caliope  Clio Erato Euterpe Melpomene Polimnia   Terpsicore  Talia   Urania
# names fr
Calliope Clio Erato Euterpe Melpomene Polymnie   Terpsichore Thalie  Uranie
# names it
Calliope Clio Erato Euterpe Melpomene Polimnia   Tersicore   Talia   Urania
# names la
Calliope Clio Erato Euterpe Melpomene Polyhymnia Terpsichore Thalia  Urania
# names nl
Kalliope Clio Erato Euterpe Melpomene Polyhymnia Terpsichore Thaleia Urania
# names pl
Kalliope Klio Erato Euterpe Melpomene Polihymnia Terpsychora Talia   Urania
# names pt
Caliope  Clio Erato Euterpe Melpomene Polimnia   Terpsicore  Talia   Urania
