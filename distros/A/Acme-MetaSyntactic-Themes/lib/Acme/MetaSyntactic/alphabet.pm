package Acme::MetaSyntactic::alphabet;
use strict;
use Acme::MetaSyntactic::Locale;
our @ISA = qw( Acme::MetaSyntactic::Locale );
our $VERSION = '1.000';
__PACKAGE__->init();
1;

=head1 NAME

Acme::MetaSyntactic::alphabet - Learn your ABC in various languages

=head1 DESCRIPTION

Various alphabets, transliterated if the latin alphabet doesn't fit.

I've found most of the transliterations on the Internet, which may
be wrong. Please correct me.

=head1 CONTRIBUTOR

Philippe "BooK" Bruhat.

=head1 ACKNOWLEDGMENTS

Thanks to Estelle Souche for help with the Yiddish Alef-Beys.

=head1 CHANGES

=over 4

=item *

2012-05-07 - v1.000

Updated with small fixes for category C<nato> (see RT #50160), and
received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2005-05-09

Introduced in Acme-MetaSyntactic version 0.21.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::Locale>.

=cut

__DATA__
# default
en
# names en
a b c d e f g h i j k l m n o p q r s t u v w x y z
# names it
a b c d e f g h i     l m n o p q r s t u v       z
# names la
a b c d e f   h i   k l m n o p q r s t   v   x
# names he
aleph bet gimmel dalet  hey vav    zayin chet tet  yod kaf
lamed mem nun    samech pay tsadie qof   resh shin tav
# names yi
alef  beys giml daled  hey  vov zayen  khes tes   yud  kof
lamed mem  nun  samekh ayen pey tsadik kuf  reysh shin tov
# names gr
alpha beta gamma   delta epsilon zeta  eta theta   iota kappa lambda mu
nu    xi   omicron pi    rho     sigma tau upsilon phi  chi   psi    omega
# names nato
alfa    bravo charlie  delta echo foxtrot golf  hotel  india juliett kilo
lima    mike  november oscar papa quebec  romeo sierra tango uniform victor
whiskey xray  yankee   zulu
# names ja
a  i   u   e  o
ka ki  ku  ke ko
sa shi su  se so
ta chi tsu te to
na ni  nu  ne no
ha hi  fu  he ho
ma mi  mu  me mo
ya     yu     yo    
ra ri  ru  re ro
wa wi      we wo  
              n
