package Business::OnlinePayment::Litle;


use warnings;
use strict;

use Business::OnlinePayment;
use Business::OnlinePayment::HTTPS;
use Business::OnlinePayment::Litle::ErrorCodes '%ERRORS';
use vars qw(@ISA $me $DEBUG);
use MIME::Base64;
use HTTP::Tiny;
use XML::Writer;
use XML::Simple;
use Tie::IxHash;
use Business::CreditCard qw(cardtype);
use Data::Dumper;
use IO::String;
use Carp qw(croak);
use Log::Scrubber qw(disable $SCRUBBER scrubber :Carp scrubber_add_scrubber);

@ISA     = qw(Business::OnlinePayment::HTTPS);
$me      = 'Business::OnlinePayment::Litle';
$DEBUG   = 0;
our $VERSION = '0.958'; # VERSION

# PODNAME: Business::OnlinePayment::Litle

# ABSTRACT: Business::OnlinePayment::Litle - Vantiv (was Litle & Co.) Backend for Business::OnlinePayment


sub server_request {
    my ( $self, $val, $tf ) = @_;
    if ($val) {
        $self->{server_request} = scrubber $val;
        $self->server_request_dangerous($val,1) unless $tf;
    }
    return $self->{server_request};
}


sub server_request_dangerous {
    my ( $self, $val, $tf ) = @_;
    if ($val) {
        $self->{server_request_dangerous} = $val;
        $self->server_request($val,1) unless $tf;
    }
    return $self->{server_request_dangerous};
}


sub server_response {
    my ( $self, $val, $tf ) = @_;
    if ($val) {
        $self->{server_response} = scrubber $val;
        $self->server_response_dangerous($val,1) unless $tf;
    }
    return $self->{server_response};
}


sub server_response_dangerous {
    my ( $self, $val, $tf ) = @_;
    if ($val) {
        $self->{server_response_dangerous} = $val;
        $self->server_response($val,1) unless $tf;
    }
    return $self->{server_response_dangerous};
}



sub _info {
    return {
        info_compat       => '0.01',
        gateway_name      => 'Litle',
        gateway_url       => 'http://www.vantiv.com',
        module_version    => $VERSION,
        supported_types   => ['CC'],
        supported_actions => {
            CC => [
                'Normal Authorization',
                'Post Authorization',
                'Authorization Only',
                'Credit',
                'Void',
                'Auth Reversal',
            ],
        },
    };
}


sub set_defaults {
    my $self = shift;
    my %opts = @_;

    $self->build_subs(
        qw( order_number md5 avs_code cvv2_response card_token
          cavv_response api_version xmlns failure_status batch_api_version chargeback_api_version
          is_prepaid prepaid_balance get_affluence chargeback_server chargeback_port chargeback_path
          verify_SSL phoenixTxnId is_duplicate card_token card_token_response card_token_message
          )
    );

    $self->test_transaction(0);

    if ( $opts{debug} ) {
        $self->debug( $opts{debug} );
        delete $opts{debug};
    }

    ## load in the defaults
    my %_defaults = ();
    foreach my $key ( keys %opts ) {
        $key =~ /^default_(\w*)$/ or next;
        $_defaults{$1} = $opts{$key};
        delete $opts{$key};
    }

    $self->{_scrubber} = \&_default_scrubber;
    if( defined $_defaults{'Scrubber'} ) {
        my $code = $_defaults{'Scrubber'};
        if( ref($code) ne 'CODE' ) {
            warn('default_Scrubber is not a code ref');
        }
        else {
            $self->{_scrubber} = $code;
        }
    }

    $self->api_version('11.0')                   unless $self->api_version;
    $self->batch_api_version('11.0')             unless $self->batch_api_version;
    $self->chargeback_api_version('2.2')        unless $self->chargeback_api_version;
    $self->xmlns('http://www.litle.com/schema') unless $self->xmlns;
}


sub test_transaction {
    my $self = shift;
    my $testMode = shift;
    if (! defined $testMode) { $testMode = $self->{'test_transaction'} || 0; }

    if (lc($testMode) eq 'sandbox') {
    $self->{'test_transaction'} = 'sandbox';
        $self->verify_SSL(0);

        $self->server('www.testvantivcnp.com');
        $self->port('443');
        $self->path('/sandbox/communicator/online');

        $self->chargeback_server('services.vantivpostlive.com'); # no sandbox exists, so fallback to certify
        $self->chargeback_port('443');
        $self->chargeback_path('/services/communicator/chargebacks/webCommunicator');
    } elsif (lc($testMode) eq 'localhost') {
        # this allows the user to create a local web server to do generic testing with
    $self->{'test_transaction'} = 'localhost';
        $self->verify_SSL(0);

        $self->server('localhost');
        $self->port('443');
        $self->path('/sandbox/communicator/online');

        $self->chargeback_server('localhost');
        $self->chargeback_port('443');
        $self->chargeback_path('/services/communicator/chargebacks/webCommunicator');
    } elsif (lc($testMode) eq 'prelive') {
    $self->{'test_transaction'} = $testMode;
        $self->verify_SSL(0);

        $self->server('payments.vantivprelive.com');
        $self->port('443');
        $self->path('/vap/communicator/online');

        $self->chargeback_server('services.vantivprelive.com');
        $self->chargeback_port('443');
        $self->chargeback_path('/services/communicator/chargebacks/webCommunicator');
    } elsif ($testMode) {
    $self->{'test_transaction'} = $testMode;
        $self->verify_SSL(0);

        $self->server('payments.vantivpostlive.com');
        $self->port('443');
        $self->path('/vap/communicator/online');

        $self->chargeback_server('services.vantivpostlive.com');
        $self->chargeback_port('443');
        $self->chargeback_path('/services/communicator/chargebacks/webCommunicator');
    } else {
    $self->{'test_transaction'} = 0;
        $self->verify_SSL(1);

        $self->server('payments.vantivcnp.com');
        $self->port('443');
        $self->path('/vap/communicator/online');

        $self->chargeback_server('services.vantivcnp.com');
        $self->chargeback_port('443');
        $self->chargeback_path('/services/communicator/chargebacks/webCommunicator');
    }

    return $self->{'test_transaction'};
}


sub map_fields {
    my ( $self, $content ) = @_;

    my $action  = lc( $content->{'action'} );
    my %actions = (
        'normal authorization' => 'sale',
        'authorization only'   => 'authorization',
        'post authorization'   => 'capture',
        'void'                 => 'void',
        'credit'               => 'credit',
        'auth reversal'        => 'authReversal',
        'account update'       => 'accountUpdate',
        'tokenize'             => 'registerTokenRequest',
        'force capture'        => 'force_capture',

        # AVS ONLY
        # Capture Given
        #
    );
    $content->{'TransactionType'} = $actions{$action} || $action;

    my $type_translate = {
        'VISA card'                   => 'VI',
        'MasterCard'                  => 'MC',
        'Discover card'               => 'DI',
        'American Express card'       => 'AX',
        'Diner\'s Club/Carte Blanche' => 'DI',
        'JCB'                         => 'DI',
        'China Union Pay'             => 'DI',
    };

    $content->{'card_type'} =
         $type_translate->{ cardtype( $content->{'card_number'} ) }
      || $content->{'type'} if $content->{'card_number'};

    if (   $content->{recurring_billing}
        && $content->{recurring_billing} eq 'YES' )
    {
        $content->{'orderSource'} = 'recurring';
    }
    else {
        $content->{'orderSource'} = 'ecommerce';
    }
    $content->{'customerType'} =
      $content->{'orderSource'} eq 'recurring'
      ? 'Existing'
      : 'New';    # new/Existing

    $content->{'deliverytype'} = 'SVC';

    # stuff it back into %content
    if ( $content->{'products'} && ref( $content->{'products'} ) eq 'ARRAY' ) {
        my $count = 1;
        foreach ( @{ $content->{'products'} } ) {
            $_->{'itemSequenceNumber'} = $count++;
        }
    }

    if( $content->{'velocity_check'} && (
        $content->{'velocity_check'} != 0
        && $content->{'velocity_check'} !~ m/false/i ) ) {
      $content->{'velocity_check'} = 'true';
    } else {
      $content->{'velocity_check'} = 'false';
    }

    if( $content->{'partial_auth'} && (
        $content->{'partial_auth'} != 0
        && $content->{'partial_auth'} !~ m/false/i ) ) {
      $content->{'partial_auth'} = 'true';
    } else {
      $content->{'partial_auth'} = 'false';
    }

    $self->content( %{$content} );
    return $content;
}


sub format_misc_field {
    my ($self, $content, $trunc) = @_;

    if( defined $content->{ $trunc->[0] } ) {
      utf8::upgrade($content->{ $trunc->[0] });
      my $len = length( $content->{ $trunc->[0] } );
      if ( $trunc->[3] && $trunc->[2] && $len != 0 && $len < $trunc->[2] ) {
        # Zero is a valid length (mostly for cvv2 value)
        croak "$trunc->[0] has too few characters";
      }
      elsif ( $trunc->[3] && $trunc->[1] && $len > $trunc->[1] ) {
        croak "$trunc->[0] has too many characters";
      }
      $content->{ $trunc->[0] } = substr($content->{ $trunc->[0] } , 0, $trunc->[1] );
      #warn "$trunc->[0] => $len => $content->{ $trunc->[0] }\n" if $DEBUG;
    }
    elsif ( $trunc->[4] ) {
      croak "$trunc->[0] is required";
    }
}


sub format_amount_field {
    my ($self, $data, $field) = @_;
    if (defined ( $data->{$field} ) ) {
        $data->{$field} = sprintf( "%.2f", $data->{$field} );
        $data->{$field} =~ s/\.//g;
    }
}


