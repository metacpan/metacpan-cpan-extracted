package Acme::MetaSyntactic::bottles;
use strict;
use Acme::MetaSyntactic::Locale;
our @ISA = qw( Acme::MetaSyntactic::Locale );
our $VERSION = '1.000';
__PACKAGE__->init();
1;

=head1 NAME

Acme::MetaSyntactic::bottles - Bottle sizes, kings, patriarchs and private eyes

=head1 DESCRIPTION

Names for wine and champagne bottles of different sizes. 

This list is a mixed bag containing ancient kings,
biblical patriarchs and an Hawaiian private eye.

Yet, some people pretend this list is a companion
to L<Acme::MetaSyntactic::booze>.

Sources:

=over 4

=item *

L<http://fr.wikipedia.org/wiki/Vin_de_Champagne#Flacons>,

=item *

L<http://www.diracdelta.co.uk/science/source/b/o/bottle/source.html>,

=item *

L<http://damngoodwine.com/botts1.htm>,

=item *

L<http://www.champagnemagic.com/sizes.htm>,

=item *

L<http://www.ebrew.com/primarynews/wine_bottle_sizes.htm>,

=item *

L<http://www.awinestore.com/big_bottles.htm>.

=back

=head1 CONTRIBUTORS

Abigail, Jean Forget.

=head1 CHANGES

=over 4

=item *

2012-09-10 - v1.000

Merged both versions of the module in a single one,
published in Acme-MetaSyntactic-Themes version 1.018.

=item *

2006-08-09

Submitted by Jean Forget, as a multilist with French and English bottle names.

=item *

2005-11-01

Submitted by Abigail.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::Locale>.

=cut

__DATA__
# default
en
# names en
split                quarter_bottle   piccolo
half_bottle          demiboite
bottle               fifth
magnum
marie_jean
double_magnum        jeroboam
rehoboam
imperial             methusalem       methusalah
salmanazar
balthazar
nebuchadnezzar
solomon              melchior
sovereign
primat
# names fr
bouteille
magnum
jeroboam
rehoboam
mathusalem
salmanazar
balthazar
nabuchodonosor
