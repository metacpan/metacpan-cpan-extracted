package Business::OnlinePayment::Iridium::Action::GetGatewayEntryPoints;

use Moose;

with 'Business::OnlinePayment::Iridium::Action';

sub _build__type { return 'GetGatewayEntryPoints' }

sub template {
  return <<DATA;
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xmlns:xsd="http://www.w3.org/2001/XMLSchema"
               xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
<soap:Body>
  <GetGatewayEntryPoints xmlns="https://www.thepaymentgateway.net/">
    <GetGatewayEntryPointsMessage>
      <MerchantAuthentication MerchantID="[% MerchantID %]" Password="[% Password %]" />
    </GetGatewayEntryPointsMessage>
  </GetGatewayEntryPoints>
</soap:Body>
</soap:Envelope>
DATA
}

1;
