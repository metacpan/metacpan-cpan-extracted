package Business::OnlinePayment::IATSPayments;
use base qw( Business::OnlinePayment );

use warnings;
use strict;
use Data::Dumper;
use Business::CreditCard;
use SOAP::Lite;
#SOAP::Lite->import(+trace=>'debug');

our $VERSION = '0.02';
$VERSION = eval $VERSION; # modperlstyle: convert the string into a number

sub _info {
  {
    'info_compat'       => '0.01',
    'gateway_name'      => 'IATS Payments',
    'gateway_url'       => 'http://home.iatspayments.com/',
    'module_version'    => $VERSION,
    'supported_types'   => [ 'CC', 'ECHECK' ],
    #'token_support'     => 1,
    'test_transaction'  => 1,

    'supported_actions' => [ 'Normal Authorization',
                             'Credit',
                           ],
  };
}

sub set_defaults {
    my $self = shift;
    #my %opts = @_;

    #$self->build_subs(qw( order_number avs_code cvv2_response
    #                      response_page response_code response_headers
    #                 ));

    $self->build_subs(qw( avs_code ));

}

sub map_fields {
    my($self) = @_;

    my %content = $self->content();

    # TYPE MAP
    my %types = ( 'visa'               => 'CC',
                  'mastercard'         => 'CC',
                  'american express'   => 'CC',
                  'discover'           => 'CC',
                  'check'              => 'ECHECK',
                );
    $content{'type'} = $types{lc($content{'type'})} || $content{'type'};
    $self->transaction_type($content{'type'});
    
    # ACTION MAP 
    my $action = lc($content{'action'});
    my %actions =
      ( 'normal authorization'  => 'ProcessCreditCardV1',
        'credit'                => 'ProcessCreditCardRefundWithTransactionIdV1',
      );
    my %check_actions =
      ( 'normal authorization'  => 'ProcessACHEFTV1',
        'credit'                => 'ProcessACHEFTRefundWithTransactionIdV1',
      );

    if ($self->transaction_type eq 'CC') {
      $content{'action'} = $actions{$action} || $action;
    } elsif ($self->transaction_type eq 'ECHECK') {

      $content{'action'} = $check_actions{$action} || $action;

      # ACCOUNT TYPE MAP
      my %account_types = ('personal checking'   => 'CHECKING',
                           'personal savings'    => 'SAVINGS',
                           'business checking'   => 'CHECKING',
                           'business savings'    => 'SAVINGS',
                           #not technically B:OP valid i guess?
                           'checking'            => 'CHECKING',
                           'savings'             => 'SAVINGS',
                          );
      $content{'account_type'} = $account_types{lc($content{'account_type'})}
                                 || $content{'account_type'};
    }

    # stuff it back into %content
    $self->content(%content);

}

sub remap_fields {
    my($self,%map) = @_;

    my %content = $self->content();
    foreach(keys %map) {
        $content{$map{$_}} = $content{$_};
    }
    $self->content(%content);
}

# NA: VISA, MC, AMX, DSC
# UK: VISA, MC, AMX, MAESTR
our %mop = (
  'VISA card'             => 'VISA',
  'MasterCard'            => 'MC',
  'Discover card'         => 'DSC',
  'American Express card' => 'AMEX',
  'Switch'                => 'MAESTR',
  'Solo'                  => 'MAESTR',
);

