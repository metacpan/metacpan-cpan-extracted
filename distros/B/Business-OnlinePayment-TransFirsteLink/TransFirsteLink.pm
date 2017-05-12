package Business::OnlinePayment::TransFirsteLink;

use strict;
use vars qw($VERSION $DEBUG %error_messages);
use Carp qw(carp croak);
use Tie::IxHash;

use base qw(Business::OnlinePayment::HTTPS);

$VERSION = '0.05';
$VERSION = eval $VERSION;
$DEBUG   = 0;

%error_messages = (
  '000' => 'Approval',
  '001' => 'Call Issuer',
  '002' => 'Referral special',
  '003' => 'Invalid merchant number',
  '004' => 'Pick up',
  '005' => 'Declined',
  '006' => 'General error',
  '007' => 'Pick up special',
  '008' => 'Honor with ID',
  '009' => 'General Decline',
  '010' => 'Network Error',
  '011' => 'Approval',
  '012' => 'Invalid transaction type',
  '013' => 'Invalid amount field',
  '014' => 'Invalid card number',
  '015' => 'Invalid issuer',
  '016' => 'General Decline',
  '017' => 'General Decline',
  '018' => 'General Decline',
  '019' => 'Re-enter',
  '020' => 'General Decline',
  '021' => 'No action taken',
  '022' => 'General Decline',
  '023' => 'General Decline',
  '024' => 'General Decline',
  '025' => 'Acct num miss',
  '026' => 'General Decline',
  '027' => 'General Decline',
  '028' => 'File unavailable',
  '029' => 'General Decline',
  '030' => 'Format Error - Decline',
  '031' => 'General Decline',
  '032' => 'General Decline',
  '033' => 'General Decline',
  '034' => 'General Decline',
  '036' => 'General Decline',
  '037' => 'General Decline',
  '038' => 'General Decline',
  '039' => 'No card acct',
  '040' => 'General Decline',
  '041' => 'Lost card',
  '042' => 'General Decline',
  '043' => 'Stolen card',
  '044' => 'General Decline',
  '045' => 'General Decline',
  '046' => 'General Decline',
  '048' => 'General Decline',
  '049' => 'General Decline',
  '050' => 'General Decline',
  '051' => 'Over limit',
  '052' => 'No checking acct',
  '053' => 'No saving acct',
  '054' => 'Expired card',
  '055' => 'Invalid pin',
  '056' => 'General Decline',
  '057' => 'TXN not allowed',
  '058' => 'TXN not allowed term',
  '059' => 'TXN not allowed - Merchant',
  '060' => 'General Decline',
  '061' => 'Over cash limit',
  '062' => 'Restricted card',
  '063' => 'Security violate',
  '064' => 'General Decline',
  '065' => 'Excessive authorizations',
  '066' => 'General Decline',
  '067' => 'General Decline',
  '069' => 'General Decline',
  '070' => 'General Decline',
  '071' => 'General Decline',
  '072' => 'General Decline',
  '073' => 'General Decline',
  '074' => 'General Decline',
  '075' => 'Excessive pin entry tries',
  '076' => 'Unable locate previous msg (ref# not found)',
  '077' => 'Mismatched info',
  '078' => 'No account',
  '079' => 'Already reversed',
  '080' => 'Invalid date',
  '081' => 'Crypto error',
  '082' => 'CVV failure',
  '083' => 'Unable verify pin',
  '084' => 'Duplicate trans',
  '085' => 'No reason 2 decline',
  '086' => 'Cannot verify pin',
  '088' => 'General Decline',
  '089' => 'General Decline',
  '090' => 'General Decline',
  '091' => 'Issuer unavailable',
  '092' => 'Destination route not found',
  '093' => 'Law violation',
  '094' => 'Duplicate trans',
  '096' => 'System malfunction',
  '098' => 'General Decline',
  '099' => 'General Decline',
  '0B1' => 'Surcharge amount not permitted on Visa cards or EBT food stamps',
  '0B2' => 'Surcharge amount not supported by debit network issuer',
  '0EB' => 'Check digit error',
  '0EC' => 'Cid format error',
  '0N0' => 'FORCE STIP',
  '0N3' => 'Service not available',
  '0N4' => 'Exceeds limit issuer',
  '0N5' => 'Ineligible for resubmission',
  '0N7' => 'CVV2 failure',
  '0N8' => 'Trans amount exceeds preauth amt',
  '0P0' => 'Approved pvid miss',
  '0P1' => 'Declined pvid miss',
  '0P2' => 'Invalid bill info',
  '0Q1' => 'Card auth failed',
  '0R0' => 'Multipay stopped',
  '0R1' => 'Multipay stopped merch',
  '0R3' => 'Revocation of all authorizations order',
  '0XA' => 'Forward to issue1',
  '0XD' => 'Forward to issue2',
  '0VD' => 'General Decline',
  '0T0' => 'First Time Check',
  '0T1' => 'Check is OK, but cannot be converted',
  '0T2' => 'Invalid routing transit number or check belongs to a category that is not eligible for conversion',
  '0T3' => 'Amount greater than established service limit',
  '0T4' => 'Unpaid items, failed negative check',
  '0T5' => 'Duplicate check number',
  '0T6' => 'MICR Error',
  '0T7' => 'Too many checks (over merchant or bank limit)',
  '203' => 'Invalid merchant number',
  '212' => 'Invalid transaction type',
  '213' => 'Invalid amount field',
  '214' => 'Invalid card number',
  '254' => 'Expired card',
  '257' => 'Txn not allowed',
  '276' => 'Unable to locate prvious msg (ref # not found)',
  '278' => 'No account',
  '284' => 'General Decline',
  '296' => 'System malfunction',
  '2Q1' => 'Card authorization failed',
  '300' => 'Invalid request format',
  '301' => 'Missing file header',
  '303' => 'Invalid sender ID',
  '306' => 'Duplicate file number',
  '307' => 'General Decline',
  '309' => 'Comm link down',
  '310' => 'Missing batch header',
  '317' => 'Invalid MOTO ID',
  '338' => 'General Decline',
  '380' => 'Missing batch trailer',
  '382' => 'Record count does not match number records in batch',
  '383' => 'Net amount does not match file amount',
  '384' => 'Duplicate transaction',
  '385' => 'Invalid request format',
  '394' => 'Record count does not match records in file',
  '395' => 'Net amount does not match file amount',
  '396' => 'Declined post - reauthorization attempt',
  '318' => 'Invalid account data source',
  '319' => 'Invalid POS entry mode',
  '320' => 'Auth date invalid (transaction date)',
  '321' => 'Invalid auth source code',
  '322' => 'Invalid ACI code',
  'REJ' => 'Rejected transaction that has been re-keyed',
  '3AC' => 'Invalid authorization code (must be uppercase, no special chars)',
  '3TI' => 'Invalid tax indicator',
  '3VD' => 'Voided transaction',
  '3AD' => 'AVS response code declined',
  '3AR' => 'AVS required/address information not provided',
  '3BD' => 'AVS and CVV2 response Code Declined',
  '3BR' => 'AVS and CVV2 required/information not provided',
  '3CD' => 'CVV2 response code declined',
  '3CR' => 'CVV2 required/inrormation not provided',
  '3L5' => 'No data sent',
  '3L6' => 'Order number missing',
  '3M1' => 'Auth date blank',
  '3M2' => 'Auth amount blank',
  '3MT' => 'Managed transaction',
  '3RV' => 'Reversed transaction',
  '3TO' => 'Timeout',
  '600' => 'General Decline',
  '990' => 'Voided',
  '991' => 'Voided',
  '992' => 'Voided',
  '993' => 'Voided',
  '994' => 'Voided',
  '995' => 'Voided',
  '996' => 'Voided',
  '997' => 'Voided',
  '998' => 'Voided',
  '999' => 'Voided',
  'XXX' => 'General Decline',
);