sub format_phone_field {
    my ($self, $data, $field) = @_;
    if (defined ( $data->{$field} ) ) {
        my $convertPhone = {
            'a' => 2, 'b' => 2, 'c' => 2,
            'd' => 3, 'e' => 3, 'f' => 3,
            'g' => 4, 'h' => 4, 'i' => 4,
            'j' => 5, 'k' => 5, 'l' => 5,
            'm' => 6, 'n' => 6, 'o' => 6,
            'p' => 7, 'q' => 7, 'r' => 7, 's' => 7,
            't' => 8, 'u' => 8, 'v' => 8,
            'w' => 9, 'x' => 9, 'y' => 9, 'z' => 9,
        };
        $data->{$field} =~ s/(\D)/$$convertPhone{lc($1)}||''/eg;
    }
}


sub map_request {
    my ( $self, $content ) = @_;

    $self->map_fields($content);

    my $action = $content->{'TransactionType'};

    my @required_fields = qw(action type);

    $self->required_fields(@required_fields);

    # for tabbing
    # set dollar amounts to the required format (eg $5.00 should be 500)
    foreach my $field ( 'amount', 'salesTax', 'discountAmount', 'shippingAmount', 'dutyAmount' ) {
        $self->format_amount_field($content, $field);
    }

    # make sure the date is in MMYY format
    $content->{'expiration'} =~ s/^(\d{1,2})\D*\d*?(\d{2})$/$1$2/;

    if ( ! defined $content->{'description'} ) { $content->{'description'} = ''; } # schema req
    $content->{'description'} =~ s/[^\w\s\*\,\-\'\#\&\.]//g;

    # Litle pre 0.934 used token, however BOP likes card_token
    $content->{'card_token'} = $content->{'token'} if ! defined $content->{'card_token'} && defined $content->{'card_token'};

    # only numbers are allowed in company_phone
    $self->format_phone_field($content, 'company_phone');

    $content->{'invoice_number_length_15'} ||= $content->{'invoice_number'}; # orderId = 25, invoiceReferenceNumber = 15

    #  put in a list of constraints
    my @validate = (
      # field,     maxLen, minLen, errorOnLength, isRequired
      [ 'name',       100,      0,             0, 0 ],
      [ 'email',      100,      0,             0, 0 ],
      [ 'address',     35,      0,             0, 0 ],
      [ 'city',        35,      0,             0, 0 ],
      [ 'state',       30,      0,             0, 0 ], # 30 is allowed, but it should be the 2 char code
      [ 'zip',         20,      0,             0, 0 ],
      [ 'country',      3,      0,             0, 0 ], # should use iso 3166-1 2 char code
      [ 'phone',       20,      0,             0, 0 ],

      [ 'ship_name',  100,      0,             0, 0 ],
      [ 'ship_email', 100,      0,             0, 0 ],
      [ 'ship_address',35,      0,             0, 0 ],
      [ 'ship_city',   35,      0,             0, 0 ],
      [ 'ship_state',  30,      0,             0, 0 ], # 30 is allowed, but it should be the 2 char code
      [ 'ship_zip',    20,      0,             0, 0 ],
      [ 'ship_country', 3,      0,             0, 0 ], # should use iso 3166-1 2 char code
      [ 'ship_phone',  20,      0,             0, 0 ],

      #[ 'customerType',13,      0,             0, 0 ],

      ['company_phone',13,      0,             0, 0 ],
      [ 'description', 25,      0,             0, 0 ],

      [ 'po_number',   17,      0,             0, 0 ],
      [ 'salestax',     8,      0,             1, 0 ],
      [ 'discount',     8,      0,             1, 0 ],
      [ 'shipping',     8,      0,             1, 0 ],
      [ 'duty',         8,      0,             1, 0 ],
      ['invoice_number',25,     0,             0, 0 ],
      ['invoice_number_length_15',15,0,        0, 0 ],
      [ 'orderdate',   10,      0,             0, 0 ], # YYYY-MM-DD

      [ 'recycle_by',   8,      0,             0, 0 ],
      [ 'recycle_id',  25,      0,             0, 0 ],

      [ 'affiliate',   25,      0,             0, 0 ],

      [ 'card_type',    2,      2,             1, 0 ],
      [ 'card_number', 25,     13,             1, 0 ],
      [ 'expiration',   4,      4,             1, 0 ], # MMYY
      [ 'cvv2',         4,      3,             1, 0 ],
      # 'card_token' does not have a documented limit

      [ 'customer_id', 25,      0,             0, 0 ],
    );
    foreach my $trunc ( @validate ) {
      $self->format_misc_field($content,$trunc);
      #warn "$trunc->[0] => ".($content->{ $trunc->[0] }||'')."\n" if $DEBUG;
    }

    tie my %customer_info, 'Tie::IxHash', $self->_revmap_fields(
        content                  => $content,
        ssn                      => 'ssn',
        dob                      => 'dob',
        customerRegistrationDate => 'registration_date',
        customerType             => 'customer_type',
        incomeAmount             => 'income_amount',
        incomeCurrency           => 'income_currency',
        employerName             => 'employer_name',
        customerWorkTelephone    => 'work_phone',
        residenceStatus          => 'residence_status',
        yearsAtResidence         => 'residence_years',
        yearsAtEmployer          => 'employer_years',
    );

    tie my %billToAddress, 'Tie::IxHash', $self->_revmap_fields(
        content      => $content,
        name         => 'name',
        email        => 'email',
        addressLine1 => 'address',
        city         => 'city',
        state        => 'state',
        zip          => 'zip',
        country      => 'country'
        , #TODO: will require validation to the spec, this field wont' work as is
        phone => 'phone',
    );

    tie my %shipToAddress, 'Tie::IxHash', $self->_revmap_fields(
        content      => $content,
        name         => 'ship_name',
        addressLine1 => 'ship_address',
        addressLine2 => 'ship_address2',
        addressLine3 => 'ship_address3',
        city         => 'ship_city',
        state        => 'ship_state',
        zip          => 'ship_zip',
        country      => 'ship_country'
        , #TODO: will require validation to the spec, this field wont' work as is
        email        => 'ship_email',
        phone => 'ship_phone',
    );

    tie my %customerinfo, 'Tie::IxHash',
      $self->_revmap_fields(
        content      => $content,
        customerType => 'customerType',
      );

    tie my %custombilling, 'Tie::IxHash',
      $self->_revmap_fields(
        content    => $content,
        phone      => 'company_phone',
        descriptor => 'description',
        #url        => 'url',
      );

    ## loop through product list and generate lineItemData for each
    #
    my @products = ();
    if( defined $content->{'products'} && scalar( @{ $content->{'products'} } ) < 100 ){
      foreach my $prodOrig ( @{ $content->{'products'} } ) {
          # use a local copy of prod so that we do not have issues if they try to submit more then once.
          my %prod = %$prodOrig;
          foreach my $field ( 'tax','amount','totalwithtax','discount' ) {
            # Note: DO NOT format 'cost', it uses the decimal format
            $self->format_amount_field(\%prod, $field);
          }

          my @validate = (
            # field,     maxLen, minLen, errorOnLength, isRequired
            [ 'description', 26,      0,             0, 0 ],
            [ 'tax',          8,      0,             1, 0 ],
            [ 'amount',       8,      0,             1, 0 ],
            [ 'totalwithtax', 8,      0,             1, 0 ],
            [ 'discount',     8,      0,             1, 0 ],
            [ 'code',        12,      0,             0, 0 ],
            [ 'cost',        12,      0,             1, 0 ],
          );
          foreach my $trunc ( @validate ) { $self->format_misc_field(\%prod,$trunc); }

          tie my %lineitem, 'Tie::IxHash',
            $self->_revmap_fields(
              content              => \%prod,
              itemSequenceNumber   => 'itemSequenceNumber',
              itemDescription      => 'description',
              productCode          => 'code',
              quantity             => 'quantity',
              unitOfMeasure        => 'units',
              taxAmount            => 'tax',
              lineItemTotal        => 'amount',
              lineItemTotalWithTax => 'totalwithtax',
              itemDiscountAmount   => 'discount',
              commodityCode        => 'code',
              unitCost             => 'cost', # This "amount" field uses decimals
            );
          push @products, \%lineitem;
      }
    }

    tie my %filtering, 'Tie::IxHash', $self->_revmap_fields(
        content                  => $content,
        prepaid       => 'filter_prepaid',
        international => 'filter_international',
        chargeback    => 'filter_chargeback',
    );

    tie my %healthcaresub, 'Tie::IxHash', $self->_revmap_fields(
        content                  => $content,
        totalHealthcareAmount => 'amount_healthcare',
        RxAmount          => 'amount_medications',
        visionAmount      => 'amount_vision',
        clinicOtherAmount => 'amount_clinic',
        dentalAmount      => 'amount_dental',
    );

    tie my %healthcare, 'Tie::IxHash', $self->_revmap_fields(
        content                  => $content,
        healthcareAmounts => \%healthcaresub,
        IIASFlag          => 'healthcare_flag',
    );

    tie my %amexaggregator, 'Tie::IxHash', $self->_revmap_fields(
        content                  => $content,
        sellerId                   => 'amex_seller_id',
        sellerMerchantCategoryCode => 'amex_merch_code',
    );

    tie my %detailtax, 'Tie::IxHash', $self->_revmap_fields(
        content                  => $content,
        taxIncludedInTotal => 'tax_in_total',
        taxAmount          => 'tax_amount',
        taxRate            => 'tax_rate',
        taxTypeIdentifier  => 'tax_type',
        cardAcceptorTaxId  => 'tax_id',
    );
    #
    #
    tie my %enhanceddata, 'Tie::IxHash', $self->_revmap_fields(
        content                => $content,
        customerReference      => 'po_number',
        salesTax               => 'salestax',
        deliveryType           => 'deliverytype',
        taxExempt              => 'tax_exempt',
        discountAmount         => 'discount',
        shippingAmount         => 'shipping',
        dutyAmount             => 'duty',
        shipFromPostalCode     => 'company_zip',
        destinationPostalCode  => 'ship_zip',
        destinationCountryCode => 'ship_country',
        invoiceReferenceNumber => 'invoice_number_length_15',
        orderDate              => 'orderdate',
        detailTax              => \%detailtax,
        lineItemData           => \@products,
    );

    tie my %card, 'Tie::IxHash', $self->_revmap_fields(
        content           => $content,
        type              => 'card_type',
        number            => 'card_number',
        expDate           => 'expiration',
        cardValidationNum => 'cvv2',
        pin               => 'pin',
    );

    tie my %token, 'Tie::IxHash', $self->_revmap_fields(
        content            => $content,
        litleToken         => 'card_token',
        expDate            => 'expiration',
        cardValidationNum  => 'cvv2',
    );

    tie my %sepadirect, 'Tie::IxHash', $self->_revmap_fields(
        content              => $content,
        mandateProvider      => 'sepa_mandate_provider',
        sequenceType         => 'sepa_sequence_type',
        mandateReference     => 'sepa_mandate_reference',
        mandateUrl           => 'sepa_mandate_url',
        mandateSignatureDate => 'sepa_mandate_signature_date',
        iban                 => 'sepa_iban',
        preferredLanguage    => 'sepa_language',
    );
    
    tie my %ideal, 'Tie::IxHash', $self->_revmap_fields(
        content           => $content,
        preferredLanguage => 'ideal_language',
    );

    tie my %processing, 'Tie::IxHash', $self->_revmap_fields(
        content               => $content,
        bypassVelocityCheck   => 'velocity_check',
    );

    tie my %pos, 'Tie::IxHash', $self->_revmap_fields(
        content                  => $content,
        capability   => 'pos_capability',
        entryMode    => 'pos_entry_mode',
        cardholderId => 'pos_cardholder_id',
        terminalId   => 'pos_terminal_id',
        catLevel     => 'pos_cat_level',
        #For CAT (Cardholder Activated Terminal) transactions, the capability element must be set to magstripe, the cardholderId element must be set to nopin, and the catLevel element must be set to self service.
    );

    tie my %cardholderauth, 'Tie::IxHash',
      $self->_revmap_fields(
        content                     => $content,
        authenticationValue         => '3ds',
        authenticationTransactionId => 'visaverified',
        customerIpAddress           => 'ip',
        authenticatedByMerchant     => 'authenticated',
      );

    tie my %merchantdata, 'Tie::IxHash',
      $self->_revmap_fields(
        content            => $content,
        affiliate          => 'affiliate',
        merchantGroupingId => 'merchant_grouping_id',
      );

    tie my %recyclingrequest, 'Tie::IxHash',
      $self->_revmap_fields(
        content      => $content,
        recycleBy    => 'recycle_by',
        recycleId    => 'recycle_id',
      );

    tie my %recurringRequest, 'Tie::IxHash',
      $self->_revmap_fields(
        content          => $content,
        planCode         => 'recurring_plan_code',
        numberOfPayments => 'recurring_number_of_payments',
        startDate        => 'recurring_start_date',
        amount           => 'recurring_amount',
      );
    
      tie my %advancedfraud, 'Tie::IxHash',
      $self->_revmap_fields(
        content               => $content,
        threatMetrixSessionId => 'threatMetrixSessionId',
        customAttribute1      => 'advanced_fraud_customAttribute1',
        customAttribute2      => 'advanced_fraud_customAttribute2',
        customAttribute3      => 'advanced_fraud_customAttribute3',
        customAttribute4      => 'advanced_fraud_customAttribute4',
        customAttribute5      => 'advanced_fraud_customAttribute5',
      );

    tie my %wallet, 'Tie::IxHash',
      $self->_revmap_fields(
        content            => $content,
        walletSourceType   => 'wallet_source_type',
        walletSourceTypeId => 'wallet_source_type_id',
      );

    my %req;

    if ( $action eq 'registerTokenRequest' ) {
        croak 'missing card_number' if length($content->{'card_number'} || '') == 0;
        tie %req, 'Tie::IxHash', $self->_revmap_fields(
            content                      => $content,
            orderId                      => 'invoice_number',
            accountNumber                => 'card_number',
        );
    }
    elsif ( $action eq 'sale' ) {
        croak 'missing card_token or card_number' if length($content->{'card_number'} || $content->{'card_token'} || '') == 0;
        tie %req, 'Tie::IxHash', $self->_revmap_fields(
            content                      => $content,
            orderId                      => 'invoice_number',
            amount                       => 'amount',
            secondaryAmount              => 'secondary_amount',
            orderSource                  => 'orderSource',
            customerInfo                 => \%customer_info, # PP only
            billToAddress                => \%billToAddress,
            shipToAddress                => \%shipToAddress,
            card                         => $content->{'card_number'} ? \%card : {},
            token                        => $content->{'card_token'} ? \%token : {},
            #[<card>|<paypage>|<token>|<paypal>|<mpos>|<applepay>|
            #<sepaDirectDebit>|<ideal>] (Choice)
            sepaDirectDebit              => \%sepadirect,
            ideal                        => \%ideal,
            cardholderAuthentication     => \%cardholderauth,
            customBilling                => \%custombilling,
            taxType                      => 'tax_type',      # payment|fee
            enhancedData                 => \%enhanceddata,
            processingInstructions       => \%processing,
            amexAggregatorData           => \%amexaggregator,
            allowPartialAuth             => 'partial_auth',
            healthcareIIAS               => \%healthcare,
            filtering                    => \%filtering,
            merchantData                 => \%merchantdata,
            recyclingRequest             => \%recyclingrequest,
            fraudFilterOverride          => 'filter_fraud_override',
            recurringRequest             => \%recurringRequest,
            debtRepayment                => 'debt_repayment',
            advancedFraudChecks          => \%advancedfraud,
            wallet                       => \%wallet,
            processingType               => 'processing_type',
            originalNetworkTransactionId => 'original_network_transaction_id',
            originalTransactionAmount    => 'original_transaction_amount',
        );
    }
    elsif ( $action eq 'authorization' ) {
        croak 'missing card_token or card_number' if length($content->{'card_number'} || $content->{'card_token'} || '') == 0;
        tie %req, 'Tie::IxHash', $self->_revmap_fields(
            content                      => $content,
            orderId                      => 'invoice_number',
            amount                       => 'amount',
            secondaryAmount              => 'secondary_amount',
            orderSource                  => 'orderSource',
            customerInfo                 => \%customer_info, #  PP only
            billToAddress                => \%billToAddress,
            shipToAddress                => \%shipToAddress,
            card                         => $content->{'card_number'} ? \%card : {},
            token                        => $content->{'card_token'} ? \%token : {},

            cardholderAuthentication     => \%cardholderauth,
            processingInstructions       => \%processing,
            pos                          => \%pos,
            customBilling                => \%custombilling,
            taxType                      => 'tax_type', # payment|fee
            enhancedData                 => \%enhanceddata,
            amexAggregatorData           => \%amexaggregator,
            allowPartialAuth             => 'partial_auth',
            healthcareIIAS               => \%healthcare,
            filtering                    => \%filtering,
            merchantData                 => \%merchantdata,
            recyclingRequest             => \%recyclingrequest,
            fraudFilterOverride          => 'filter_fraud_override',
            recurringRequest             => \%recurringRequest,
            debtRepayment                => 'debt_repayment',
            advancedFraudChecks          => \%advancedfraud,
            wallet                       => \%wallet,
            processingType               => 'processing_type',
            originalNetworkTransactionId => 'original_network_transaction_id',
            originalTransactionAmount    => 'original_transaction_amount',

        );
    }
    elsif ( $action eq 'capture' ) {
        push @required_fields, qw( order_number amount );
        tie %req, 'Tie::IxHash',
          $self->_revmap_fields(
              # partial is an element of the start tag, so located in the header
            content                => $content,
            litleTxnId             => 'order_number',
            amount                 => 'amount',
            surchargeAmount        => 'surcharge_amount',
            enhancedData           => \%enhanceddata,
            processingInstructions => \%processing,
            payPalOrderComplete    => 'paypal_order_complete',
            pin                    => 'pin',
          );
    }
    elsif ( $action eq 'force_capture' ) {
        ## ARE YOU SURE YOU WANT TO DO THIS?
        # Seriously, force captures are like running up the pirate flag, check with your Vantiv rep
        push @required_fields, qw( order_number amount );
        tie %req, 'Tie::IxHash',
          $self->_revmap_fields(
              # partial is an element of the start tag, so located in the header
            content                => $content,
            litleTxnId             => 'order_number',
            amount                 => 'amount',
            secondaryAmount        => 'secondary_amount',
            orderSource            => 'orderSource',
            billToAddress          => \%billToAddress,
            card                   => $content->{'card_number'} ? \%card : {},
            token                  => $content->{'card_token'} ? \%token : {},
            customBilling          => \%custombilling,
            taxType                => 'tax_type',      # payment|fee
            enhancedData           => \%enhanceddata,
            processingInstructions => \%processing,
            amexAggregatorData     => \%amexaggregator,
            merchantData           => \%merchantdata,
            debtRepayment          => 'debt_repayment',
            processingType         => 'processing_type',
          );
    }
    elsif ( $action eq 'credit' ) {

       # IF there is a litleTxnId, it's a normal linked credit
       if( $content->{'order_number'} ){
          push @required_fields, qw( order_number amount );
          tie %req, 'Tie::IxHash', $self->_revmap_fields(
              content                => $content,
              litleTxnId             => 'order_number',
              amount                 => 'amount',
              secondaryAmount        => 'secondary_amount',
              customBilling          => \%custombilling,
              enhancedData           => \%enhanceddata,
              processingInstructions => \%processing,
              actionReason           => 'action_reason', #  ENUM(SUSPECT_FRAUD) only option atm
          );
        }
       # ELSE it's an unlinked, which requires different data
       else {
          croak 'missing card_token or card_number' if length($content->{'card_number'} || $content->{'card_token'} || '') == 0;
          push @required_fields, qw( invoice_number amount );
          tie %req, 'Tie::IxHash', $self->_revmap_fields(
              content                => $content,
              orderId                => 'invoice_number',
              amount                 => 'amount',
              orderSource            => 'orderSource',
              billToAddress          => \%billToAddress,
              card                   => $content->{'card_number'} ? \%card : {},
              token                  => $content->{'card_token'} ? \%token : {},
              customBilling          => \%custombilling,
              taxType                => 'tax_type',
              enhancedData           => \%enhanceddata,
              processingInstructions => \%processing,
              pos                    => \%pos,
              amexAggregatorData     => \%amexaggregator,
              merchantData           => \%merchantdata,
              actionReason           => 'action_reason', # ENUM(SUSPECT_FRAUD) only option atm
          );
       }
    }
    elsif ( $action eq 'void' ) {
        push @required_fields, qw( order_number );
        tie %req, 'Tie::IxHash',
          $self->_revmap_fields(
            content                  => $content,
            litleTxnId               => 'order_number',
            processingInstructions   => \%processing,
          );
    }
    elsif ( $action eq 'authReversal' ) {
        push @required_fields, qw( order_number amount );
        tie %req, 'Tie::IxHash',
          $self->_revmap_fields(
            content                  => $content,
            litleTxnId               => 'order_number',
            amount                   => 'amount',
            actionReason             => 'action_reason', # ENUM(SUSPECT_FRAUD) only option atm
          );
    }
    elsif ( $action eq 'accountUpdate' ) {
        push @required_fields, qw( card_number expiration );
        tie %req, 'Tie::IxHash',
          $self->_revmap_fields(
            content                  => $content,
            orderId                  => 'customer_id',
            card                     => \%card,
          );
    }

    $self->required_fields(@required_fields);
    return \%req;
}

sub submit {
    my ($self) = @_;

    local $SCRUBBER=1;
    $self->_litle_init;

    my %content = $self->content();

    warn 'Pre processing: '.Dumper(\%content) if $DEBUG;
    my $req     = $self->map_request( \%content );
    warn 'Post processing: '.Dumper(\%content) if $DEBUG;
    my $post_data;

    my $writer = XML::Writer->new(
        OUTPUT      => \$post_data,
        DATA_MODE   => 1,
        DATA_INDENT => 2,
        ENCODING    => 'utf-8',
    );

    ## set the authentication data
    tie my %authentication, 'Tie::IxHash',
      $self->_revmap_fields(
        content  => \%content,
        user     => 'login',
        password => 'password',
      );

    warn Dumper($req) if $DEBUG;
    ## Start the XML Document, parent tag
    $writer->xmlDecl();
    $writer->startTag(
        "litleOnlineRequest",
        version    => $self->api_version,
        xmlns      => $self->xmlns,
        merchantId => $content{'merchantid'},
    );

    $self->_xmlwrite( $writer, 'authentication', \%authentication );

    ## partial capture modifier, odd location, because it modifies the start tag :(
    my %extra;
    if ($content{'TransactionType'} eq 'capture'){
        $extra{'partial'} = $content{'partial'} ? 'true' : 'false';
    }

    $writer->startTag(
        $content{'TransactionType'},
        id          => $content{'invoice_number'},
        reportGroup => $content{'report_group'} || 'BOP',
        customerId  => $content{'customer_id'} || 1,
        %extra,
    );
    foreach ( keys( %{$req} ) ) {
        $self->_xmlwrite( $writer, $_, $req->{$_} );
    }

    $writer->endTag( $content{'TransactionType'} );
    $writer->endTag("litleOnlineRequest");
    $writer->end();
    ## END XML Generation

    $self->server_request( $post_data );
    warn $self->server_request if $DEBUG;

    if ( $] ge '5.008' ) {
        # http_post expects data in this format
        utf8::encode($post_data) if utf8::is_utf8($post_data);
    }

    my ( $page, $status_code, %headers ) = $self->https_post( { 'Content-Type' => 'text/xml; charset=utf-8' } , $post_data);

    $self->server_response( $page );
    warn Dumper $self->server_response, $status_code, \%headers if $DEBUG;

    my $response = $self->_parse_xml_response( $page, $status_code );

    $content{'TransactionType'} =~ s/Request$//; # no clue why some of the types have a Request and some do not

    if ( exists( $response->{'response'} ) && $response->{'response'} == 1 ) {
        ## parse error type error
        warn Dumper 'https://'.$self->server.':'.$self->port.$self->path,$response, $self->server_request;
        $self->error_message( $response->{'message'} );
        return;
    } else {
        $self->error_message(
            $response->{ $content{'TransactionType'} . 'Response' }
              ->{'message'} );
    }
    $self->{_response} = $response;

    warn Dumper($response) if $DEBUG;

    ## Set up the data:
    my $resp = $response->{ $content{'TransactionType'} . 'Response' };
    $self->{_response} = $resp;
    $self->card_token( $resp->{'litleToken'} || $resp->{'tokenResponse'}->{'litleToken'} || $content{'card_token'} || '' );
    $self->order_number( $resp->{'litleTxnId'} || '' );
    $self->result_code( $resp->{'response'}    || '' );
    $resp->{'authCode'} =~ s/\D//g if $resp->{'authCode'};
    $self->authorization( $resp->{'authCode'} || '' );
    $self->cvv2_response( $resp->{'fraudResult'}->{'cardValidationResult'}
          || '' );
    $self->avs_code( $resp->{'fraudResult'}->{'avsResult'} || '' );
    if( $resp->{enhancedAuthResponse}
        && $resp->{enhancedAuthResponse}->{fundingSource}
        && $resp->{enhancedAuthResponse}->{fundingSource}->{type} eq 'PREPAID' ) {

      $self->is_prepaid(1);
      $self->prepaid_balance( $resp->{enhancedAuthResponse}->{fundingSource}->{availableBalance} );
    } else {
      $self->is_prepaid(0);
    }

    #$self->is_dupe( $resp->{'duplicate'} ? 1 : 0 );
    if( defined $resp->{'duplicate'} && $resp->{'duplicate'} eq 'true' ) {
        $self->is_duplicate(1);
    }
    else {
        $self->is_duplicate(0);
    }

    if( defined $resp->{tokenResponse} ) {
        $self->card_token($resp->{tokenResponse}->{litleToken});
        $self->card_token_response($resp->{tokenResponse}->{tokenResponseCode});
        $self->card_token_message($resp->{tokenResponse}->{tokenMessage});
    }

    if( $resp->{enhancedAuthResponse}
        && $resp->{enhancedAuthResponse}->{affluence}
      ){
      $self->get_affluence( $resp->{enhancedAuthResponse}->{affluence} );
    }
    $self->is_success( $self->result_code() eq '000' ? 1 : 0 );
    if(
           $self->result_code() eq '010' # Partial approval, if they chose that option
        || ($self->result_code() eq '802' && $self->card_token) # Card is already a token
    ) {
      $self->is_success(1);
    }

    ##Failure Status for 3.0 users
    if ( !$self->is_success ) {
        my $f_status =
            $ERRORS{ $self->result_code }->{'failure'}
          ? $ERRORS{ $self->result_code }->{'failure'}
          : 'decline';
        $self->failure_status($f_status);
    }

    unless ( $self->is_success() ) {
        unless ( $self->error_message() ) {
            $self->error_message( "(HTTPS response: $status_code) "
                  . "(HTTPS headers: "
                  . join( ", ", map { "$_ => " . $headers{$_} } keys %headers )
                  . ") "
                  . "(Raw HTTPS content: ".$self->server_response().")" );
        }
    }

}


