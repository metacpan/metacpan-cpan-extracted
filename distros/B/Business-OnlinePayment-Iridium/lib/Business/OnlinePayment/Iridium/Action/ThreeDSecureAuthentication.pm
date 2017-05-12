package Business::OnlinePayment::Iridium::Action::ThreeDSecureAuthentication;

use Moose;

with 'Business::OnlinePayment::Iridium::Action';

has 'CrossReference' => (
  isa => 'Int',
  is  => 'rw', required => '1'
);

has 'PaRES' => (
  isa => 'Str',
  is  => 'rw', required => '1'
);

sub _build__type { return 'ThreeDSecureAuthentication' }

sub template {
  return <<DATA;
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xmlns:xsd="http://www.w3.org/2001/XMLSchema"
               xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
<soap:Body>
  <ThreeDSecureAuthentication xmlns="https://www.thepaymentgateway.net/">
    <ThreeDSecureMessage>
      <MerchantAuthentication MerchantID="[% MerchantID %]" Password="[% Password %]" />
      <ThreeDSecureInputData CrossReference="[% CrossReference %]">
        <PaRES>
          [% PaRES %]
        </PaRES>
      </ThreeDSecureInputData>
      <PassOutData>[% PassOutData %]</PassOutData>
    </ThreeDSecureMessage>
  </ThreeDSecureAuthentication>
</soap:Body>
</soap:Envelope>
DATA
}

1;
