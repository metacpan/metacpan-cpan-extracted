package Business::PayPal::API::RecurringPayments;
$Business::PayPal::API::RecurringPayments::VERSION = '0.77';
use 5.008001;
use strict;
use warnings;

use SOAP::Lite 0.67;
use Business::PayPal::API ();

our @ISA       = qw(Business::PayPal::API);
our @EXPORT_OK = qw( SetCustomerBillingAgreement
    GetBillingAgreementCustomerDetails
    CreateRecurringPaymentsProfile
    DoReferenceTransaction);

our $API_VERSION = '50.0';

sub SetCustomerBillingAgreement {
    my $self = shift;
    my %args = @_;

    ## billing agreement details type
    my %badtypes = (
        BillingType                 => '',            # 'ns:BillingCodeType',
        BillingAgreementDescription => 'xs:string',
        PaymentType => '',    # 'ns:MerchantPullPaymentCodeType',
        BillingAgreementCustom => 'xs:string',
    );

    my %types = (
        BillingAgreementDetails   => 'ns:BillingAgreementDetailsType',
        ReturnURL                 => 'xs:string',
        CancelURL                 => 'xs:string',
        LocaleCode                => 'xs:string',
        PageStyle                 => 'xs:string',
        'cpp-header-image'        => 'xs:string',
        'cpp-header-border-color' => 'xs:string',
        'cpp-header-back-color'   => 'xs:string',
        'cpp-payflow-color'       => 'xs:string',
        PaymentAction             => '',
        BuyerEmail                => 'ns:EmailAddressType',
    );

    ## set defaults
    $args{BillingType} ||= 'RecurringPayments';
    $args{PaymentType} ||= 'InstantOnly';
    $args{currencyID}  ||= 'USD';

    my @btypes = ();
    for my $field ( keys %badtypes ) {
        next unless $args{$field};
        push @btypes,
            SOAP::Data->name( $field => $args{$field} )
            ->type( $badtypes{$field} );
    }

    my @scba = ();
    for my $field ( keys %types ) {
        next unless $args{$field};
        push @scba,
            SOAP::Data->name( $field => $args{$field} )
            ->type( $types{$field} );
    }
    push @scba,
        SOAP::Data->name(
        BillingAgreementDetails => \SOAP::Data->value(@btypes) );

    my $request = SOAP::Data->name(
        SetCustomerBillingAgreementRequest => \SOAP::Data->value(
            $self->version_req,    #$API_VERSION,
            SOAP::Data->name(
                SetCustomerBillingAgreementRequestDetails =>
                    \SOAP::Data->value(@scba)
                )->attr( { xmlns => $self->C_xmlns_ebay } ),
        )
    )->type('ns:SetCustomerBillingAgreementRequestDetailsType');

    my $som = $self->doCall( SetCustomerBillingAgreementReq => $request )
        or return;

    my $path = '/Envelope/Body/SetCustomerBillingAgreementResponse';

    my %response = ();
    unless ( $self->getBasic( $som, $path, \%response ) ) {
        $self->getErrors( $som, $path, \%response );
        return %response;
    }

    $self->getFields( $som, $path, \%response, { Token => 'Token' } );

    return %response;
}

sub GetBillingAgreementCustomerDetails {
    my $self  = shift;
    my $token = shift;

    my $request = SOAP::Data->name(
        GetBillingAgreementCustomerDetailsRequest => \SOAP::Data->value(
            $self->version_req,
            SOAP::Data->name( Token => $token )->type('xs:string')
                ->attr( { xmlns => $self->C_xmlns_ebay } ),
        )
    )->type('ns:GetBillingAgreementCustomerDetailsResponseType');

    my $som
        = $self->doCall( GetBillingAgreementCustomerDetailsReq => $request )
        or return;

    my $path = '/Envelope/Body/GetBillingAgreementCustomerDetailsResponse';

    my %details = ();
    unless ( $self->getBasic( $som, $path, \%details ) ) {
        $self->getErrors( $som, $path, \%details );
        return %details;
    }

    $self->getFields(
        $som,
        "$path/GetBillingAgreementCustomerDetailsResponseDetails",
        \%details,
        {
            Token => 'Token',

            Payer         => 'PayerInfo/Payer',
            PayerID       => 'PayerInfo/PayerID',
            PayerStatus   => 'PayerInfo/PayerStatus',     ## 'unverified'
            PayerBusiness => 'PayerInfo/PayerBusiness',

            Name            => 'PayerInfo/Address/Name',
            AddressOwner    => 'PayerInfo/Address/AddressOwner',   ## 'PayPal'
            AddressStatus   => 'PayerInfo/Address/AddressStatus',  ## 'none'
            Street1         => 'PayerInfo/Address/Street1',
            Street2         => 'PayerInfo/Address/Street2',
            StateOrProvince => 'PayerInfo/Address/StateOrProvince',
            PostalCode      => 'PayerInfo/Address/PostalCode',
            CountryName     => 'PayerInfo/Address/CountryName',

            Salutation => 'PayerInfo/PayerName/Salutation',
            FirstName  => 'PayerInfo/PayerName/FirstName',
            MiddleName => 'PayerInfo/PayerName/MiddleName',
            LastName   => 'PayerInfo/PayerName/LastName',
            Suffix     => 'PayerInfo/PayerName/Suffix',
        }
    );

    return %details;
}