sub chargeback_retrieve_support_doc {
    my ( $self ) = @_;
    $self->_litle_support_doc('RETRIEVE');
    if ($self->is_success) { $self->{'fileContent'} = $self->{'server_response_dangerous'}; } else { $self->{'fileContent'} = undef; }
}


sub chargeback_delete_support_doc {
    my ( $self ) = @_;
    $self->_litle_support_doc('DELETE' );
}


sub chargeback_upload_support_doc {
    my ( $self ) = @_;
    $self->_litle_support_doc('UPLOAD' );
}


sub chargeback_replace_support_doc {
    my ( $self ) = @_;
    $self->_litle_support_doc('REPLACE' );
}

sub _litle_support_doc {
    my ( $self, $action ) = @_;

    local $SCRUBBER=1;
    $self->_litle_init;

    my %content = $self->content();

    my $requiredargs = ['case_id','filename','merchantid'];
    if ($action =~ /(?:UPLOAD|REPLACE)/) { push @$requiredargs, 'filecontent', 'mimetype'; }
    foreach my $key (@$requiredargs) {
        croak "Missing arg $key" unless $content{$key};
    }

    my $actionRESTful = {
        'DELETE' => 'DELETE',
        'RETRIEVE' => 'GET',
        'UPLOAD' => 'POST',
        'REPLACE' => 'PUT',
    };
    die "UNDEFINED ACTION: $action" unless defined $actionRESTful->{$action};

    {
      use bytes;
      if ( defined $content{'filecontent'} ) {
          if ( length($content{'filecontent'}) > 2097152 ) { # file limit of 2M
              my $msg = 'Filesize Exceeds Limit Of 2MB';
              $self->result_code( 012 ); ## no critic
              $self->error_message( $msg );
              croak $msg;
          }
          my $allowedTypes = {
              'application/pdf' => 1,
              'image/gif' => 1,
              'image/jpeg' => 1,
              'image/png' => 1,
              'image/tiff' => 1,
          };
          if ( ! defined $allowedTypes->{$content{'mimetype'}||''} ) {
              croak "File must be one of PDF/GIF/JPG/PNG/TIFF".$content{'mimetype'};
          }
      }
    }

    my $caseidURI = $content{'case_id'};
    my $filenameURI = $content{'filename'};
    my $merchantidURI = $content{'merchantid'};
    foreach ( $caseidURI, $filenameURI, $merchantidURI ) {
        s/([^a-z0-9\.\-])/sprintf('%%%X',ord($1))/ige;
    }

    my $url = 'https://'.$self->chargeback_server.':'.$self->chargeback_port.'//services/chargebacks/documents/'.$merchantidURI.'/'.$caseidURI.'/'.$filenameURI;
    my $response = HTTP::Tiny->new( verify_SSL=>$self->verify_SSL )->request($actionRESTful->{$action}, $url, {
        headers => {
            'Authorization' => 'Basic ' . MIME::Base64::encode("$content{'login'}:$content{'password'}",''),
            'Content-Type' => $content{'mimetype'} || 'text/plain',
        },
        content => $content{'filecontent'},
    } );

    $self->server_request( $content{'mimetype'} );
    $self->server_response( $response->{'content'} );

    if ( $action eq 'RETRIEVE' && $response->{'status'} =~ /^200/ && substr($response->{'content'},0,500) !~ /<Merchant/x) {
        # the RETRIEVE action returns the actual page as the file, rather then returning XML
        $self->is_success(1);
    } else {
        my $xml_response = $self->_parse_xml_response( $response->{'content'}, $response->{'status'} );

        if (defined $xml_response && defined $xml_response->{'ChargebackCase'}{'Document'}{'ResponseCode'}) {
            $self->is_success( $xml_response->{'ChargebackCase'}{'Document'}{'ResponseCode'} eq '000' ? 1 : 0 );
            $self->result_code( $xml_response->{'ChargebackCase'}{'Document'}{'ResponseCode'} );
            $self->error_message( $xml_response->{'ChargebackCase'}{'Document'}{'ResponseMessage'} );
        } else {
            croak "UNRECOGNIZED RESULT: ".$self->server_response;
        }
    }
}


