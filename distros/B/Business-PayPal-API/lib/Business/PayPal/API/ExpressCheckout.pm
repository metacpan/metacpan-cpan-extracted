package Business::PayPal::API::ExpressCheckout;
$Business::PayPal::API::ExpressCheckout::VERSION = '0.76';
use 5.008001;
use strict;
use warnings;

use SOAP::Lite 0.67;
use Business::PayPal::API ();

our @ISA = qw(Business::PayPal::API);
our @EXPORT_OK
    = qw( SetExpressCheckout GetExpressCheckoutDetails DoExpressCheckoutPayment );

## if you specify an InvoiceID, PayPal seems to remember it and not
## allow you to bill twice with it.
sub SetExpressCheckout {
    my $self = shift;
    my %args = @_;

    my %types = (
        Token                     => 'ebl:ExpressCheckoutTokenType',
        OrderTotal                => 'cc:BasicAmountType',
        currencyID                => '',
        MaxAmount                 => 'cc:BasicAmountType',
        OrderDescription          => 'xs:string',
        Custom                    => 'xs:string',
        InvoiceID                 => 'xs:string',
        ReturnURL                 => 'xs:string',
        CancelURL                 => 'xs:string',
        Address                   => 'ebl:AddressType',
        ReqConfirmShipping        => 'xs:string',
        NoShipping                => 'xs:string',
        AddressOverride           => 'xs:string',
        LocaleCode                => 'xs:string',
        PageStyle                 => 'xs:string',
        'cpp-header-image'        => 'xs:string',
        'cpp-header-border-color' => 'xs:string',
        'cpp-header-back-color'   => 'xs:string',
        'cpp-payflow-color'       => 'xs:string',
        PaymentAction             => '',
        BuyerEmail                => 'ebl:EmailAddressType'
    );

    ## billing agreement details type
    my %badtypes = (
        BillingType                 => '',            #'ns:BillingCodeType',
        BillingAgreementDescription => 'xs:string',
        PaymentType => '',    #'ns:MerchantPullPaymentCodeType',
        BillingAgreementCustom => 'xs:string',
    );

    ## set some defaults
    $args{PaymentAction} ||= 'Sale';
    $args{currencyID}    ||= 'USD';
    my $currencyID = delete $args{currencyID};

    ## SetExpressCheckoutRequestDetails
    my @secrd = (
        SOAP::Data->name( OrderTotal => delete $args{OrderTotal} )
            ->type( $types{OrderTotal} )->attr(
            { currencyID => $currencyID, xmlns => $self->C_xmlns_ebay }
            ),
        SOAP::Data->name( ReturnURL => delete $args{ReturnURL} )
            ->type( $types{ReturnURL} ),
        SOAP::Data->name( CancelURL => delete $args{CancelURL} )
            ->type( $types{CancelURL} ),
    );

    ## add all the other fields
    for my $field ( keys %types ) {
        next unless defined $args{$field};

        if ( $field eq 'MaxAmount' ) {
            push @secrd,
                SOAP::Data->name( $field => $args{$field} )
                ->type( $types{$field} )
                ->attr(
                { currencyID => $currencyID, xmlns => $self->C_xmlns_ebay } );
        }
        elsif ( $field eq 'Address' ) {
            my $address       = $args{$field};
            my %address_types = (
                Name            => 'xs:string',
                Street1         => 'xs:string',
                Street2         => 'xs:string',
                CityName        => 'xs:string',
                StateOrProvince => 'xs:string',
                Country         => 'xs:string',
                PostalCode      => 'xs:string',
            );
            my @address;
            foreach my $k ( keys %address_types ) {
                if ( defined $address->{$k} ) {
                    push @address,
                        SOAP::Data->name( $k => $address->{$k} )
                        ->type( $address_types{$k} );
                }
            }
            if (@address) {
                push @secrd,
                    SOAP::Data->name( $field =>
                        \SOAP::Data->value(@address)->type( $types{$field} )
                        ->attr( { xmlns => $self->C_xmlns_ebay } ) );
            }
        }
        else {
            push @secrd,
                SOAP::Data->name( $field => $args{$field} )
                ->type( $types{$field} );
        }
    }

    my @btypes = ();
    for my $field ( keys %badtypes ) {
        next unless $args{$field};
        push @btypes,
            SOAP::Data->name( $field => $args{$field} )
            ->type( $badtypes{$field} );
    }
    push @secrd,
        SOAP::Data->name(
        BillingAgreementDetails => \SOAP::Data->value(@btypes) )
        if $args{'BillingType'};

    my $request = SOAP::Data->name(
        SetExpressCheckoutRequest => \SOAP::Data->value(
            $self->version_req,
            SOAP::Data->name(
                SetExpressCheckoutRequestDetails => \SOAP::Data->value(@secrd)
                )->attr( { xmlns => $self->C_xmlns_ebay } ),
        )
    )->type('ns:SetExpressCheckoutRequestType');

    my $som = $self->doCall( SetExpressCheckoutReq => $request )
        or return;

    my $path = '/Envelope/Body/SetExpressCheckoutResponse';

    my %response = ();
    unless ( $self->getBasic( $som, $path, \%response ) ) {
        $self->getErrors( $som, $path, \%response );
        return %response;
    }

    $self->getFields( $som, $path, \%response, { Token => 'Token' } );

    return %response;
}