sub CreateRecurringPaymentsProfile {
    my $self = shift;
    my %args = @_;

    ## RecurringPaymentProfileDetails
    my %profiledetailstype = (
        SubscriberName           => 'xs:string',
        SubscriberShipperAddress => 'ns:AddressType',
        BillingStartDate         => 'xs:dateTime',      ## MM-DD-YY
        ProfileReference         => 'xs:string',
    );

    ## ScheduleDetailsType
    my %schedtype = (
        Description               => 'xs:string',
        ActivationDetails         => 'ns:ActivationDetailsType',
        TrialPeriod               => 'ns:BillingPeriodDetailsType',
        PaymentPeriod             => 'ns:BillingPeriodDetailsType',
        MaxFailedPayments         => 'xs:int',
        AutoBillOutstandingAmount => 'ns:AutoBillType',
    );    ## NoAutoBill or AddToNextBilling

    ## activation details
    my %activationdetailstype = (
        InitialAmount             => 'cc:BasicAmountType',
        FailedInitialAmountAction => 'ns:FailedPaymentAction',
    );    ## ContinueOnFailure or CancelOnFailure

    ## BillingPeriodDetailsType
    my %trialbilltype = (
        TrialBillingPeriod      => 'xs:string',      ##'ns:BillingPeriodType',
        TrialBillingFrequency   => 'xs:int',
        TrialTotalBillingCycles => 'xs:int',
        TrialAmount             => 'cc:AmountType',
        TrialShippingAmount     => 'cc:AmountType',
        TrialTaxAmount          => 'cc:AmountType',
    );

    my %paymentbilltype = (
        PaymentBillingPeriod      => 'xs:string',    ##'ns:BillingPeriodType',
        PaymentBillingFrequency   => 'xs:int',
        PaymentTotalBillingCycles => 'xs:int',
        PaymentAmount             => 'cc:AmountType',
        PaymentShippingAmount     => 'cc:AmountType',
        PaymentTaxAmount          => 'cc:AmountType',
    );

    ## AddressType
    my %payaddrtype = (
        CCPayerName            => 'xs:string',
        CCPayerStreet1         => 'xs:string',
        CCPayerStreet2         => 'xs:string',
        CCPayerCityName        => 'xs:string',
        CCPayerStateOrProvince => 'xs:string',
        CCPayerCountry         => 'xs:string',    ## ebl:CountryCodeType
        CCPayerPostalCode      => 'xs:string',
        CCPayerPhone           => 'xs:string',
    );

    my %shipaddrtype = (
        SubscriberShipperName            => 'xs:string',
        SubscriberShipperStreet1         => 'xs:string',
        SubscriberShipperStreet2         => 'xs:string',
        SubscriberShipperCityName        => 'xs:string',
        SubscriberShipperStateOrProvince => 'xs:string',
        SubscriberShipperCountry    => 'xs:string',    ## ebl:CountryCodeType
        SubscriberShipperPostalCode => 'xs:string',
        SubscriberShipperPhone      => 'xs:string',
    );

    ## credit card payer
    my %payerinfotype = (
        CCPayer         => 'ns:EmailAddressType',
        CCPayerID       => 'ebl:UserIDType',
        CCPayerStatus   => 'xs:string',
        CCPayerName     => 'xs:string',
        CCPayerCountry  => 'xs:string',
        CCPayerPhone    => 'xs:string',
        CCPayerBusiness => 'xs:string',
        CCAddress       => 'xs:string',
    );

    ## credit card details
    my %creditcarddetailstype = (
        CardOwner      => 'ns:PayerInfoType',
        CreditCardType => 'ebl:CreditCardType'
        ,    ## Visa, MasterCard, Discover, Amex, Switch, Solo
        CreditCardNumber => 'xs:string',
        ExpMonth         => 'xs:int',
        ExpYear          => 'xs:int',
        CVV2             => 'xs:string',
        StartMonth       => 'xs:string',
        StartYear        => 'xs:string',
        IssueNumber      => 'xs:int',
    );

    ## this gets pushed onto scheduledetails
    my @activationdetailstype = ();
    for my $field ( keys %activationdetailstype ) {
        next unless exists $args{$field};
        my $real_field = $field;
        push @activationdetailstype,
            SOAP::Data->name( $real_field => $args{$field} )
            ->type( $activationdetailstype{$field} );
    }

    ## this gets pushed onto scheduledetails
    my @trialbilltype = ();
    for my $field ( keys %trialbilltype ) {
        next unless exists $args{$field};
        ( my $real_field = $field ) =~ s/^Trial//;
        push @trialbilltype,
            SOAP::Data->name( $real_field => $args{$field} )
            ->type( $trialbilltype{$field} );
    }

    ## this gets pushed onto scheduledetails
    my @paymentbilltype = ();
    for my $field ( keys %paymentbilltype ) {
        next unless exists $args{$field};
        ( my $real_field = $field ) =~ s/^Payment//;
        push @paymentbilltype,
            SOAP::Data->name( $real_field => $args{$field} )
            ->type( $paymentbilltype{$field} );
    }

    ## this gets pushed onto the top
    my @sched = ();
    for my $field ( keys %schedtype ) {
        next unless exists $args{$field};
        push @sched,
            SOAP::Data->name( $field => $args{$field} )
            ->type( $schedtype{$field} );
    }
    push @sched,
        SOAP::Data->name( TrialPeriod => \SOAP::Data->value(@trialbilltype) )
        ;    #->type( 'ns:BillingPeriodDetailsType' );
    push @sched,
        SOAP::Data->name(
        PaymentPeriod => \SOAP::Data->value(@paymentbilltype) )
        ;    #->type( 'ns:BillingPeriodDetailsType' );

    ## this gets pushed into profile details
    my @shipaddr = ();
    for my $field ( keys %shipaddrtype ) {
        next unless exists $args{$field};
        ( my $real_field = $field ) =~ s/^SubscriberShipper//;
        push @shipaddr,
            SOAP::Data->name( $real_field => $args{$field} )
            ->type( $shipaddrtype{$field} );
    }

    ## this gets pushed into payerinfo (from creditcarddetails)
    my @payeraddr = ();
    for my $field ( keys %payaddrtype ) {
        next unless $args{$field};
        ( my $real_field = $field ) =~ s/^CCPayer//;
        push @payeraddr,
            SOAP::Data->name( $real_field => $args{$field} )
            ->type( payaddrtype { $field } );
    }

    ## credit card type
    my @creditcarddetails = ();
    for my $field ( keys %creditcarddetailstype ) {
        next unless $args{$field};
        ( my $real_field = $field ) =~ s/^CC//;
        push @payeraddr,
            SOAP::Data->name( $real_field => $args{$field} )
            ->type( payaddrtype { $field } );
    }

    ## this gets pushed onto the top
    my @profdetail = ();
    for my $field ( keys %profiledetailstype ) {
        next unless exists $args{$field};
        push @profdetail,
            SOAP::Data->name( $field => $args{$field} )
            ->type( $profiledetailstype{$field} );
    }
    push @profdetail,
        SOAP::Data->name(
        SubscriberShipperAddress => \SOAP::Data->value(@shipaddr) );

    ## crappard?
    my @crpprd = ();
    push @crpprd, SOAP::Data->name( Token => $args{Token} );
    push @crpprd,
        SOAP::Data->name(
        CreditCardDetails => \SOAP::Data->value(@creditcarddetails) )
        ;    #->type( 'ns:CreditCardDetailsType' );
    push @crpprd,
        SOAP::Data->name(
        RecurringPaymentProfileDetails => \SOAP::Data->value(@profdetail) )
        ;    #->type( 'ns:RecurringPaymentProfileDetailsType' );
    push @crpprd,
        SOAP::Data->name( ScheduleDetails => \SOAP::Data->value(@sched) )
        ;    #->type( 'ns:ScheduleDetailsType' );

    my $request = SOAP::Data->name(
        CreateRecurringPaymentsProfileRequest => \SOAP::Data->value

            #        ( $API_VERSION,
            (
            $self->version_req,
            SOAP::Data->name(
                CreateRecurringPaymentsProfileRequestDetails =>
                    \SOAP::Data->value(@crpprd)
            )->attr( { xmlns => $self->C_xmlns_ebay } )
            )
    );    #->type( 'ns:CreateRecurringPaymentsProfileRequestType' );

    my $som = $self->doCall( CreateRecurringPaymentsProfileReq => $request )
        or return;

    my $path = '/Envelope/Body/CreateRecurringPaymentsProfileResponse';

    my %response = ();
    unless ( $self->getBasic( $som, $path, \%response ) ) {
        $self->getErrors( $som, $path, \%response );
        return %response;
    }

    $self->getFields( $som, $path, \%response, { Token => 'Token' } );

    return %response;
}