sub chargeback_list_support_docs {
    my ( $self ) = @_;

    local $SCRUBBER=1;
    $self->_litle_init;

    my %content = $self->content();

    croak "Missing arg case_id" unless $content{'case_id'};
    croak "Missing arg merchantid" unless $content{'merchantid'};
    my $caseidURI = $content{'case_id'};
    my $merchantidURI = $content{'merchantid'};
    foreach ( $caseidURI, $merchantidURI ) {
        s/([^a-z0-9\.\-])/sprintf('%%%X',ord($1))/ige;
    }

    my $url = 'https://'.$self->chargeback_server.':'.$self->chargeback_port.'//services/chargebacks/documents/'.$merchantidURI.'/'.$caseidURI.'/';
    my $response = HTTP::Tiny->new( verify_SSL=>$self->verify_SSL )->request('GET', $url, {
        headers => { Authorization => 'Basic ' . MIME::Base64::encode("$content{'login'}:$content{'password'}",'') },
    } );

    $self->server_request( $url );
    $self->server_response( $response->{'content'} );

    my $xml_response = $self->_parse_xml_response( $response->{'content'}, $response->{'status'} );

    if (defined $xml_response && $xml_response->{'ChargebackCase'}{'ResponseCode'}) {
        $self->result_code( $xml_response->{'ChargebackCase'}{'ResponseCode'} );
        $self->error_message( $xml_response->{'ChargebackCase'}{'ResponseMessage'} );
    } elsif (defined $xml_response && $xml_response->{'ChargebackCase'}{'DocumentEntry'}) {
        $self->is_success(1);
        $self->result_code( '000' );

    my $ref = $xml_response->{'ChargebackCase'}{'DocumentEntry'};
    if (defined $ref->{'id'} && ref $ref->{'id'} eq '') {
        # XMLin does not parse the result properly for a single document.  This fixes the single document format to match the multi-doc format
        $ref = { $ref->{'id'} => $ref };
        }
    return $ref;
    } else {
        croak "UNRECOGNIZED RESULT: ".$self->server_response;
    }
    return {};
}