sub GetExpressCheckoutDetails {
    my $self  = shift;
    my $token = shift;

    my $request = SOAP::Data->name(
        GetExpressCheckoutDetailsRequest => \SOAP::Data->value(
            $self->version_req,
            SOAP::Data->name( Token => $token )->type('xs:string')
                ->attr( { xmlns => $self->C_xmlns_ebay } ),
        )
    )->type('ns:GetExpressCheckoutRequestType');

    my $som = $self->doCall( GetExpressCheckoutDetailsReq => $request )
        or return;

    my $path = '/Envelope/Body/GetExpressCheckoutDetailsResponse';

    my %details = ();
    unless ( $self->getBasic( $som, $path, \%details ) ) {
        $self->getErrors( $som, $path, \%details );
        return %details;
    }

    $self->getFields(
        $som,
        "$path/GetExpressCheckoutDetailsResponseDetails",
        \%details,
        {
            Token           => 'Token',
            Custom          => 'Custom',
            InvoiceID       => 'InvoiceID',
            ContactPhone    => 'ContactPhone',
            Payer           => 'PayerInfo/Payer',
            PayerID         => 'PayerInfo/PayerID',
            PayerStatus     => 'PayerInfo/PayerStatus',
            Salutation      => 'PayerInfo/PayerName/Salutation',
            FirstName       => 'PayerInfo/PayerName/FirstName',
            MiddleName      => 'PayerInfo/PayerName/MiddleName',
            LastName        => 'PayerInfo/PayerName/LastName',
            NameSuffix      => 'PayerInfo/PayerName/Suffix',
            PayerBusiness   => 'PayerInfo/PayerBusiness',
            AddressStatus   => 'PayerInfo/Address/AddressStatus',
            Name            => 'PayerInfo/Address/Name',
            Street1         => 'PayerInfo/Address/Street1',
            Street2         => 'PayerInfo/Address/Street2',
            CityName        => 'PayerInfo/Address/CityName',
            StateOrProvince => 'PayerInfo/Address/StateOrProvince',
            PostalCode      => 'PayerInfo/Address/PostalCode',
            Country         => 'PayerInfo/Address/Country',
            PayerCountry    => 'PayerInfo/PayerCountry',
        }
    );

    return %details;
}