#https://www.iatspayments.com/english/help/rejects.html
our %reject = (
  '1' => 'Agent code has not been set up on the authorization system. Please call iATS at 1-888-955-5455.',
  '2' => 'Unable to process transaction. Verify and re-enter credit card information.',
  '3' => 'Invalid Customer Code.',
  '4' => 'Incorrect expiration date.',
  '5' => 'Invalid transaction. Verify and re-enter credit card information.',
  '6' => 'Please have cardholder call the number on the back of the card.',
  '7' => 'Lost or stolen card.',
  '8' => 'Invalid card status.',
  '9' => 'Restricted card status. Usually on corporate cards restricted to specific sales.',
  '10' => 'Error. Please verify and re-enter credit card information.',
  '11' => 'General decline code. Please have client call the number on the back of credit card',
  '12' => 'Incorrect CVV2 or Expiry date',
  '14' => 'The card is over the limit.',
  '15' => 'General decline code. Please have client call the number on the back of credit card',
  '16' => 'Invalid charge card number. Verify and re-enter credit card information.',
  '17' => 'Unable to authorize transaction. Authorizer needs more information for approval.',
  '18' => 'Card not supported by institution.',
  '19' => 'Incorrect CVV2 security code',
  '22' => 'Bank timeout. Bank lines may be down or busy. Re-try transaction later.',
  '23' => 'System error. Re-try transaction later.',
  '24' => 'Charge card expired.',
  '25' => 'Capture card. Reported lost or stolen.',
  '26' => 'Invalid transaction, invalid expiry date. Please confirm and retry transaction.',
  '27' => 'Please have cardholder call the number on the back of the card.',
  '32' => 'Invalid charge card number.',
  '39' => 'Contact IATS 1-888-955-5455.',
  '40' => 'Invalid card number. Card not supported by IATS.',
  '41' => 'Invalid Expiry date.',
  '42' => 'CVV2 required.',
  '43' => 'Incorrect AVS.',
  '45' => 'Credit card name blocked. Call iATS at 1-888-955-5455.',
  '46' => 'Card tumbling. Call iATS at 1-888-955-5455.',
  '47' => 'Name tumbling. Call iATS at 1-888-955-5455.',
  '48' => 'IP blocked. Call iATS at 1-888-955-5455.',
  '49' => 'Velocity 1 – IP block. Call iATS at 1-888-955-5455.',
  '50' => 'Velocity 2 – IP block. Call iATS at 1-888-955-5455.',
  '51' => 'Velocity 3 – IP block. Call iATS at 1-888-955-5455.',
  '52' => 'Credit card BIN country blocked. Call iATS at 1-888-955-5455.',
  '100' => 'DO NOT REPROCESS. Call iATS at 1-888-955-5455.',
  #Timeout 	The system has not responded in the time allotted. Call iATS at 1-888-955-5455.
);

our %failure_status = (
  '7'  => 'stolen',
  '8'  => 'inactive',
  '9'  => 'inactive',
  '14' => 'nsf',
  '24' => 'expired',
  '25' => 'stolen',
  '45' => 'blacklisted',
  '48' => 'blacklisted',
  '49' => 'blacklisted',
  '50' => 'blacklisted',
  '51' => 'blacklisted',
  '52' => 'blacklisted',
  #'100' => # it sounds serious.  but why?  it says nothing specific
);

