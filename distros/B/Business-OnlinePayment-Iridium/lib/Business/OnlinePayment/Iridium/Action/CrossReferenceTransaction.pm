package Business::OnlinePayment::Iridium::Action::CrossReferenceTransaction;

use Moose;

with 'Business::OnlinePayment::Iridium::Action';

# PODNAME: Business::OnlinePayment::Iridium::Action::CrossReferenceTransaction
# ABSTRACT: Cross reference for repeast transactions etc.

has 'Amount' => (
  isa => 'Int',
  is  => 'rw', required => '1'
);

has 'OrderID' => (
  isa => 'Str',
  is  => 'rw', required => '1'
);

has 'OrderDescription' => (
  isa => 'Str',
  is  => 'rw', required => '0'
);

has 'TransactionType' => (
  isa => 'Str',
  is  => 'rw', required => '1'
);

has 'CrossReference' => (
  isa => 'Int',
  is  => 'rw', required => '1'
);

has 'CardName' => (
  isa => 'Str',
  is  => 'rw', required => '1'
);

has 'CardNumber' => (
  isa => 'Int',
  is  => 'rw', required => '1'
);

has 'ExpireMonth' => (
  isa => 'Int',
  is  => 'rw', required => '1'
);

has 'ExpireYear' => (
  isa => 'Int',
  is  => 'rw', required => '1'
);

sub _build__type { return 'CrossReferenceTransaction' }


sub template {
  return <<DATA;
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
<soap:Body>
  <CrossReferenceTransaction xmlns="https://www.thepaymentgateway.net/">
    <PaymentMessage>
      <MerchantAuthentication MerchantID="[% MerchantID %]" Password="[% Password %]" />
      <TransactionDetails Amount="[% Amount %]" CurrencyCode="[% CurrencyCode %]">
        <MessageDetails TransactionType="[% TransactionType %]" NewTransaction="FALSE"
           CrossReference="[% CrossReference %]" />
        <OrderID>[% OrderID %]</OrderID>
        <OrderDescription>[% OrderDescription %]</OrderDescription>
      </TransactionDetails>
      <PassOutData>[% PassOutData %]</PassOutData>
    </PaymentMessage>
  </CrossReferenceTransaction>
</soap:Body>
</soap:Envelope>
DATA
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::OnlinePayment::Iridium::Action::CrossReferenceTransaction - Cross reference for repeast transactions etc.

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