sub _parse_xml_response {
    my ( $self, $page, $status_code ) = @_;
    my $response = {};
    if ( $status_code =~ /^200/ ) {
        if ( ! eval { $response = XMLin($page); } ) {
            die "XML PARSING FAILURE: $@";
        }
    }
    else {
        $status_code =~ s/[\r\n\s]+$//; # remove newline so you can see the error in a linux console
        if ( $status_code =~ /^(?:900|599)/ ) { $status_code .= ' - verify Litle has whitelisted your IP'; }
        die "CONNECTION FAILURE: $status_code";
    }
    return $response;
}

sub _parse_batch_response {
    my ( $self, $args ) = @_;
    my @results;
    my $resp = $self->{'batch_response'};
    $self->order_number( $resp->{'litleBatchId'} );

    #$self->invoice_number( $resp->{'id'} );
    my @result_types =
      grep { $_ =~ m/Response$/ }
      keys %{$resp};    ## get a list of result types in this batch
    return {
        'account_update' => $self->_get_update_response,
        ## do the other response types now
    };
}


sub add_item {
    my $self = shift;
    ## do we want to render it now, or later?
    push @{ $self->{'batch_entries'} }, shift;
}


sub create_batch {
    my ( $self, %opts ) = @_;

    local $SCRUBBER=1;
    $self->_litle_init(\%opts);

    if ( ! defined $self->{'batch_entries'} || scalar( @{ $self->{'batch_entries'} } ) < 1 ) {
        $self->error_message('Cannot create an empty batch');
        return;
    }

    my $post_data;

    my $writer = XML::Writer(
        OUTPUT      => \$post_data,
        DATA_MODE   => 1,
        DATA_INDENT => 2,
        ENCODING    => 'utf-8',
    );
    ## set the authentication data
    tie my %authentication, 'Tie::IxHash',
      $self->_revmap_fields(
        content  => \%opts,
        user     => 'login',
        password => 'password',
      );

    ## Start the XML Document, parent tag
    $writer->xmlDecl();
    $writer->startTag(
        "litleRequest",
        version => $self->batch_api_version,
        xmlns   => $self->xmlns,
        id      => $opts{'batch_id'} || time,
        numBatchRequests => 1,  #hardcoded for now, not doing multiple merchants
    );

    ## authentication
    $self->_xmlwrite( $writer, 'authentication', \%authentication );
    ## batch Request tag
    $writer->startTag(
        'batchRequest',
        id => $opts{'batch_id'} || time,
        numAccountUpdates => scalar( @{ $self->{'batch_entries'} } ),
        merchantId        => $opts{'merchantid'},
    );
    foreach my $entry ( @{ $self->{'batch_entries'} } ) {
        $self->_litle_scrubber_add_card($entry->{'card_number'});
        my $req     = $self->map_request( $entry );
        $writer->startTag(
            $entry->{'TransactionType'},
            id          => $entry->{'invoice_number'},
            reportGroup => $entry->{'report_group'} || 'BOP',
            customerId  => $entry->{'customer_id'} || 1,
        );
        foreach ( keys( %{$req} ) ) {
            $self->_xmlwrite( $writer, $_, $req->{$_} );
        }
        $writer->endTag( $entry->{'TransactionType'} );
        ## need to also handle the action tag here, and custid info
    }
    $writer->endTag("batchRequest");
    $writer->endTag("litleRequest");
    $writer->end();
    ## END XML Generation

    $self->server_request( $post_data );
    warn $self->server_request if $DEBUG;

    #----- Send it
    if ( $opts{'method'} && $opts{'method'} eq 'sftp' ) {    #FTP
        my $sftp = $self->_sftp_connect(\%opts,'inbound');

        ## save the file out, can't put directly from var, and is multibyte, so issues from filehandle
        my $filename = $opts{'batch_id'} || $opts{'login'} . "_" . time;
        my $io = IO::String->new($post_data);
        tie *IO, 'IO::String';

        $sftp->put( $io, "$filename.prg" )
          or $self->_die("Cannot PUT $filename", $sftp->error);
        $sftp->rename( "$filename.prg",
          "$filename.asc" ) #once complete, you rename it, for pickup
          or $self->die("Cannot RENAME file", $sftp->error);
        $self->is_success(1);
        $self->server_response( $sftp->message );
    }
    elsif ( $opts{'method'} && $opts{'method'} eq 'https' ) {    #https post
        $self->port('15000');
        $self->path('/');
        my ( $page, $status_code, %headers ) =
          $self->https_post($post_data);
        $self->server_response( $page );

        warn Dumper [ $page, $status_code, \%headers ] if $DEBUG;

        my $response = {};
        if ( $status_code =~ /^200/ ) {
            if ( ! eval { $response = XMLin($page); } ) {
                $self->_die("XML PARSING FAILURE: $@");
            }
            elsif ( exists( $response->{'response'} )
                && $response->{'response'} == 1 )
            {
                ## parse error type error
                warn Dumper( $response, $self->server_request );
                $self->error_message( $response->{'message'} );
                return;
            }
            else {
                $self->error_message(
                    $response->{'batchResponse'}->{'message'} );
            }
        }
        else {
            $self->_die("CONNECTION FAILURE: $status_code");
        }
        $self->{_response} = $response;

        ##parse out the batch info as our general status
        my $resp = $response->{'batchResponse'};
        $self->order_number( $resp->{'litleSessionId'} );
        $self->result_code( $response->{'response'} );
        $self->is_success( $response->{'response'} eq '0' ? 1 : 0 );

        warn Dumper($response) if $DEBUG;
        unless ( $self->is_success() ) {
            unless ( $self->error_message() ) {
                $self->error_message(
                        "(HTTPS response: $status_code) "
                      . "(HTTPS headers: "
                      . join( ", ",
                        map { "$_ => " . $headers{$_} } keys %headers )
                      . ") "
                      . "(Raw HTTPS content: $page)"
                );
            }
        }
        if ( $self->is_success() ) {
            $self->{'batch_response'} = $resp;
        }
    }

}


