package Acme::MetaSyntactic::counting_rhyme;
use strict;
use Acme::MetaSyntactic::Locale;
our @ISA = qw( Acme::MetaSyntactic::Locale );
our $VERSION = '1.001';
__PACKAGE__->init();
1;

=encoding iso-8859-1

=head1 NAME

Acme::MetaSyntactic::counting_rhyme - The counting rhyme theme

=head1 DESCRIPTION

Based on popular children counting rhymes, mostly used to decide roles
in games (who'll be the wolf?)

=head1 FULL VERSIONS

=head2 English

    Eeny, meeny, miny, moe
    Catch a tiger by the toe
    If he hollers let him go,
    Eeny, meeny, miny, moe.

=head2 French

    Am, stram, gram,
    Pique et pique et colégram
    Bourre, bourre et ratatam
    Am, stram, gram.

=head2 Dutch

    Iene, miene, mutte,
    tien pond grutten,
    tien pond kaas,
    Iene, miene, mutte,
    is de baas.

=head2 German

    Eene, Meene, Muh, und raus bist du
    Eene, Meene, Maus, und du bist raus
    Eene, Meene, Meck, und du bist weg
    Weg bist du noch lange nicht,
    sag mir erst wie alt du bist.

=head1 CONTRIBUTORS

Xavier Caron, Paul-Christophe Varoutas, Abigail, Yanick and Anja Champoux.

=head1 CHANGES

=over 4

=item *

2012-05-14 - v1.001

Updated with an C<=encoding> pod command in Acme-Meta version 1.001.

=item *

2012-05-07 - v1.000

Received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-04-03

Updated with the German theme in Acme-MetaSyntactic version 0.68.

=item *

2006-03-24

Yanick Champoux provided a patch to add a German countring rhyme (RT #18330).

=item *

2005-11-07

Updated with the Dutch theme in Acme-MetaSyntactic version 0.47.

=item *

2005-10-25

Abigail provided a patch to add a Dutch counting rhyme.

=item *

2005-09-12

Patched a typo in Acme-MetaSyntactic version 0.39.

=item *

2005-07-11

Introduced in Acme-MetaSyntactic version 0.30.

Xavier Caron proposed the idea in French, and Paul-Christophe Varoutas
provided the English version.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::Locale>.

=cut

__DATA__
# default
en
# names en 
eenie meeny miny moe
catch a tiger by the toe 
if he hollers let him go 
# names fr
am stram gram
pique et colegram
bourre ratatam
# names nl 
iene miene mutte
tien pond grutten
kaas is de baas
# names de
eene meene muh und raus bist du 
maus meck weg 
noch lange nicht 
sag mir erst wie alt
