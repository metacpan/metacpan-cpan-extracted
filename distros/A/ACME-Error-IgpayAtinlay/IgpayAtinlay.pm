package ACME::Error::IgpayAtinlay;

use strict;
no  strict 'refs';

use vars q[$VERSION];
$VERSION = '0.01';

use Lingua::Atinlay::Igpay qw[:all];

*die_handler = *warn_handler = sub {
  my @errors = @_;
  return enhay2igpayatinlay @errors;
};

1;
__END__

=head1 AMENAY

ACMEHAY::Errorhay::IgpayAtinlayhay - ACMEHAY::Errorhay Ackendbay otay Onvertcay Errorshay otay Igpay Atinlay

=head1 OPSISSYNAY

  usehay ACMEHAY::Errorhay => IgpayAtinlayhay;

  arnway "Adbay"; # Adbayhay

=head1 ESCRIPTIONDAY

Onvertscay ouryay errorshay otay Igpay Atinlay.

=head1 AUTHORHAY

Aseycay Estway <F<aseycay@eeknestgay.omcay>>

=head1 OPYRIGHTCAY

Opyrightcay (c) 2002 Aseycay R. Estway <aseycay@eeknestgay.omcay>.  Allhay
ightsray eservedray.  Isthay ogrampray ishay eefray oftwaresay; ouyay ancay
edistributeray ithay andhay/orhay odifymay ithay underhay ethay amesay ermstay ashay
Erlpay itselfhay.

=head1 EESAY ALSOHAY

erlpay(1), Ingualay::Atinlayhay::Igpayhay.

=cut
