package Business::OnlinePayment::Iridium::Action::ThreeDSecureAuthentication;

use Moose;

with 'Business::OnlinePayment::Iridium::Action';

# PODNAME: Business::OnlinePayment::Iridium::Action::ThreeDSecureAuthentication
# ABSTRACT: Handle 3DSecure

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

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::OnlinePayment::Iridium::Action::ThreeDSecureAuthentication - Handle 3DSecure

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