sub debug {
    my $self = shift;

    if (@_) {
        my $level = shift || 0;
        if ( ref($self) ) {
            $self->{"__DEBUG"} = $level;
        }
        else {
            $DEBUG = $level;
        }
        $Business::OnlinePayment::HTTPS::DEBUG = $level;
    }
    return ref($self) ? ( $self->{"__DEBUG"} || $DEBUG ) : $DEBUG;
}

sub set_defaults {
    my $self = shift;
    my %opts = @_;

    # standard B::OP methods/data
    $self->server("epaysecure1.transfirst.com");
    $self->port("443");
    $self->path("/");

    $self->build_subs(qw( 
                          merchantcustservnum
                          order_number avs_code cvv2_response
                          response_page response_code response_headers
                          junk
                     ));

    # module specific data
    if ( $opts{debug} ) {
        $self->debug( $opts{debug} );
        delete $opts{debug};
    }

    if ( $opts{merchantcustservnum} ) {
        $self->merchantcustservnum( $opts{merchantcustservnum} );
        delete $opts{merchantcustservnum};
    }

}

sub _map_fields {
    my ($self) = @_;

    my %content = $self->content();

    #ACTION MAP
    my %actions = (
        'normal authorization' => 32,    # Authorization/Settle transaction
        'credit'               => 20,    # Credit (refund)
        'authorization only'   => 30,    # Authorization only
        'post authorization'   => 40,    # Settlement
        'void'                 => 61,    # Void
    );

    $content{'TransactionCode'} = $actions{ lc( $content{'action'} ) }
      || $content{'action'};

    # TYPE MAP
    my %types = (
        'visa'             => 'CC',
        'mastercard'       => 'CC',
        'american express' => 'CC',
        'discover'         => 'CC',
        'cc'               => 'CC',

        'check'            => 'ECHECK',
    );

    $content{'type'} = $types{ lc( $content{'type'} ) } || $content{'type'};

    $self->transaction_type( $content{'type'} );

    # stuff it back into %content
    $self->content(%content);
}