sub submit {
  my($self) = @_;

  $self->map_fields;

  $self->remap_fields(
        login             => 'agentCode',
        password          => 'password',

        description       => 'comment',
        amount            => 'total',
        invoice_number    => 'invoiceNum',
        customer_ip       => 'customerIPAddress',

        last_name         => 'lastName',
        first_name        => 'firstName',
        address           => 'address',
        city              => 'city',
        state             => 'state',
        zip               => 'zipCode',
        #country           => 'x_Country',

        card_number       => 'creditCardNum',
        expiration        => 'creditCardExpiry',
        cvv2              => 'cvv2',

        authorization     => 'transactionId',

        account_type      => 'accountType',

  );

  my %content = $self->content();

  $content{'mop'} = $mop{ cardtype($content{creditCardNum}) }
    if $content{'type'} eq 'CC';

  if ( $self->test_transaction ) {
    $content{agentCode} = 'TEST88';
    $content{password}  = 'TEST88';
  }

  my $base_uri =
    ( ! $content{currency} || $content{currency} =~ /^(USD|CAD)$/i )
      ? 'https://www.iatspayments.com/NetGate/'
      : 'https://www.uk.iatspayments.com/NetGate/';

  my $action = $content{action};

  my $uri = $base_uri. "ProcessLink.asmx?op=$action";

  my %data = map { $_ => $content{$_} } (qw(
    agentCode
    password
    comment
    total
    customerIPAddress
  ));

  if ( $action =~ /RefundWithTransacdtionIdV[\d\.]+$/ ) {

    $data{ $_ } = $content{$_} for qw(
      transactionId
    );

  } else {

    $data{ $_ } = $content{$_} for qw(
      invoiceNum
      lastName
      firstName
      address
      city
      state
      zipCode
    );

    if ( $content{'type'} eq 'CC' ) {

      $data{$_} = $content{$_}
        for qw( creditCardNum creditCardExpiry cvv2 mop );

    } elsif ( $content{'type'} eq 'ECHECK' ) {

      $data{'accountNum'}= $content{'routing_code'}. $content{'account_number'};

      $data{$_} = $content{$_}
        for qw( accountType );

    }

  }

  my @opts = map { SOAP::Data->name($_)->value( $data{$_} ) }
               keys %data;

  my $result = SOAP::Lite
                 ->proxy($uri)
                 ->default_ns($base_uri)
                 #->on_action( sub { join '/', @_ } )
                 ->on_action( sub { join '', @_ } )
                 ->autotype(0)

                 ->$action( @opts )

                 ->result();

  my $iatsresponse = $result->{IATSRESPONSE};

  if ( $iatsresponse->{STATUS} eq 'Failure' && $iatsresponse->{ERRORS} ) {
    die 'iATS Payments error: '. $iatsresponse->{ERRORS}. "\n";
  } elsif ( $iatsresponse->{STATUS} ne 'Success' ) {
    die "Couldn't parse iATS Payments response: ". Dumper($result);
  }

  my $processresult = $iatsresponse->{PROCESSRESULT};

  if ( defined( $processresult->{TRANSACTIONID} ) ) {
    $processresult->{TRANSACTIONID} =~ s/^\s+//;
    $processresult->{TRANSACTIONID} =~ s/\s+$//;
  }
  $self->authorization($processresult->{TRANSACTIONID} || '');

  if ( $processresult->{AUTHORIZATIONRESULT} =~ /^\s*OK(:\s*\d+:)?(\w)?\s*$/i ) {
    $self->is_success(1);
    $self->avs_code($2); #avs_code?  sure looks like one

  } elsif ( $processresult->{AUTHORIZATIONRESULT} =~ /^\s*Timeout\s*$/i ) {
    $self->is_success(0);
    $self->error_message('The system has not responded in the time allotted. '.
                         'Call iATS at 1-888-955-5455.');

  } elsif ( $processresult->{AUTHORIZATIONRESULT}
              =~ /^\s*REJ(ECT)?:\s*(\d+)\s*$/i
          )
  {
    $self->is_success(0);
    $self->result_code($2);
    $self->error_message( $reject{$2} || $processresult->{AUTHORIZATIONRESULT});
    $self->failure_status( $failure_status{$2} || 'decline' );

  } else {
    die "No/Unknown AUTHORIZATIONRESULT iATS Payments response: ".
          Dumper($processresult);
  }

}

1;

__END__

=head1 NAME

Business::OnlinePayment::IATSPayments - IATS Payments backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $tx =
    new Business::OnlinePayment( 'IATSPayments' );

  $tx->content(
      login          => 'TEST88', # agentCode
      password       => 'TEST88', #password 

      type           => 'CC',
      action         => 'Normal Authorization',
      amount         => '1.00',

      first_name     => 'Tofu',
      last_name      => 'Beast',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'UT',
      zip            => '84058',

      card_number    => '4111111111111111',
      expiration     => '09/20',
      cvv2           => '124',

      #optional
      description    => 'Business::OnlinePayment test',
      customer_ip    => '1.2.3.4',
      invoice_num    => 54,
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

=head1 SUPPORTED TRANSACTION TYPES

=head2 CC, Visa, MasterCard, American Express, Discover

Content required: type, login, action, amount, card_number, expiration.

=head2 Check

Content required: type, login, action, amount, name, account_number, routing_code.

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 METHODS AND FUNCTIONS

See L<Business::OnlinePayment> for the complete list. The following methods either override the methods in L<Business::OnlinePayment> or provide additional functions.  

=head2 result_code

Returns the response error code.

=head2 error_message

Returns the response error number.

=head2 action

The following actions are valid

  Normal Authorization
  Credit

=head1 COMPATIBILITY

Business::OnlinePayment::IATSPayments uses iATS WebServices ProcessLink 4.0
and (for tokenization support) iATS WebServices CustomerLink 4.0.

=head1 AUTHORS

Ivan Kohler <ivan-iatspayments@freeside.biz>

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=cut

