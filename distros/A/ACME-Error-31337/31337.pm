package ACME::Error::31337;

use strict;
no  strict 'refs';

use vars q[$VERSION];
$VERSION = '0.01';

use Lingua::31337 qw[text231337];

*die_handler = *warn_handler = sub {
  return text231337 @_;
};

1;
__END__

=head1 n4Me

ACME::Error::31337 - ACM3::ERRoR b4ck3ND To tR4NSl4T3 erRorS 7O co0l 74Lk

=head1 sYn0PS1S

  use ACME::Error::31337;

  die "You stink!";

=head1 DEScR1Pt10N

CoNv3R7 y0Ur 3RR0rS 7o 31173 spE3cH.

US3 C<$Lingua::31337::LEVEL> 70 rA1sE OR 10W3r YoUR L3vel of 31I7eNess.

=head1 auTH0R

CAS3y W3ST <f<CaseY@geeKNEst.Com>>

=head1 cOpyRiGH7

COpYRiGht (C) 2002 C4s3Y R. weSt <C4seY@G33kneSt.cOM>.  4l1
r1gH7S ResERVED.  7h1S PR0grAm 1S pHr3E sOPhTW4RE; YoU c4n
red1S7rIBuT3 17 AND/0R m0dIpHy It UnDEr th3 SaMe TeRMS aS
Per1 itSE1F.

=head1 s3e aLSo

p3rl(1), AcM3::eRROr, L1NGu4::31337.

=cut