sub send_rfr {
    my ( $self, $args ) = @_;

    local $SCRUBBER=1;
    $self->_litle_init($args);

    my $post_data;
    my $writer =  XML::Writer->new(
        OUTPUT      => \$post_data,
        DATA_MODE   => 1,
        DATA_INDENT => 2,
        ENCODING    => 'utf-8',
    );
    ## set the authentication data
    tie my %authentication, 'Tie::IxHash',
      $self->_revmap_fields(
        content  => $args,
        user     => 'login',
        password => 'password',
      );

    ## Start the XML Document, parent tag
    $writer->xmlDecl();
    $writer->startTag(
        "litleRequest",
        version          => $self->batch_api_version,
        xmlns            => $self->xmlns,
        numBatchRequests => 0,
    );

    ## authentication
    $self->_xmlwrite( $writer, 'authentication', \%authentication );
    ## batch Request tag
    $writer->startTag('RFRRequest');
    $writer->startTag('accountUpdateFileRequestData');
    $writer->startTag('merchantId');
    $writer->characters( $args->{'merchantid'} );
    $writer->endTag('merchantId');
    $writer->startTag('postDay');
    $writer->characters( $args->{'date'} );
    $writer->endTag('postDay');
    $writer->endTag('accountUpdateFileRequestData');
    $writer->endTag("RFRRequest");
    $writer->endTag("litleRequest");
    $writer->end();
    ## END XML Generation
    #
    $self->port('15000');
    $self->path('/');
    my ( $page, $status_code, %headers ) = $self->https_post($post_data);

    $self->server_request( $post_data );
    $self->server_response( $page );
    warn $self->server_request if $DEBUG;

    warn Dumper [ $page, $status_code, \%headers ] if $DEBUG;

    my $response = {};
    if ( $status_code =~ /^200/ ) {
        if ( ! eval { $response = XMLin($page); } ) {
            die "XML PARSING FAILURE: $@";
        }
        elsif ( exists( $response->{'response'} ) && $response->{'response'} == 1 )
        {
            ## parse error type error
            warn Dumper( $response, $self->server_request );
            $self->error_message( $response->{'message'} );
            return;
        }
        else {
            $self->error_message( $response->{'RFRResponse'}->{'message'} );
        }
    }
    else {
        die "CONNECTION FAILURE: $status_code";
    }
    $self->{_response} = $response;
    if ( $response->{'RFRResponse'} ) {
        ## litle returns an 'error' if the file is not done. So it's not ready yet.
        $self->result_code( $response->{'RFRResponse'}->{'response'} );
        return;
    }
    else {

      #if processed, it returns as a batch, so, success, and let get the details
        my $resp = $response->{'batchResponse'};
        $self->is_success( $resp->{'response'} eq '000' ? 1 : 0 );
        $self->{'batch_response'} = $resp;
        $self->_parse_batch_response;
    }
}

sub _sftp_connect {
    my ($self,$args,$dir) = @_;
    $self->_die("Missing ftp_username") if ! $args->{'ftp_username'};
    $self->_die("Missing ftp_password") if ! $args->{'ftp_password'};
    require Net::SFTP::Foreign;
    my $sftp = Net::SFTP::Foreign->new(
        $self->server(),
        timeout  => $args->{'ftp_timeout'} || 90,
        stderr_discard => 1,
        user     => $args->{'ftp_username'},
        password => $args->{'ftp_password'},
    );
    $sftp->error and $self->_die("SSH connection failed: " . $sftp->error);

    if ($dir) {
        $sftp->setcwd($dir)
        or $self->_die("Cannot change working directory ", $sftp->error);
    }

    return $sftp;
}

sub _die {
    my $self = shift;
    my $msg = join '', @_;
    $self->is_success(0);
    $self->error_message( $msg );
    die $msg."\n";
}


sub retrieve_batch_list {
    my ($self, %opts ) = @_;

    local $SCRUBBER=1;
    $self->_litle_init(\%opts);

    my $sftp = $self->_sftp_connect(\%opts,'outbound');

    my $ls = $sftp->ls( wanted => qr/\.asc$/ )
    or $self->_die("Cannot get directory listing ", $sftp->error);

    my @filenames = map {$_->{'filename'}} @{ $ls };
    $self->is_success(1);
    return \@filenames;
}


sub retrieve_batch_delete  {
    my ( $self, %opts ) = @_;

    local $SCRUBBER=1;
    $self->_litle_init(\%opts);

    $self->_die("Missing batch_id") if !$opts{'batch_id'};

    my $sftp = $self->_sftp_connect(\%opts,'outbound');

    my $filename = $opts{'batch_id'};
    $sftp->remove( $filename )
    or $self->_die("Cannot delete $filename: ", $sftp->error);

    $self->is_success(1);
}


sub retrieve_batch {
    my ( $self, %opts ) = @_;

    local $SCRUBBER=1;
    $self->_litle_init(\%opts);

    $self->_die("Missing batch_id") if !$opts{'batch_id'};

    my $post_data;
    if ( $opts{'batch_return'} ) {
        ## passed in data structure
        $post_data = $opts{'batch_return'};
        $self->server_request('Data was provided using batch_return option');
    }
    else {
        ## go download a batch
        my $sftp = $self->_sftp_connect(\%opts,'outbound');

        my $filename = $opts{'batch_id'};
        $self->server_request('SFTP requesting file: '.$filename,1);
        $post_data = $sftp->get_content( $filename )
          or $self->_die("Cannot GET $filename", $sftp->error);
    }
    $self->server_response_dangerous($post_data,1);
    $self->server_response('Litle scrubber not initialized yet, see server_response_dangerous for a copy of the server response.  Please note it may contain data that is not appropriate to store.',1);

    my $response = {};
    if ( ! eval { $response = XMLin($post_data,
                                ForceArray => [ 'accountUpdateResponse' ],
                                KeyAttr => '-id',
                            ); } ) {
        $self->_die("XML PARSING FAILURE: $@");
    }
    elsif ( exists( $response->{'response'} ) && $response->{'response'} == 1 ) {
        ## parse error type error
        warn Dumper( $response, $self->{'_post_data'} );
        $self->_die($response->{'message'} || 'No reason given');
    }
    else {
        ## update the status
        $self->error_message( $response->{'batchResponse'}->{'message'} );
    }

    $self->{_response} = $response;
    my $resp = $response->{'batchResponse'};
    $self->order_number( $resp->{'litleSessionId'} );
    $self->result_code( $response->{'response'} );
    $self->is_success( $response->{'response'} eq '0' ? 1 : 0 );
    if ( $self->is_success() ) {
        $self->{'batch_response'} = $resp;
        return $self->_parse_batch_response;
    }
}

sub _get_update_response {
    my $self = shift;
    require Business::OnlinePayment::Litle::UpdaterResponse;
    my @response;
    foreach
      my $item ( @{ $self->{'batch_response'}->{'accountUpdateResponse'} } )
    {
        push @response,
          Business::OnlinePayment::Litle::UpdaterResponse->new( $item );
    }
    return \@response;
}

sub _revmap_fields {
    my $self = shift;
    tie my (%map), 'Tie::IxHash', @_;
    my %content;
    if ( $map{'content'} && ref( $map{'content'} ) eq 'HASH' ) {
        %content = %{ delete( $map{'content'} ) };
    }
    else {
        warn "WARNING: This content has not been pre-processed with map_fields ";
        %content = $self->content();
    }

    map {
        my $value;
        if ( ref( $map{$_} ) eq 'HASH' ) {
            $value = $map{$_} if ( keys %{ $map{$_} } );
        }
        elsif ( ref( $map{$_} ) eq 'ARRAY' ) {
            $value = $map{$_};
        }
        elsif ( ref( $map{$_} ) ) {
            $value = ${ $map{$_} };
        }
        elsif ( exists( $content{ $map{$_} } ) ) {
            $value = $content{ $map{$_} };
        }

        if ( defined($value) ) {
            ( $_ => $value );
        }
        else {
            ();
        }
    } ( keys %map );
}

sub _xmlwrite {
    my ( $self, $writer, $item, $value ) = @_;
    if ( ref($value) eq 'HASH' ) {
        my $attr = $value->{'attr'} ? $value->{'attr'} : {};
        $writer->startTag( $item, %{$attr} );
        foreach ( keys(%$value) ) {
            next if $_ eq 'attr';
            $self->_xmlwrite( $writer, $_, $value->{$_} );
        }
        $writer->endTag($item);
    }
    elsif ( ref($value) eq 'ARRAY' ) {
        foreach ( @{$value} ) {
            $self->_xmlwrite( $writer, $item, $_ );
        }
    }
    else {
        $writer->startTag($item);
        $writer->characters($value);
        $writer->endTag($item);
    }
}

sub _default_scrubber {
    my $cc = shift;
    my $del = substr($cc,0,6).('X'x(length($cc)-10)).substr($cc,-4,4); # show first 6 and last 4
    return $del;
}

sub _litle_scrubber_add_card {
    my ( $self, $cc ) = @_;
    return if ! $cc;
    my $scrubber = $self->{_scrubber};
    scrubber_add_scrubber({$cc=>&{$scrubber}($cc)});
}

sub _litle_init {
    my ( $self, $opts ) = @_;

    # initialize/reset the reporting methods
    $self->is_success(0);
    $self->server_request('');
    $self->server_response('');
    $self->error_message('');

    # some calls are passed via the content method, others are direct arguments... this way we cover both
    my %content = $self->content();
    foreach my $ptr (\%content,$opts) {
        next if ! $ptr;
        scrubber_init({
            quotemeta($ptr->{'password'}||'')=>'DELETED',
            quotemeta($ptr->{'ftp_password'}||'')=>'DELETED',
            ($ptr->{'cvv2'} ? '(?<=[^\d])'.quotemeta($ptr->{'cvv2'}).'(?=[^\d])' : '')=>'DELETED',
            });
        $self->_litle_scrubber_add_card($ptr->{'card_number'});
    }
}