sub DoExpressCheckoutPayment {
    my $self = shift;
    my %args = @_;

    my %types = (
        Token            => 'xs:string',
        PaymentAction    => '',                 ## NOTA BENE!
        PayerID          => 'ebl:UserIDType',
        currencyID       => '',
        ReturnFMFDetails => 'xs:boolean',
    );

    ## PaymentDetails
    my %pd_types = (
        OrderTotal       => 'ebl:BasicAmountType',
        OrderDescription => 'xs:string',
        ItemTotal        => 'ebl:BasicAmountType',
        ShippingTotal    => 'ebl:BasicAmountType',
        HandlingTotal    => 'ebl:BasicAmountType',
        TaxTotal         => 'ebl:BasicAmountType',
        Custom           => 'xs:string',
        InvoiceID        => 'xs:string',
        ButtonSource     => 'xs:string',
        NotifyURL        => 'xs:string',
    );

    ## ShipToAddress
    my %st_types = (
        ST_Name            => 'xs:string',
        ST_Street1         => 'xs:string',
        ST_Street2         => 'xs:string',
        ST_CityName        => 'xs:string',
        ST_StateOrProvince => 'xs:string',
        ST_Country         => 'xs:string',
        ST_PostalCode      => 'xs:string',
    );

    ##PaymentDetailsItem
    my %pdi_types = (
        PDI_Name     => 'xs:string',
        PDI_Amount   => 'ebl:BasicAmountType',
        PDI_Number   => 'xs:string',
        PDI_Quantity => 'xs:string',
        PDI_Tax      => 'ebl:BasicAmountType',
    );

    $args{PaymentAction} ||= 'Sale';
    $args{currencyID}    ||= 'USD';

    my @payment_details = ();

    ## push OrderTotal here and delete it (i.e., and all others that have special attrs)
    push @payment_details,
        SOAP::Data->name( OrderTotal => $args{OrderTotal} )
        ->type( $pd_types{OrderTotal} )->attr(
        {
            currencyID => $args{currencyID},
            xmlns      => $self->C_xmlns_ebay
        }
        );

    ## don't process it again
    delete $pd_types{OrderTotal};

    for my $field ( keys %pd_types ) {
        if ( $args{$field} ) {
            push @payment_details,
                SOAP::Data->name( $field => $args{$field} )
                ->type( $pd_types{$field} );
        }
    }

    ##
    ## ShipToAddress
    ##
    my @ship_types = ();
    for my $field ( keys %st_types ) {
        if ( $args{$field} ) {
            ( my $name = $field ) =~ s/^ST_//;
            push @ship_types,
                SOAP::Data->name( $name => $args{$field} )
                ->type( $st_types{$field} );
        }
    }

    if ( scalar @ship_types ) {
        push @payment_details,
            SOAP::Data->name( ShipToAddress =>
                \SOAP::Data->value(@ship_types)->type('ebl:AddressType')
                ->attr( { xmlns => $self->C_xmlns_ebay } ), );
    }

    ##
    ## PaymentDetailsItem
    ##
    my @payment_details_item = ();
    for my $field ( keys %pdi_types ) {
        if ( $args{$field} ) {
            ( my $name = $field ) =~ s/^PDI_//;
            push @payment_details_item,
                SOAP::Data->name( $name => $args{$field} )
                ->type( $pdi_types{$field} );
        }
    }

    if ( scalar @payment_details_item ) {
        push @payment_details,
            SOAP::Data->name(
            PaymentDetailsItem => \SOAP::Data->value(@payment_details_item)
                ->type('ebl:PaymentDetailsItemType')
                ->attr( { xmlns => $self->C_xmlns_ebay } ), );
    }

    ##
    ## ExpressCheckoutPaymentDetails
    ##
    my @express_details = (
        SOAP::Data->name( Token => $args{Token} )->type( $types{Token} )
            ->attr( { xmlns => $self->C_xmlns_ebay } ),
        SOAP::Data->name( PaymentAction => $args{PaymentAction} )
            ->type( $types{PaymentAction} )
            ->attr( { xmlns => $self->C_xmlns_ebay } ),
        SOAP::Data->name( PayerID => $args{PayerID} )
            ->type( $types{PayerID} )
            ->attr( { xmlns => $self->C_xmlns_ebay } ),
        SOAP::Data->name(
            PaymentDetails => \SOAP::Data->value(@payment_details)
                ->type('ebl:PaymentDetailsType')
                ->attr( { xmlns => $self->C_xmlns_ebay } ),
        ),
        SOAP::Data->name( ReturnFMFDetails => $args{ReturnFMFDetails} )
            ->type( $types{ReturnFMFDetails} )
            ->attr( { xmlns => $self->C_xmlns_ebay } ),
    );

    ##
    ## the main request object
    ##
    my $request = SOAP::Data->name(
        DoExpressCheckoutPaymentRequest => \SOAP::Data->value(
            $self->version_req,
            SOAP::Data->name(
                DoExpressCheckoutPaymentRequestDetails =>
                    \SOAP::Data->value(@express_details)
                    ->type('ns:DoExpressCheckoutPaymentRequestDetailsType')
                )->attr( { xmlns => $self->C_xmlns_ebay } ),
        )
    );

    my $som = $self->doCall( DoExpressCheckoutPaymentReq => $request )
        or return;

    my $path = '/Envelope/Body/DoExpressCheckoutPaymentResponse';

    my %response = ();
    unless ( $self->getBasic( $som, $path, \%response ) ) {
        $self->getErrors( $som, $path, \%response );
        return %response;
    }

    $self->getFields(
        $som,
        "$path/DoExpressCheckoutPaymentResponseDetails",
        \%response,
        {
            Token                 => 'Token',
            BillingAgreementID    => 'BillingAgreementID',
            TransactionID         => 'PaymentInfo/TransactionID',
            TransactionType       => 'PaymentInfo/TransactionType',
            PaymentType           => 'PaymentInfo/PaymentType',
            PaymentDate           => 'PaymentInfo/PaymentDate',
            GrossAmount           => 'PaymentInfo/GrossAmount',
            FeeAmount             => 'PaymentInfo/FeeAmount',
            SettleAmount          => 'PaymentInfo/SettleAmount',
            TaxAmount             => 'PaymentInfo/TaxAmount',
            ExchangeRate          => 'PaymentInfo/ExchangeRate',
            PaymentStatus         => 'PaymentInfo/PaymentStatus',
            PendingReason         => 'PaymentInfo/PendingReason',
            AcceptFilters         => 'FMFDetails/AcceptFilters',
            DenyFilters           => 'FMFDetails/DenyFilters',
            PendingFilters        => 'FMFDetails/PendingFilters',
            ReportsFilters        => 'FMFDetails/ReportsFilters',
            ProtectionEligibility => 'PaymentInfo/ProtectionEligibility',
        }
    );

    return %response;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Business::PayPal::API::ExpressCheckout - PayPal Express Checkout API

=head1 VERSION

version 0.76

=head1 SYNOPSIS

  use Business::PayPal::API::ExpressCheckout;

  ## see Business::PayPal::API documentation for parameters
  my $pp = Business::PayPal::API::ExpressCheckout->new( ... );

  my %resp = $pp->SetExpressCheckout
               ( OrderTotal => '55.43',   ## defaults to USD
                 ReturnURL  => 'http://site.tld/return.html',
                 CancelURL  => 'http://site.tld/cancellation.html', );

  ... time passes, buyer validates the token with PayPal ...

  my %details = $pp->GetExpressCheckoutDetails($resp{Token});

  ## now ask PayPal to xfer the money
  my %payinfo = $pp->DoExpressCheckoutPayment( Token => $details{Token},
                                               PaymentAction => 'Sale',
                                               PayerID => $details{PayerID},
                                               OrderTotal => '55.43' );

=head1 DESCRIPTION

B<Business::PayPal::API::ExpressCheckout> implements PayPal's
B<Express Checkout API> using SOAP::Lite to make direct API calls to
PayPal's SOAP API server. It also implements support for testing via
PayPal's I<sandbox>. Please see L<Business::PayPal::API> for details
on using the PayPal sandbox.

=head2 SetExpressCheckout

Implements PayPal's "Website Payment Pro" B<SetExpressCheckout> API call. Supported
parameters include:

  Token
  OrderTotal
  currencyID
  MaxAmount
  OrderDescription
  Custom
  InvoiceID
  ReturnURL
  CancelURL
  Address
  ReqConfirmShipping
  NoShipping
  AddressOverride
  LocaleCode
  PageStyle
  'cpp-header-image'
  'cpp-header-border-color'
  'cpp-header-back-color'
  'cpp-payflow-color'
  PaymentAction
  BuyerEmail
  BillingType
  BillingAgreementDescription
  PaymentType
  BillingAgreementCustom

as described in the PayPal "Web Services API Reference" document. The
default currency setting is 'USD' if not otherwise specified.

Returns a hash containing a 'Token' key, whose value represents the
PayPal transaction token.

Required fields:

  OrderTotal, ReturnURL, CancelURL.

    my %resp = $pp->SetExpressCheckout();
    my $token = $resp{Token};

Example (courtesy Ollie Ready):

  my $address = {
        Name            =>      'Some Customer',
        Street1         =>      '888 Test St.',
        Street2         =>      'Suite 9',
        CityName        =>      'San Diego',
        StateOrProvince =>      'CA',
        PostalCode      =>      '92111',
        Country         =>      'US',
        Phone           =>      '123-123-1234',
  };

  my %response = $pp->SetExpressCheckout(
        OrderTotal      =>      '11.01',
        ReturnURL       =>      '<![CDATA[http://example.com/p?cmd=checkout]]>',
        CancelURL       =>      'http://example.com',
        PaymentAction   =>      'Authorization',
        AddressOverride =>      1,
        Address         =>      $address,
  );

=head2 GetExpressCheckoutDetails

Implements PayPal's WPP B<SetExpressCheckout> API call. Supported
parameters include:

  Token

as described in the PayPal "Web Services API Reference" document. This
is the same token you received from B<SetExpressCheckout>.

Returns a hash with the following keys:

  Token
  Custom
  InvoiceID
  ContactPhone
  Payer
  PayerID
  PayerStatus
  FirstName
  LastName
  PayerBusiness
  AddressStatus
  Name
  Street1
  Street2
  CityName
  StateOrProvince
  PostalCode
  Country

Required fields:

  Token

=head2 DoExpressCheckoutPayment

Implements PayPal's WPP B<SetExpressCheckout> API call. Supported
parameters include:

  Token
  PaymentAction (defaults to 'Sale' if not supplied)
  PayerID
  currencyID (defaults to 'USD' if not supplied)

  OrderTotal
  OrderDescription
  ItemTotal
  ShippingTotal
  HandlingTotal
  TaxTotal
  Custom
  InvoiceID
  ButtonSource
  NotifyURL

  ST_Name
  ST_Street1
  ST_Street2
  ST_CityName
  ST_StateOrProvince
  ST_Country
  ST_PostalCode

  PDI_Name
  PDI_Amount
  PDI_Number
  PDI_Quantity
  PDI_Tax

as described in the PayPal "Web Services API Reference" document.

Returns a hash with the following keys:

  Token
  TransactionID
  TransactionType
  PaymentType
  PaymentDate
  GrossAmount
  FeeAmount
  SettleAmount
  TaxAmount
  ExchangeRate
  PaymentStatus
  PendingReason
  BillingAgreementID (if BillingType 'MerchantInitiatedBilling'
                      was specified during SetExpressCheckout)

Required fields:

  Token, PayerID, OrderTotal

=head2 ERROR HANDLING

See the B<ERROR HANDLING> section of B<Business::PayPal::API> for
information on handling errors.

=head1 EXAMPLES

Andy Spiegl <paypalcheckout.Spiegl@kascada.com> has kindly donated
some example code (in German) which may be found in the F<eg>
directory of this archive. Additional code examples may be found in
the F<t> test directory.

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<SOAP::Lite>, L<Business::PayPal::API>,
L<https://www.paypal.com/IntegrationCenter/ic_expresscheckout.html>,
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

# ABSTRACT: PayPal Express Checkout API

