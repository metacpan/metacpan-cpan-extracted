package Business::OnlinePayment::Iridium::Action::GetGatewayEntryPoints;

use Moose;

with 'Business::OnlinePayment::Iridium::Action';

# PODNAME: Business::OnlinePayment::Iridium::Action::GetGatewayEntryPoints
# ABSTRACT: Query PayVectors gateways

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

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::OnlinePayment::Iridium::Action::GetGatewayEntryPoints - Query PayVectors gateways

=head1 VERSION

version 1.01

=head2 template

SOAP template to use to send to PayVector / Iridium

=head1 AUTHOR

[ 'Gavin Henry <ghenry@surevoip.co.uk>', 'Wallace Reis <reis.wallace@gmail.com>' ]

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by [ 'Gavin Henry', 'Wallace Reis' ].

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