sub _revmap_fields {
    my ( $self, %map ) = @_;
    my %content = $self->content();
    foreach ( keys %map ) {
        $content{$_} =
          ref( $map{$_} )
          ? ${ $map{$_} }
          : $content{ $map{$_} };
    }
    $self->content(%content);
}

sub expdate_mmyy {
    my $self       = shift;
    my $expiration = shift;
    my $expdate_mmyy;
    if ( defined($expiration) and $expiration =~ /^(\d+)\D+\d*(\d{2})$/ ) {
        my ( $month, $year ) = ( $1, $2 );
        $expdate_mmyy = sprintf( "%02d", $month ) . $year;
    }
    return defined($expdate_mmyy) ? $expdate_mmyy : $expiration;
}

sub required_fields {
    my($self,@fields) = @_;

    my @missing;
    my %content = $self->content();
    foreach(@fields) {
      next
        if (exists $content{$_} && defined $content{$_} && $content{$_}=~/\S+/);
      push(@missing, $_);
    }

    Carp::croak("missing required field(s): " . join(", ", @missing) . "\n")
      if(@missing);

}

sub submit {
    my ($self) = @_;

    $self->_map_fields();

    my %content = $self->content;

    my %required;
    $required{CC_20} = [ qw( ePayAccountNum Password OrderNum
                             TransactionAmount CardAccountNum ExpirationDate
                             MerchantCustServNum ) ];
    $required{CC_30} = [ qw( ePayAccountNum Password TransactionCode OrderNum
                             TransactionAmount CardAccountNum ExpirationDate
                             CardHolderZip MerchantCustServNum ) ];
    $required{CC_32} = $required{CC_30};
    $required{CC_61} = [ qw( ePayAccountNum Password TransactionCode
                             ReferenceNum ) ];
    $required{ECHECK_20} = [ qw( ePayAccountNum Password AccountNumber
                                 RoutingNumber DollarAmount OrderNumber
                                 CustomerNumber CustomerName ) ];
    $required{ECHECK_32} = [ qw( ePayAccountNum Password OrderNumber
                                 AccountNumber RoutingNumber CheckNumber
                                 DollarAmount CustomerName CustomerAddress
                                 CustomerCity CustomerState CustomerZip
                                 CustomerPhone ) ];

    my %optional;
    $optional{CC_20} = [ qw( CardHolderName CardHolderAddress CardHolderCity
                             CardHolderState CardHolderZip CardHolderEmail
                             CardHolderPhone CustomerNum Misc1 Misc2 CVV2
                             Ecommerce DuplicateChecking AuthorizedAmount
                             AutorizedDate AuthorizedTime FulfillmentDate
                             CardHolderCountry POSEntryMode MerchantStoreNum
                             CardHolderIDSource SICCATCode MerchantZipCode
                             AccountDataSource AuthResponseCode AuthSourceCode
                             AuthACICode AuthValidationCode AuthAVSResponse
                             MerchantCustServNum CrossReferenceNum
                             PaymentDescription ReferenceNum ) ];
    $optional{CC_32} = $optional{CC_30};
    $optional{CC_30} = [ qw( CardHolderName CardHolderAddress CardHolderCity
                             CardHolderState CardHolderEmail CardHolderPhone
                             CustomerNum Misc1 Misc2 CVV2 Ecommerce
                             DuplicateChecking MessageSequenceNum
                             CardHolderCountry POSEntryMode MerchantStoreNum
                             CardHolderIDSource SICCATCode MerchantZipCode
                             PaymenntDiscriptor CAVVCode ECIValue XID
                             TaxIndicator TotalTaxAmount ) ];
    $optional{CC_32} = $optional{CC_30};
    $optional{CC_61} = [ qw( MessageSequenceNum CrossReferenceNum OrderNum
                             CustomerNum ) ];
    $optional{ECHECK_20} = ();
    $optional{ECHECK_32} = [ qw( CustomerNumber Misc1 Misc2 CustomerEmail
                                 DriversLicense DriversLicenseState
                                 BirthDate SocSecNum ) ];

    my $type_action = $self->transaction_type(). '_'. $content{TransactionCode};
    unless ( exists($required{$type_action}) ) {
#        croak( "TransFirst eLink can't (yet?) handle transaction type: ".
#              "$content{action} on " . $self->transaction_type() );
      $self->error_message("TransFirst eLink can't handle transaction type: ".
        "$content{action} on " . $self->transaction_type() );
      $self->is_success(0);
      return;
    }

    my $expdate_mmyy = $self->expdate_mmyy( $content{"expiration"} );

    my $zip          = $content{'zip'};
    $zip =~ s/[^[:alnum:]]//g;

    my $phone = $content{'phone'};
    $phone =~ s/\D//g;

    my $merchantcustservnum = $self->merchantcustservnum;
    my $account_number = $self->transaction_type() eq 'CC'
                           ? $content{card_number}
                           : $content{account_number} ;

    my $invoice_number = $content{invoice_number} || "PAYMENT";  # make one up
    my $check_number = $content{check_number} || "100";  # make one up

    $self->_revmap_fields(

        ePayAccountNum      => 'login',
        Password            => 'password',
        OrderNum            => \$invoice_number,
        OrderNumber         => \$invoice_number,
        MerchantCustServNum => \$merchantcustservnum,

        TransactionAmount   => 'amount',
        DollarAmount        => 'amount',
        CardAccountNum      => 'card_number',
        ExpirationDate      => \$expdate_mmyy,    # MMYY from 'expiration'
        CVV2                => 'cvv2',

        RoutingNumber       => 'routing_code',
        AccountNumber       => \$account_number,
        AccountNum          => \$account_number,
        CheckNumber         => \$check_number,

        CardHolderName      => 'name',
        CustomerName        => 'account_name',
        CardHolderAddress   => 'address',
        CustomerAddress     => 'address',
        CardHolderCity      => 'city',
        CustomerCity        => 'city',
        CardHolderState     => 'state',
        CustomerState       => 'state',
        CardHolderZip       => \$zip,          # 'zip' with non-alnums removed
        CustomerZip         => \$zip,          # 'zip' with non-alnums removed
        CardHolderEmail     => 'email',
        CustomerEmail       => 'email',
        CardHolderPhone     => \$phone,
        CustomerPhone       => \$phone,
        CustomerNum         => 'customer_id',
        CustomerNumber      => 'customer_id',
        CardHolderCountry   => 'country',

        PaymentDescriptor   => 'description',

        ReferenceNum        => 'order_number'
    );

    tie my %params, 'Tie::IxHash',
      $self->get_fields( @{$required{$type_action}},
                         @{$optional{$type_action}},
                       );

    $params{TestTransaction}='Y' if $self->test_transaction;

    $params{InstallmentNum} = $params{InstallmentOf} = '01'
      unless ($params{InstallmentNum} && $params{InstallmentOf}); 

    if ($self->transaction_type() eq 'ECHECK') {
      delete $params{InstallmentNum};
      delete $params{InstallmentOf};
    }

    if ( $type_action eq "CC_30" || $type_action eq "CC_32" ) {
      $self->path($self->path."elink/authpd.asp");
    } elsif ( $type_action eq "CC_61" ) {
      $self->path($self->path."eLink/voidpd.asp");
    } elsif ( $type_action eq "CC_20" ) {
      $self->path($self->path."eLink/creditpd.asp");
    } elsif ( $type_action eq "ECHECK_32" ) {
      $self->path($self->path."eLink/checkPD.asp");
    } elsif ( $type_action eq "ECHECK_20" ) {
      $self->path($self->path."eLink/checkcreditPD.asp");
    } else {
      croak "don't know path for unexpected type and action $type_action";
    }

    warn join("\n", map{ "$_ => $params{$_}" } keys(%params)) if $DEBUG > 1;
    my ( $page, $resp, %resp_headers ) =
      $self->https_post( %params );

    $self->response_code( $resp );
    $self->response_page( $page );
    $self->response_headers( \%resp_headers );

    warn "$page\n" if $DEBUG > 1;
    # $page should contain | separated values

    $self->required_fields(@{$required{$type_action}});

    my $status ='';
    my @rarray = ();

    if ( $type_action eq "CC_30" || $type_action eq "CC_32" ) {
      my ($format,$account,$tcode,$seq,$moi,$cardnum,$exp,$authamt,$authdate,
          $authtime,$tstat,$custnum,$ordernum,$refnum,$rcode,$authsrc,$achar,
          $transid,$vcode,$sic,$country,$avscode,$storenum,$cvv2resp,$cavvcode,
          $crossrefnum,$etstat,$cavvresponse,$xid,$eci,@junk)
        = split '\|', $page;

      # AVS and CVS values may be set on success or failure
      $self->avs_code($avscode);
      $self->cvv2_response( $cvv2resp );
      $self->result_code( $status = $etstat );
      $self->order_number( $refnum );
      $self->authorization( $rcode );
      $self->junk( \@junk );
      $self->error_message($error_messages{$status});


    } elsif ( $type_action eq "CC_61" ) {
      $self->avs_code('');
      $self->cvv2_response('');
      my ($format,$account,$tcode,$seq,$voiddate,$voidtime,$tstat, # flaky docs
          $refnum,$filler1,$filler2,$filler3,$etstat,@junk)
         = split '\|', $page;
      $self->result_code( $status = $etstat );
      $self->order_number( $refnum );
      $self->authorization('');
      $self->junk( \@junk );
      $self->error_message($error_messages{$status});

    } elsif ( $type_action eq "CC_20" ) {
      $self->avs_code('');
      $self->cvv2_response('');
      my ($format,$account,$tcode,$seq,$moi,$authamt,$authdate,$authtime,
          $tstat,$refnum,$crossrefnum,$custnum,$ordernum,$etstat,@junk)
         = split '\|', $page;
      $self->result_code( $status = $etstat );
      $self->order_number( $refnum );
      $self->authorization('');
      $self->junk( \@junk );
      $self->error_message($error_messages{$status});

    } elsif ( $type_action eq "ECHECK_32" ) {
      my ($responsecode,$response,$transactionid,$note,$errors,@junk)
         = split '\|', $page;
      $self->avs_code('');
      $self->cvv2_response('');
      $self->result_code( $status = $responsecode );
      $self->order_number( $transactionid );
      $self->authorization('');
      $errors = $errors ? $errors : '';
      $self->error_message("$response $errors");
      $self->junk( \@junk );

    } elsif ( $type_action eq "ECHECK_20" ) {
      my ($response,$transactionid,$note,$errors,@junk) # very flaky docs
         = split '\|', $page;
      $self->avs_code('');
      $self->cvv2_response('');
      $self->result_code( $status = $response );
      $self->order_number( $transactionid );
      $self->authorization('');
      $errors = $errors ? $errors : '';
      $self->error_message("$response $errors");
      $self->junk( \@junk );

    } else {
      croak "can't interpret response for unexpected type and action $type_action";
    }

    if ( $resp =~ /^(HTTP\S+ )?200/ && ($status eq "000" || $status eq "011" || $status eq "085" || $status eq "0P0" || $status eq "P00" || $status eq 'ACCEPTED') ) {
        $self->is_success(1);
    }
    else {
        $self->is_success(0);
    }
}

