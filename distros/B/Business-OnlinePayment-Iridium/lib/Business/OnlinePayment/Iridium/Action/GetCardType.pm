package Business::OnlinePayment::Iridium::Action::GetCardType;

use Moose;

with 'Business::OnlinePayment::Iridium::Action';

# PODNAME: Business::OnlinePayment::Iridium::Action::GetCardType
# ABSTRACT: Query PayVector for card type (they do their best):w

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

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::OnlinePayment::Iridium::Action::GetCardType - Query PayVector for card type (they do their best):w

=head1 VERSION

version 1.03

=head2 template

SOAP template to use to send to PayVector / Iridium

=head1 AUTHOR

[ 'Gavin Henry <ghenry@surevoip.co.uk>', 'Wallace Reis <reis.wallace@gmail.com>' ]

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by [ 'Gavin Henry', 'Wallace Reis' ].

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