sub DoReferenceTransaction {
    my $self = shift;
    my %args = @_;

    my %types = (
        ReferenceID   => 'xs:string',
        PaymentAction => '',            ## NOTA BENE!
        currencyID    => '',
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
        ST_Phone           => 'xs:string',
    );

    ##PaymentDetailsItem
    my %pdi_types = (
        PDI_Name        => 'xs:string',
        PDI_Description => 'xs:string',
        PDI_Amount      => 'ebl:BasicAmountType',
        PDI_Number      => 'xs:string',
        PDI_Quantity    => 'xs:string',
        PDI_Tax         => 'ebl:BasicAmountType',
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
    ## ReferenceTransactionPaymentDetails
    ##
    my @reference_details = (
        SOAP::Data->name( ReferenceID => $args{ReferenceID} )
            ->type( $types{ReferenceID} )
            ->attr( { xmlns => $self->C_xmlns_ebay } ),
        SOAP::Data->name( PaymentAction => $args{PaymentAction} )
            ->type( $types{PaymentAction} )
            ->attr( { xmlns => $self->C_xmlns_ebay } ),
        SOAP::Data->name(
            PaymentDetails => \SOAP::Data->value(@payment_details)
                ->type('ebl:PaymentDetailsType')
                ->attr( { xmlns => $self->C_xmlns_ebay } ),
        ),
    );

    ##
    ## the main request object
    ##
    my $request = SOAP::Data->name(
        DoReferenceTransactionRequest => \SOAP::Data->value(
            $self->version_req,
            SOAP::Data->name(
                DoReferenceTransactionRequestDetails =>
                    \SOAP::Data->value(@reference_details)
                    ->type('ns:DoReferenceTransactionRequestDetailsType')
                )->attr( { xmlns => $self->C_xmlns_ebay } ),
        )
    );

    my $som = $self->doCall( DoReferenceTransactionReq => $request )
        or return;

    my $path = '/Envelope/Body/DoReferenceTransactionResponse';

    my %response = ();
    unless ( $self->getBasic( $som, $path, \%response ) ) {
        $self->getErrors( $som, $path, \%response );
        return %response;
    }

    $self->getFields(
        $som,
        "$path/DoReferenceTransactionResponseDetails",
        \%response,
        {
            BillingAgreementID => 'BillingAgreementID',
            TransactionID      => 'PaymentInfo/TransactionID',
            TransactionType    => 'PaymentInfo/TransactionType',
            PaymentType        => 'PaymentInfo/PaymentType',
            PaymentDate        => 'PaymentInfo/PaymentDate',
            GrossAmount        => 'PaymentInfo/GrossAmount',
            FeeAmount          => 'PaymentInfo/FeeAmount',
            SettleAmount       => 'PaymentInfo/SettleAmount',
            TaxAmount          => 'PaymentInfo/TaxAmount',
            ExchangeRate       => 'PaymentInfo/ExchangeRate',
            PaymentStatus      => 'PaymentInfo/PaymentStatus',
            PendingReason      => 'PaymentInfo/PendingReason',
            ReasonCode         => 'PaymentInfor/ReasonCode',
        }
    );

    return %response;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Business::PayPal::API::RecurringPayments - PayPal RecurringPayments API

=head1 VERSION

version 0.77

=head1 SYNOPSIS

    use Business::PayPal::API::RecurringPayments;

    my $pp = Business::PayPal::API::RecurringPayments->new( ... );

    my %resp = $pp->FIXME

    # Ask PayPal to charge a new transaction from the ReferenceID
    # This method is used both for Recurring Transactions as well
    # as for Express Checkout's MerchantInitiatedBilling, where
    # ReferenceID is the BillingAgreementID returned from
    # ExpressCheckout->DoExpressCheckoutPayment

    my %payinfo = $pp->DoReferenceTransaction(
        ReferenceID   => $details{ReferenceID},
        PaymentAction => 'Sale',
        OrderTotal    => '55.43'
    );

=head1 DESCRIPTION

THIS MODULE IS NOT COMPLETE YET. PLEASE DO NOT REPORT ANY BUGS RELATED
TO IT.

=head2 DoReferenceTransaction

Implements PayPal's WPP B<DoReferenceTransaction> API call. Supported
parameters include:

  ReferenceID (aka BillingAgreementID)
  PaymentAction (defaults to 'Sale' if not supplied)
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
  ST_Phone

  PDI_Name
  PDI_Description
  PDI_Amount
  PDI_Number
  PDI_Quantity
  PDI_Tax

as described in the PayPal "Web Services API Reference" document.

Returns a hash with the following keys:

  BillingAgreementID
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
  ReasonCode

Required fields:

  ReferenceID, OrderTotal

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

# ABSTRACT: PayPal RecurringPayments API