1;

__END__

=head1 NAME

Business::OnlinePayment::TransFirsteLink - Transfirst eLink backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;
  
  my $tx = new Business::OnlinePayment(
      'TransFirsteLink',
      'merchantcustservnum' => "8005551212",
  );
  
  # See the module documentation for details of content()
  $tx->content(
      type           => 'CC',
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment::TransFirsteLink test',
      amount         => '49.95',
      invoice_number => '100100',
      customer_id    => 'jef',
      name           => 'Jeff Finucane',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'GA',
      zip            => '30004',
      email          => 'transfirst@weasellips.com',
      card_number    => '4111111111111111',
      expiration     => '12/09',
      cvv2           => '123',
      order_number   => 'string',
  );
  
  $tx->submit();
  
  if ( $tx->is_success() ) {
      print(
          "Card processed successfully: ", $tx->authorization, "\n",
          "order number: ",                $tx->order_number,  "\n",
          "CVV2 response: ",               $tx->cvv2_response, "\n",
          "AVS code: ",                    $tx->avs_code,      "\n",
      );
  }
  else {
      my $info = "";
      $info = " (CVV2 mismatch)" if ( $tx->result_code == 114 );
      
      print(
          "Card was rejected: ", $tx->error_message, $info, "\n",
          "order number: ",      $tx->order_number,         "\n",
      );
  }