sub chargeback_activity_request {
    my ( $self ) = @_;

    local $SCRUBBER=1;
    $self->_litle_init;

    my $post_data;
    my %content = $self->content();

    ## activity_date
    ## Type = Date; Format = YYYY-MM-DD
    if ( ! $content{'activity_date'} || $content{'activity_date'} !~ m/^\d{4}-(\d{2})-(\d{2})$/ || $1 > 12 || $2 > 31) {
        $self->_die("Invalid Date Pattern, YYYY-MM-DD required:" . ( $content{'activity_date'} || 'undef'));
    }
    #
    ## financials only [true,false]
    # The financialOnly element is an optional child of the litleChargebackActivitiesRequest element.
    # You use this flag in combination with the activityDate element to specify a request for chargeback financial activities that occurred on the specified date.
    # A value of true returns only activities that had financial impact on the specified date.
    # A value of false returns all activities on the specified date.
    #Type = Boolean; Valid Values = true or false
    my $financials;
    if ( defined( $content{'financial_only'} ) ) {
        $financials = $content{'financial_only'} ? 'true' : 'false';
    }
    else {
        $financials = 'false';
    }

    my $writer = XML::Writer->new(
        OUTPUT      => \$post_data,
        DATA_MODE   => 1,
        DATA_INDENT => 2,
        ENCODING    => 'utf-8',
    );
    ## set the authentication data
    tie my %authentication, 'Tie::IxHash',
      $self->_revmap_fields(
        content  => \%content,
        user     => 'login',
        password => 'password',
      );

    ## Start the XML Document, parent tag
    $writer->xmlDecl();
    $writer->startTag(
        "litleChargebackActivitiesRequest",
        version => $self->chargeback_api_version,
        xmlns   => $self->xmlns,
    );

    ## authentication
    $self->_xmlwrite( $writer, 'authentication', \%authentication );
    ## batch Request tag
    $writer->startTag('activityDate');
      $writer->characters( $content{'activity_date'} );
    $writer->endTag('activityDate');
    $writer->startTag('financialOnly');
      $writer->characters($financials);
    $writer->endTag('financialOnly');
    $writer->endTag("litleChargebackActivitiesRequest");
    $writer->end();
    ## END XML Generation

    $self->{'_post_data'} = $post_data;
    warn $self->{'_post_data'} if $DEBUG;
    #my ( $page, $status_code, %headers ) = $self->https_post( { 'Content-Type' => 'text/xml; charset=utf-8' } , $post_data);
    my $url = 'https://'.$self->chargeback_server.':'.$self->chargeback_port.'/'.$self->chargeback_path;
    my $tiny_response = HTTP::Tiny->new( verify_SSL=>$self->verify_SSL )->request('POST', $url, {
        headers => { 'Content-Type' => 'text/xml; charset=utf-8', },
        content => $post_data,
    } );

    my $page = $tiny_response->{'content'};
    $self->server_request( $post_data );
    $self->server_response( $page );
    my $status_code = $tiny_response->{'status'};
    my %headers = %{$tiny_response->{'headers'}};

    warn Dumper $page, $status_code, \%headers if $DEBUG;

    my $response = {};
    if ( $status_code =~ /^200/ ) {
        ## Failed to parse
        if ( !eval { $response = XMLin($page,
                                ForceArray => [ 'caseActivity' ],
                                ); } ) {
            $self->_die("XML PARSING FAILURE: $@, $page");
        }    ## well-formed failure message
        elsif ( exists( $response->{'response'} )
            && $response->{'response'} == 1 )
        {
            ## parse error type error
            warn Dumper( $response, $self->{'_post_data'} );
            $self->error_message( $response->{'message'} );
            return;
        }    ## success message
        else {
            $self->error_message(
                $response->{'litleChargebackActivitiesResponse'}->{'message'} );
        }
    }
    else {
        $status_code =~ s/[\r\n\s]+$//
          ;    # remove newline so you can see the error in a linux console
        if ( $status_code =~ /^(?:900|599)/ ) {
            $status_code .= ' - verify Litle has whitelisted your IP';
        }
        $self->_die("CONNECTION FAILURE: $status_code");
    }
    $self->{_response} = $response;

    my @response_list;
    require Business::OnlinePayment::Litle::ChargebackActivityResponse;
    foreach my $case ( @{ $response->{caseActivity} } ) {
       push @response_list,
       Business::OnlinePayment::Litle::ChargebackActivityResponse->new($case);
    }

    warn Dumper($response) if $DEBUG;
    $self->is_success(1);
    return \@response_list;
}


sub chargeback_update_request {
    my ( $self ) = @_;

    local $SCRUBBER=1;
    $self->_litle_init;

    my $post_data;
    my %content = $self->content();

    foreach my $key (qw(case_id merchant_activity_id activity )) {
        ## case_id
        ## merchant_activity_id
        ## activity
      croak "Missing arg $key" unless $content{$key};
    }

    my $writer = XML::Writer->new(
        OUTPUT      => \$post_data,
        DATA_MODE   => 1,
        DATA_INDENT => 2,
        ENCODING    => 'utf-8',
    );
    ## set the authentication data
    tie my %authentication, 'Tie::IxHash',
      $self->_revmap_fields(
        content  => \%content,
        user     => 'login',
        password => 'password',
      );

    ## Start the XML Document, parent tag
    $writer->xmlDecl();
    $writer->startTag(
        "litleChargebackUpdateRequest",
        version => $self->chargeback_api_version,
        xmlns   => $self->xmlns,
    );

    ## authentication
      $self->_xmlwrite( $writer, 'authentication', \%authentication );
      $writer->startTag('caseUpdate');
        $writer->startTag('caseId');
          $writer->characters( $content{'case_id'} );
        $writer->endTag('caseId');

        $writer->startTag('merchantActivityId');
          $writer->characters( $content{'merchant_activity_id'} );
        $writer->endTag('merchantActivityId');

        $writer->startTag('activity');
          $writer->characters( $content{'activity'} );
        $writer->endTag('activity');

      $writer->endTag('caseUpdate');
    $writer->endTag("litleChargebackUpdateRequest");
    $writer->end();
    ## END XML Generation

    $self->{'_post_data'} = $post_data;
    warn $self->{'_post_data'} if $DEBUG;
    #my ( $page, $status_code, %headers ) = $self->https_post($post_data);
    my $url = 'https://'.$self->chargeback_server.':'.$self->chargeback_port.'/'.$self->chargeback_path;
    my $tiny_response = HTTP::Tiny->new( verify_SSL=>$self->verify_SSL )->request('POST', $url, {
        headers => { 'Content-Type' => 'text/xml; charset=utf-8', },
        content => $post_data,
    } );

    my $page = $tiny_response->{'content'};
    $self->server_response( $page );
    my $status_code = $tiny_response->{'status'};
    my %headers = %{$tiny_response->{'headers'}};

    warn Dumper $page, $status_code, \%headers if $DEBUG;

    my $response = {};
    if ( $status_code =~ /^200/ ) {
        ## Failed to parse
        if ( !eval { $response = XMLin($page); } ) {
            die "XML PARSING FAILURE: $@, $page";
        }    ## well-formed failure message
        $self->{_response} = $response;
        if ( exists( $response->{'response'} ) ) {
            ## parse error type error
            warn Dumper( $response, $self->{'_post_data'} );
            $self->result_code( $response->{'response'} ); # 0 - success, 1 invalid xml
            $self->error_message( $response->{'message'} );
            $self->phoenixTxnId( $response->{'caseUpdateResponse'}{'phoenixTxnId'} );
            $self->is_success(1);
            return $response->{'caseUpdateResponse'}{'phoenixTxnId'};
        }
        else {
        die "UNKNOWN XML RESULT: $page";
        }
    }
    else {
        $status_code =~ s/[\r\n\s]+$//
          ;    # remove newline so you can see the error in a linux console
        if ( $status_code =~ /^(?:900|599)/ ) {
            $status_code .= ' - verify Litle has whitelisted your IP';
        }
        die "CONNECTION FAILURE: $status_code";
    }
}



1; # End of Business::OnlinePayment::Litle

__END__

=pod

=head1 NAME

Business::OnlinePayment::Litle - Business::OnlinePayment::Litle - Vantiv (was Litle & Co.) Backend for Business::OnlinePayment

=head1 VERSION

version 0.958

=head1 SYNOPSIS

This is a plugin for the Business::OnlinePayment interface.  Please refer to that documentation for general usage, and here for Vantiv specific usage.

In order to use this module, you will need to have an account set up with Vantiv L<http://www.vantiv.com/>

