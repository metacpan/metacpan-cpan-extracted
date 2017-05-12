package Business::PayPal::API::DirectPayments;
$Business::PayPal::API::DirectPayments::VERSION = '0.76';
use 5.008001;
use strict;
use warnings;

use SOAP::Lite;

#use SOAP::Lite +trace => 'debug';
use Business::PayPal::API ();

our @ISA       = qw(Business::PayPal::API);
our @EXPORT_OK = qw(DoDirectPaymentRequest);

sub DoDirectPaymentRequest {
    my $self = shift;
    my %args = @_;

    my %types = (
        PaymentAction => '',

        # Payment Detail
        OrderTotal    => 'xs:string',
        ItemTotal     => 'xsd:string',
        ShippingTotal => 'xsd:string',
        TaxTotal      => 'xsd:string',
        InvoiceID     => 'xsd:string',
        ButtonSource  => 'xsd:string',

        # Credit Card
        CreditCardType   => '',
        CreditCardNumber => 'xsd:string',
        ExpMonth         => 'xs:int',
        ExpYear          => 'xs:int',

        # CardOwner
        Payer => 'ns:EmailAddressType',

        # Payer Name
        FirstName => 'xs:string',
        LastName  => 'xs:string',

        #  Payer Address
        Street1         => 'xs:string',
        Street2         => 'xs:string',
        CityName        => 'xs:string',
        StateOrProvince => 'xs:string',
        Country         => 'xs:string',
        PostalCode      => 'xs:string',

        # Shipping Address
        ShipToName            => 'xs:string',
        ShipToStreet1         => 'xs:string',
        ShipToStreet2         => 'xs:string',
        ShipToCityName        => 'xs:string',
        ShipToStateOrProvince => 'xs:string',
        ShipToCountry         => 'xs:string',
        ShipToPostalCode      => 'xs:string',

        # Misc
        CVV2              => 'xs:string',
        IPAddress         => 'xs:string',
        MerchantSessionId => 'xs:string',
    );

    $args{currencyID}    ||= 'USD';
    $args{PaymentAction} ||= 'Sale';

    #Assemble Credit Card Information
    my @payername = (
        SOAP::Data->name( FirstName => $args{FirstName} ),
        SOAP::Data->name( LastName  => $args{LastName} ),
    );

    my @payeraddr = (
        SOAP::Data->name( Street1 => $args{Street1} )
            ->type( $types{Street1} ),
        SOAP::Data->name( Street2 => $args{Street2} )
            ->type( $types{Street2} ),
        SOAP::Data->name( CityName => $args{CityName} )
            ->type( $types{CityName} ),
        SOAP::Data->name( StateOrProvince => $args{StateOrProvince} )
            ->type( $types{StateOrProvince} ),
        SOAP::Data->name( Country => $args{Country} )
            ->type( $types{Country} ),
        SOAP::Data->name( PostalCode => $args{PostalCode} )
            ->type( $types{PostalCode} ),
    );

    my @shipaddr = (
        SOAP::Data->name( Name => $args{ShipToName} )
            ->type( $types{ShipToName} ),
        SOAP::Data->name( Street1 => $args{ShipToStreet1} )
            ->type( $types{ShipToStreet1} ),
        SOAP::Data->name( Street2 => $args{ShipToStreet2} )
            ->type( $types{ShipToStreet2} ),
        SOAP::Data->name( CityName => $args{ShipToCityName} )
            ->type( $types{ShipToCityName} ),
        SOAP::Data->name( StateOrProvince => $args{ShipToStateOrProvince} )
            ->type( $types{ShipToStateOrProvince} ),
        SOAP::Data->name( Country => $args{ShipToCountry} )
            ->type( $types{ShipToCountry} ),
        SOAP::Data->name( PostalCode => $args{ShipToPostalCode} )
            ->type( $types{ShipToPostalCode} ),
    );

    my @ccard = (
        SOAP::Data->name( CreditCardType => $args{CreditCardType} )
            ->type( $types{CreditCardType} ),
        SOAP::Data->name( CreditCardNumber => $args{CreditCardNumber} )
            ->type( $types{CreditCardNumber} ),
        SOAP::Data->name( ExpMonth => $args{ExpMonth} )
            ->type( $types{ExpMonth} ),
        SOAP::Data->name( ExpYear => $args{ExpYear} )
            ->type( $types{ExpYear} ),
    );

    my @ccowner = (
        SOAP::Data->name(
            CardOwner => \SOAP::Data->value(
                SOAP::Data->name( Payer => $args{Payer} )
                    ->type( $types{Payer} ),
                SOAP::Data->name(
                    PayerName => \SOAP::Data->value(@payername)
                ),
                SOAP::Data->name( Address => \SOAP::Data->value(@payeraddr) ),
            )
        )
    );

    push( @ccard, @ccowner );
    push(
        @ccard,
        SOAP::Data->name( CVV2 => $args{CVV2} )->type( $types{CVV2} )
    );

    #Assemble Payment Details
    my @paydetail = (
        SOAP::Data->name( OrderTotal => $args{OrderTotal} )
            ->attr( { currencyID => $args{currencyID} } )
            ->type( $types{currencyID} ),
        SOAP::Data->name( ItemTotal => $args{ItemTotal} )
            ->attr( { currencyID => $args{currencyID} } )
            ->type( $types{currencyID} ),
        SOAP::Data->name( TaxTotal => $args{TaxTotal} )
            ->attr( { currencyID => $args{currencyID} } )
            ->type( $types{currencyID} ),
        SOAP::Data->name( ShippingTotal => $args{ShippingTotal} )
            ->attr( { currencyID => $args{currencyID} } )
            ->type( $types{currencyID} ),
        SOAP::Data->name( ShipToAddress => \SOAP::Data->value(@shipaddr) ),
        SOAP::Data->name( InvoiceID     => $args{InvoiceID} )
            ->type( $types{InvoiceID} ),
        SOAP::Data->name( ButtonSource => $args{ButtonSource} )
            ->type( $types{ButtonSource} )
    );

    my @payreqdetail = (
        SOAP::Data->name( PaymentAction  => $args{PaymentAction} )->type(''),
        SOAP::Data->name( PaymentDetails => \SOAP::Data->value(@paydetail) ),
        SOAP::Data->name( CreditCard     => \SOAP::Data->value(@ccard) ),
        SOAP::Data->name( IPAddress      => $args{IPAddress} )
            ->type( $types{IPAddress} ),
        SOAP::Data->name( MerchantSessionId => $args{MerchantSessionId} )
            ->type( $types{MerchantSessionId} ),
    );

    #Assemble request
    my @reqval = (
        SOAP::Data->value( $self->version_req ),
        SOAP::Data->name(
            DoDirectPaymentRequestDetails => \SOAP::Data->value(@payreqdetail)
            )->attr( { xmlns => "urn:ebay:apis:eBLBaseComponents" } ),
    );
    my $request = (
        SOAP::Data->name(
            DoDirectPaymentRequest => \SOAP::Data->value(@reqval)
        ),
    );
    my $som      = $self->doCall( DoDirectPaymentReq => $request ) or return;
    my $path     = '/Envelope/Body/DoDirectPaymentResponse';
    my %response = ();
    unless ( $self->getBasic( $som, $path, \%response ) ) {
        $self->getErrors( $som, $path, \%response );
        return %response;
    }

    $self->getFields(
        $som, $path,
        \%response,
        {
            TransactionID => 'TransactionID',
            Amount        => 'Amount',
            AVSCode       => 'AVSCode',
            CVV2Code      => 'CVV2Code',
            Timestamp     => 'Timestamp',
        }
    );

    return %response;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Business::PayPal::API::DirectPayments - PayPal DirectPayments API

=head1 VERSION

version 0.76

=head1 SYNOPSIS

    use Business::PayPal::API qw(DirectPayments);

    ## see Business::PayPal::API documentation for parameters

    my $pp = Business::PayPal::API->new(
                        Username => 'name_api1.example.org',
                        Password => 'somepass',
                        CertFile => '/path/to/tester1.cert_key_pem.txt',
                        KeyFile  => '/path/to/tester1.cert_key_pem.txt',
                        sandbox  => 1,
                        );

    my %response = $pp->DoDirectPaymentRequest (
                        PaymentAction      => 'Sale',
                        OrderTotal         => 13.59,
                        TaxTotal           => 0.0,
                        ShippingTotal      => 0.0,
                        ItemTotal          => 0.0,
                        HandlingTotal      => 0.0,
                        InvoiceID          => 'your-tracking-number',
                        CreditCardType     => 'Visa',
                        CreditCardNumber   => '4561435600988217',
                        ExpMonth           => '01',
                        ExpYear            => '2007',
                        CVV2               => '123',
                        FirstName          => 'James',
                        LastName           => 'PuffDaddy',
                        Street1            => '1st Street LaCausa',
                        Street2            => '',
                        CityName           => 'La',
                        StateOrProvince    => 'Ca',
                        PostalCode         => '90210',
                        Country            => 'US',
                        Payer              => 'Joe@Example.org',
                        ShipToName         => 'Jane Doe',
                        ShipToStreet1      => '1234 S. Pleasant St.',
                        ShipToStreet2      => 'Suite #992',
                        ShipToCityName     => 'Vacation Town',
                        ShipToStateOrProvince => 'FL',
                        ShipToCountry      => 'US',
                        ShipToPostalCode   => '12345',
                        CurrencyID         => 'USD',
                        IPAddress          => '10.0.0.1',
                        MerchantSessionID  => '10113301',
                        );

=head1 DESCRIPTION

B<Business::PayPal::API::DirectPayments> implements PayPal's
B<DirectPayments> API using SOAP::Lite to make direct API calls to
PayPal's SOAP API server. It also implements support for testing via
PayPal's I<sandbox>. Please see L<Business::PayPal::API> for details
on using the PayPal sandbox.

=head2 DoDirectPaymentRequest

Implements PayPal's B<DoDirectPaymentRequest> API call. Supported
parameters include:

        PaymentAction           ( Sale|Authorize, Sale is default )
        OrderTotal
        TaxTotal
        ShippingTotal
        ItemTotal
        HandlingTotal
        InvoiceID
        CreditCardType
        CreditCardNumber
        ExpMonth                ( two digits, leading zero )
        ExpYear                 ( four digits, 20XX )
        CVV2
        FirstName
        LastName
        Street1
        Street2
        CityName
        StateOrProvince
        PostalCode
        Country
        Payer
        ShipToName
        ShipToStreet1
        ShipToStreet2
        ShipToCityName
        ShipToStateOrProvince
        ShipToCountry
        ShipToPostalCode
        CurrencyID              (USD is default)
        IPAddress
        MerchantSessionID

as described in the PayPal "Web Services API Reference" document.

Returns a hash containing the results of the transaction. The B<Ack>
element and TransactionID are the most useful return values.

Example:

  my %resp = $pp->DoDirectPaymentRequest(
                    PaymentAction => 'Sale',
                    OrderTotal    => '10.99',
                    ...
             );

  unless( $resp{Ack} !~ /Success/ ) {
      for my $error ( @{$response{Errors}} ) {
          warn "Error: " . $error->{LongMessage} . "\n";
      }
  }

=head2 ERROR HANDLING

See the B<ERROR HANDLING> section of B<Business::PayPal::API> for
information on handling errors.

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<https://developer.paypal.com/en_US/pdf/PP_APIReference.pdf>

=head1 AUTHORS

=over 4

=item *

Scott Wiersdorf <scott@perlcode.org>

=item *

Danny Hembree <danny@dynamical.org>

=item *

Bradley M. Kuhn <bkuhn@ebb.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006-2017 by Scott Wiersdorf, Danny Hembree, Bradley M. Kuhn.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: PayPal DirectPayments API