=head1 DESCRIPTION

This module is a back end driver that implements the interface
specified by L<Business::OnlinePayment> to support payment handling
via TransFirst's eLink Internet payment solution.

See L<Business::OnlinePayment> for details on the interface this
modules supports.

=head1 Standard methods

=over 4

=item set_defaults()

This method sets the 'server' attribute to 'epaysecure1.transfirst.com' and
the port attribute to '443'.  This method also sets up the
L</Module specific methods> described below.

=item submit()

=back

=head1 Unofficial methods

This module provides the following methods which are not officially part of the
standard Business::OnlinePayment interface (as of 3.00_06) but are nevertheless
supported by multiple gateways modules and expected to be standardized soon:

=over 4

=item L<order_number()|/order_number()>

=item L<avs_code()|/avs_code()>

=item L<cvv2_response()|/cvv2_response()>

=back

=head1 Module specific methods

This module provides the following methods which are not currently
part of the standard Business::OnlinePayment interface:

=over 4

=item L<expdate_mmyy()|/expdate_mmyy()>

=item L<debug()|/debug()>

=back

=head1 Settings

The following default settings exist:

=over 4

=item server

epaysecure1.transfirst.com

=item port

443

=back

=head1 Handling of content(%content)

The following rules apply to content(%content) data:

=head2 type

If 'type' matches one of the following keys it is replaced by the
right hand side value:

  'visa'               => 'CC',
  'mastercard'         => 'CC',
  'american express'   => 'CC',
  'discover'           => 'CC',
  'check'              => 'ECHECK',

The value of 'type' is used to set transaction_type().  Currently this
module only supports the above values.

=head1 Setting TransFirst eLink parameters from content(%content)

The following rules are applied to map data to TransFirst eLink parameters
from content(%content):

    # eLink param       => $content{<key>}
      ePayAccountNum    => 'login',
      Password          => 'password',
      OrderNum          => 'invoice_number',
      OrderNumber       => 'invoice_number',

      TransactionAmount => 'amount',
      DollarAmount      => 'amount',
      CardAccountNum    => 'card_number',
      ExpirationDate    => \( $month.$year ), # MM/YY from 'expiration'
      CVV2              => 'cvv2',

      RoutingNumber     => 'routing_code',
      AccountNumber     => \( $type eq 'CC' ? $card_number : $account_number ),
      CheckNumber       => 'check_number',

      CardHolderName    => 'name',
      CardHolderAddress => 'address',
      CardHolderCity    => 'city',
      CardHolderState   => 'state',
      CardHolderZip     => \$zip,       # 'zip' with non-alphanumerics removed
      CardHolderEmail   => 'email',
      CardHolderPhone   => 'phone',     # with non-digits removed
      CardHolderCountry => 'country',

      CustomerName      => 'name',
      CustomerAddress   => 'address',
      CustomerCity      => 'city',
      CustomerState     => 'state',
      CustomerZip       => \$zip,       # 'zip' with non-alphanumerics removed
      CustomerEmail     => 'email',
      CustomerPhone     => 'phone',     # with non-digits removed

      PaymentDescriptor => 'description',

