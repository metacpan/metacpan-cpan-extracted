package Business::OnlinePayment::Iridium::Action::GetCardType;

use Moose;

with 'Business::OnlinePayment::Iridium::Action';

has 'CardNumber' => (
  isa => 'Str',
  is  => 'rw', required => '1'
);

sub _build__type { return 'GetCardType' }

sub template {
  return <<DATA;
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xmlns:xsd="http://www.w3.org/2001/XMLSchema"
               xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
<soap:Body>
  <GetCardType xmlns="https://www.thepaymentgateway.net/">
    <GetCardTypeMessage>
      <MerchantAuthentication MerchantID="[% MerchantID %]" Password="[% Password %]" />
      <CardNumber>[% CardNumber %]</CardNumber>
    </GetCardTypeMessage>
  </GetCardType>
</soap:Body>
</soap:Envelope>
DATA
}

1;
