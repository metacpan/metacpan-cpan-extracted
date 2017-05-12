package Acme::MetaSyntactic::jerkcity;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.000';
__PACKAGE__->init();
1;

=encoding iso-8859-1

=head1 NAME

Acme::MetaSyntactic::jerkcity - The Jerkcity theme

=head1 DESCRIPTION

Character names and other keywords from the popular (at least
on #perl) webcomic I<jerkcity>.

See L<http://www.jerkcity.com/> for details.

=head1 CONTRIBUTOR

Rafaël Garcia-Suarez.

=head1 CHANGES

=over 4

=item *

2012-05-07 - v1.000

Received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2005-08-29

Introduced in Acme-MetaSyntactic version 0.37.

=item *

2005-08-23

After some discussion on IRC, C<rgs> provided the initial list:

    14:10 <@rgs> il faut en faire un jerkcity
    14:10 <@rgs> DONGS
    14:10 <@rgs> spigot deuce rands
    14:10 <@rgs> et pants
    14:11 <@rgs> HUGLAGHALGHALGHAL
    14:11 <@rgs> T
    14:12 <@rgs> il doit être possible d'extraire la liste des personnages automatiquement
    14:12 <@rgs> avec un script perl, par exemple
    14:17 <@rgs> http://en.wikipedia.org/wiki/Jerkcity
    14:18 <@BooK> rgs: patches welcome
    14:18 <+purl> Of course, you really mean FOAD, HAND, HTH
    14:19 <@rgs> BooK: forthcoming
    14:21 <@rgs> BooK: Atandt Bung Deuce Dick Effigy Hanford Harriet Jean_Charles Net Ozone Pants Rands Spigot T HUGLAGHALGHALGHAL gay dicks dongs rape piss
    14:23 <@rgs> d'autres mots-clés du plot ?
    14:24 <@rgs> hmm, peut être faut ajouter une option --over-18 à meta(1)

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
Atandt Bung Deuce Dick Effigy Hanford Harriet Jean_Charles Net Ozone
Pants Rands Spigot T HUGLAGHALGHALGHAL gay dicks dongs rape piss