=head1 Mapping TransFirst eLink transaction responses to object methods

The following methods provides access to the transaction response data
resulting from a Payflow Pro request (after submit()) is called:

=head2 order_number()

This order_number() method returns the ReferenceNum field for card transactions
and TransactionId for check transactions to uniquely identify the transaction.

=head2 result_code()

The result_code() method returns the Extended Transaction Status field for
card transactions and the Result Code field for check transactions.  It is the
numeric return code indicating the outcome of the attempted
transaction.

=head2 error_message()

The error_message() method returns the Errors field for check
transactions.  This provides more details about the transaction result.

=head2 authorization()

The authorization() method returns the Authorization Response Code field,
which is the approval code obtained from the card processing network.

=head2 avs_code()

The avs_code() method returns the AVS Response Code field from the
transaction result.

=head2 cvv2_response()

The cvv2_response() method returns the CVV2 Response Code field, which is a
response message returned with the transaction result.

=head2 expdate_mmyy()

The expdate_mmyy() method takes a single scalar argument (typically
the value in $content{expiration}) and attempts to parse and format
and put the date in MMYY format as required by PayflowPro
specification.  If unable to parse the expiration date simply leave it
as is and let the PayflowPro system attempt to handle it as-is.

=head2 debug()

Enable or disble debugging.  The value specified here will also set
$Business::OnlinePayment::HTTPS::DEBUG in submit() to aid in
troubleshooting problems.

=head1 COMPATIBILITY

This module implements an interface to the TransFirst eLink API version
3.4

=head1 AUTHORS

Original author: Jeff Finucane

Current maintainer: Ivan Kohler <ivan-transfirst@freeside.biz>

Based on Business::OnlinePayment::PayflowPro written by Ivan Kohler
and Phil Lobbes.

=head1 SEE ALSO

perl(1), L<Business::OnlinePayment>, L<Carp>, and the TransFirst
e Payment Services Card Not Present eLink User Guide.

=cut