Originally created for the Litle & Co. API, which became a part of the Vantiv corporation.

  use Business::OnlinePayment;
  my $tx = Business::OnlinePayment->new(
     "Litle",
     default_Origin => 'NEW',
  );

  $tx->content(
      type           => 'CC',
      login          => 'testdrive',
      password       => '123qwe',
      action         => 'Normal Authorization',
      description    => 'FOO*Business::OnlinePayment test',
      amount         => '49.95',
      customer_id    => 'tfb',
      name           => 'Tofu Beast',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'UT',
      zip            => '84058',
      card_number    => '4007000000027',
      expiration     => '09/02',
      cvv2           => '1234', #optional
      invoice_number => '54123',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

=head1 METHODS

=head2 result_code

Returns the response error code.

=head2 error_message

Returns the response error description text.

=head2 is_duplicate

Returns 1 if the request was a duplicate, 0 otherwise

=head2 card_token

Return the card token if present.  You will need to have the card tokenization feature enabled for this feature to make sense.

=head2 card_token_response

Return the Litle specific response code for the tokenization request

=head2 card_token_message

Return the Litle human readable response to the tokenization request

=head2 server_request

Returns the complete request that was sent to the server.  The request has been stripped of card_num, cvv2, and password.  So it should be safe to log.

=head2 server_request_dangerous

Returns the complete request that was sent to the server.  This could contain data that is NOT SAFE to log.  It should only be used in a test environment, or in a PCI compliant manner.

=head2 server_response

Returns the complete response from the server.  The response has been stripped of card_num, cvv2, and password.  So it should be safe to log.

=head2 server_response_dangerous

Returns the complete response from the server.  This could contain data that is NOT SAFE to log.  It should only be used in a test environment, or in a PCI compliant manner.

=head2 action

The following actions are valid

  normal authorization
  authorization only
  post authorization
  credit
  void
  auth reversal

=head2 Fields

Most data fields not part of the BOP standard can be added to the content hash directly, and will be used

Most data fields will truncate extra characters to conform to the Litle XML length requirements.  Some fields (mostly amount fields) will error if your data exceeds the allowed length.

=head2 Products

Part of the enhanced data for level III Interchange rates

    products        =>  [
    {   description =>  'First Product',
        sku         =>  'sku',
        quantity    =>  1,
        units       =>  'Months'
        amount      =>  '5.00',
        discount    =>  0,
        code        =>  1,
        cost        =>  '5.00',
    },
    {   description =>  'Second Product',
        sku         =>  'sku',
        quantity    =>  1,
        units       =>  'Months',
        amount      =>  1500,
        discount    =>  0,
        code        =>  2,
        cost        =>  '5.00',
    }

    ],

=head2 _info

Return the introspection hash for BOP 3.x

=head2 set_defaults

=head2 test_transaction

Get/set the server used for processing transactions.  Possible values are Live, Certification, and Sandbox
Default: Live

  #Live
  $self->test_transaction(0);

  #Certification
  $self->test_transaction(1);

  #Sandbox
  $self->test_transaction('sandbox');

  #Read current value
  $val = $self->test_transaction();

=head2 map_fields

=head2 format_misc_field

A new method not directly supported by BOP.
Used internally to guarantee that XML data will conform to the Litle spec.
  field  - The hash key we are checking against
  maxLen - The maximum length allowed (extra bytes will be truncated)
  minLen - The minimum length allowed
  errorOnLength - boolean
    0 - truncate any extra bytes
    1 - error if the length is out of bounds
  isRequired - boolean
    0 - ignore undefined values
    1 - error if the value is not defined

 $tx->format_misc_field( \%content, [field, maxLen, minLen, errorOnLength, isRequired] );
 $tx->format_misc_field( \%content, ['amount',   0,     12,             0,          0] );

=head2 format_amount_field

A new method not directly supported by BOP.
Used internally to change amounts from the BOP "5.00" format to the format expected by Litle "500"

$tx->format_amount_field( \%content, 'amount' );

=head2 format_phone_field

A new method not directly supported by BOP.
Used internally to strip invalid characters from phone numbers. IE "1 (800).TRY-THIS" becomes "18008788447"

$tx->format_phone_field( \%content, 'company_phone' );

=head2 map_request

Converts the BOP data to something that Litle can use.

=head2 chargeback_retrieve_support_doc

A new method not directly supported by BOP.
Retrieve a currently uploaded file

 $tx->content(
  login       => 'testdrive',
  password    => '123qwe',
  merchantid  => '123456',
  case_id     => '001',
  filename    => 'mydoc.pdf',
 );
 $tx->chargeback_retrieve_support_doc();
 $myFileData = $tx->{'fileContent'};

=head2 chargeback_delete_support_doc

A new method not directly supported by BOP.
Delete a currently uploaded file.  Follows the same format as chargeback_retrieve_support_doc

=head2 chargeback_upload_support_doc

A new method not directly supported by BOP.
Upload a new file

 $tx->content(
  login       => 'testdrive',
  password    => '123qwe',
  merchantid  => '123456',
  case_id     => '001',
  filename    => 'mydoc.pdf',
  filecontent => $binaryPdfData,
  mimetype    => 'application/pdf',
 );
 $tx->chargeback_upload_support_doc();

=head2 chargeback_replace_support_doc

A new method not directly supported by BOP.
Replace a previously uploaded file.  Follows the same format as chargeback_upload_support_doc

=head2 chargeback_list_support_docs

A new method not directly supported by BOP.
Return a hashref that contains a list of files that already exist on the server.

 $tx->content(
  login       => 'testdrive',
  password    => '123qwe',
  merchantid  => '123456',
  case_id     => '001',
 );
 my $ret = $tx->chargeback_list_support_docs();

Currently this returns in this format

 $ret = {
   'file1' => {},
   'file2' => {},
 };

Litle does not currently send any file attributes.  However the hash is built for future expansion.

=head2 add_item

A new method not directly supported by BOP.
Interface to adding multiple entries, so we can write and interface with batches

 my %content = (
   action          =>  'Account Update',
   card_number     =>  4111111111111111,
   expiration      =>  1216,
   customer_id     =>  $card->{'uid'},
   invoice_number  =>  123,
   type            =>  'VI',
   login           =>  $merchant->{'login'},
 );
 $tx->add_item( \%content );

=head2 create_batch

A new method not directly supported by BOP.
Send the current batch to Litle.

 $tx->add_item( $item1 );
 $tx->add_item( $item2 );
 $tx->add_item( $item3 );

 my $opts = {
  login       => 'testdrive',
  password    => '123qwe',
  merchantid  => '123456',
  batch_id    => '001',
  method      => 'https', # sftp or https
  ftp_username=> 'fred',
  ftp_password=> 'pancakes',
 };

 $tx->content();

 $tx->create_batch( %$opts );

=head2 send_rfr

A new method not directly supported by BOP.

=head2 retrieve_batch_list

A new method not directly supported by BOP.
Get a list of available batch result files.

 my $opts = {
  ftp_username=> 'fred',
  ftp_password=> 'pancakes',
 };

 my $ret = $tx->retrieve_batch( %$opts );
 my @filelist = @$ret if $tx->is_success;

=head2 retrieve_batch_delete

A new method not directly supported by BOP.
Delete a batch from Litle.

 my $opts = {
  login       => 'testdrive',
  password    => '123qwe',
  batch_id    => '001',
  ftp_username=> 'fred',
  ftp_password=> 'pancakes',
 };

 $tx->retrieve_batch_delete( %$opts );

=head2 retrieve_batch

A new method not directly supported by BOP.
Get a batch from Litle.

 my $opts = {
  login       => 'testdrive',
  password    => '123qwe',
  batch_id    => '001',
  batch_return=> '', # If present, this will be used instead of downloading from Litle
  ftp_username=> 'fred',
  ftp_password=> 'pancakes',
 };

 $tx->content();

 $tx->retrieve_batch( %$opts );

=head2 chargeback_activity_request

Return a arrayref that contains a list of Business::OnlinePayment::Litle::ChargebackActivityResponse objects

 $tx->content(
  login         => 'testdrive',
  password      => '123qwe',
  activity_date => '2012-04-30',
 );

 my $ret = $tx->chargeback_activity_request();

=head2 chargeback_update_request

Return a arrayref that contains a list of Business::OnlinePayment::Litle::ChargebackActivityResponse objects

 $tx->content(
  login                => 'testdrive',
  password             => '123qwe',
  case_id              => '1600010045',
  merchant_activity_id => '1555',
  activity             => 'Merchant Accepts Liability',
 );

 $tx->chargeback_update_request();

 $tx->result_code(); # 0 - success, 1 invalid xml
 $tx->error_message(); # Text version of the error message, if any
 $tx->phoenixTxnId(); # Unique identifier provided by Litle.
 $tx->is_success(); # Boolean, did the request work

=for html <a href="https://travis-ci.org/Jayceh/Business--OnlinePayment--Litle"><img src="https://travis-ci.org/Jayceh/Business--OnlinePayment--Litle.svg?branch=master"></a>

=head1 METHODS AND FUNCTIONS

See L<Business::OnlinePayment> for the complete list. The following methods either override the methods in L<Business::OnlinePayment> or provide additional functions.

=head1 Handling of content(%content) data:

=head1 Litle specific data

=head1 SPECS

Currently uses the Litle XML specifications version 11.0 and chargeback version 2.2

=head1 TESTING

In order to run the provided test suite, you will first need to apply and get your account setup with Litle.  Then you can use the test account information they give you to run the test suite. The scripts will look for three environment variables to connect: BOP_USERNAME, BOP_PASSWORD, BOP_MERCHANTID

Currently the description field also uses a fixed descriptor.  This will possibly need to be changed based on your arrangements with Litle.

=head1 CUSTOM LOG SCRUBBING FUNCTION

The default card scrubbing leaves the first 6 and last 4 of the card number for logging.

If you want to provide your own card number scrubber code ref, pass in the default_Scrubber option to the constructor.  It takes the card
number as the first parameter and should return the masked version.

  my $tx = Business::OnlinePayment->new(
     "Litle",
     default_Origin => 'NEW',
     default_Scrubber => sub {
         return substr($_[0],-4,4);
     }
  );

=head1 FUNCTIONS

=head1 UNIMPLEMENTED

Certain features are not yet implemented (no current personal business need), though the capability of support is there, and the test data for the verification suite is there.

    Capture Given Auth
    applepay
    paypage

    return objects for bounce pages (sepa|ideal)

=head1 BUGS

Please report any bugs or feature requests to C<bug-business-onlinepayment-litle at rt.cpan.org>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

You may also add to the code via github, at L<http://github.com/Jayceh/Business--OnlinePayment--Litle.git>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::OnlinePayment::Litle

You can also look for information at:

L<http://www.vantiv.com/>

=head1 SPEC

Documentation and specs are available on github at L<http://litleco.github.io/>

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-OnlinePayment-Litle>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-OnlinePayment-Litle>

=back

=head1 ACKNOWLEDGMENTS

Heavily based on Jeff Finucane's l<Business::OnlinePayment::IPPay> because it also required dynamically writing XML formatted docs to a gateway.

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>

=head1 AUTHOR

Jason Hall <jayce@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Daina Pettit David Bartle Jason Hall (Jayce^) Terry

=over 4

=item *

Daina Pettit <dpettit@bluehost.com>

=item *

David Bartle <captindave@gmail.com>

=item *

Jason Hall <jayce@jaycehall.com>

=item *

Jason (Jayce^) Hall <jayce@lug-nut.com>

=item *

Jason Terry <oaxlin@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jason Hall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
