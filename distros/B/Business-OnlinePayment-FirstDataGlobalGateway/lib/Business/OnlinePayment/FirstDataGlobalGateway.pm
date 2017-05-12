package Business::OnlinePayment::FirstDataGlobalGateway;
use base qw( Business::OnlinePayment );

use warnings;
use strict;
use Data::Dumper;
use Business::CreditCard;
use SOAP::Lite; #+trace => 'all';
#SOAP::Lite->import(+trace=>'debug');

our $VERSION = '0.01';
$VERSION = eval $VERSION; # modperlstyle: convert the string into a number

our @alpha = ( 'a'..'z', 'A'..'Z', '0'..'9' );

our %failure_status = (
  302 => 'nsf',
  501 => 'pickup',
  502 => 'stolen',
  503 => 'stolen', # "Fraud/Security violation"
  504 => 'blacklisted',
  509 => 'nsf',
  510 => 'nsf',
  519 => 'blacklisted',
  521 => 'nsf',
  522 => 'expired',
  530 => 'blacklisted',
  534 => 'blacklisted',
  # others are all "declined"
);
  

sub _info {
  {
    'info_compat'       => '0.01',
    'gateway_name'      => 'First Data Global Gateway e4',
    'gateway_url'       => 'https://www.firstdata.com/en_us/products/merchants/ecommerce/online-payment-processing.html',
    'module_version'    => $VERSION,
    'supported_types'   => [ 'CC' ], #, 'ECHECK' ],
    #'token_support'     => 1, # "Transarmor" is this, but not implemented yet
    'test_transaction'  => 1,

    'supported_actions' => [ 'Normal Authorization',
                             'Authorization Only',
                             'Post Authorization',
                             'Credit',
                             'Void',
                           ],
  };
}

sub set_defaults {
    my $self = shift;
    #my %opts = @_;

    $self->build_subs(qw( order_number avs_code cvv2_response
                          authorization failure_status result_code
                          ));
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
      ( 'normal authorization' => '00', # Purchase
        'authorization_only'   => '01', # 
        'post authorization'   => '02', # Pre-Authorization Completion
        # '' => '03', # Forced Post
        'credit'               => '04', # Refund
        # '' => '05', # Pre-Authorization Only
        'void'                 => '13', # Void
        #'reverse authorization' => '',

        # '' => '07', # PayPal Order
        # '' => '32', # Tagged Pre-Authorization Completion
        # '' => '33', # Tagged Void
        # '' => '34', # Tagged Refund
        # '' => '83', # CashOut (ValueLink, v9 or higher end point only)
        # '' => '85', # Activation (ValueLink, v9 or higher end point only)
        # '' => '86', # Balance Inquiry (ValueLink, v9 or higher end point only)
        # '' => '88', # Reload (ValueLink, v9 or higher end point only)
        # '' => '89', # Deactivation (ValueLink, v9 or higher end point only)
      );

    $content{'action'} = $actions{$action} || $action;

    # make sure there's a combined name
    $content{name} ||= $content{first_name} . ' ' . $content{last_name};

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

sub submit {
  my($self) = @_;

  $self->map_fields;

  $self->remap_fields(
        'login'             => 'ExactID',
        'password'          => 'Password',

        'action'            => 'Transaction_Type',

        'amount'            => 'DollarAmount',
        'currency'          => 'Currency',
        'card_number'       => 'Card_Number',
        'track1'            => 'Track1',
        'track2'            => 'Track2',
        'expiration'        => 'Expiry_Date',
        'name'              => 'CardHoldersName',
        'cvv2'              => 'VerificationStr2',

        'authorization'     => 'Authorization_Num',
        'order_number'      => 'Reference_No',

        'zip'               => 'ZipCode',
        'tax'               => 'Tax1Amount',
        'customer_id'       => 'Customer_Ref',
        'customer_ip'       => 'Client_IP',
        'email'             => 'Client_Email',

        #account_type      => 'accountType',

  );

  my %content = $self->content();

  $content{Expiry_Date} =~ s/\///;

  $content{country} ||= 'US';

  $content{VerificationStr1} =
    join('|', map $content{$_}, qw( address zip city state country ));
  $content{VerificationStr1} .= '|'. $content{'phone'}
    if $content{'type'} eq 'ECHECK';

  $content{CVD_Presence_Ind} = '1' if length($content{VerificationStr2});

  $content{'Reference_No'} ||= join('', map $alpha[int(rand(62))], (1..20) );

  #XXX this should be exposed as a standard B:OP field, not just recurring/no
  if ( defined($content{'recurring_billing'})
       && $content{'recurring_billing'} =~ /^[y1]/ ) {
    $content{'Ecommerce_Flag'} = '2';
  } else {
    #$content{'Ecommerce_Flag'} = '1'; 7?  if there's an IP?
  }

  my $base_uri;
  if ( $self->test_transaction ) {
    $base_uri =
      'https://api.demo.globalgatewaye4.firstdata.com/transaction';
  } else {
    $base_uri =
      'https://api.globalgatewaye4.firstdata.com/vplug-in/transaction';
  }

  my $proxy = "$base_uri/v11";

  my @transaction = map { SOAP::Data->name($_)->value( $content{$_} ) }
  grep { defined($content{$_}) }
  (qw(
    ExactID Password Transaction_Type DollarAmount Card_Number Transaction_Tag
    Track1 Track2 Authorization_Num Expiry_Date CardHoldersName
    VerificationStr1 VerificationStr2 CVD_Presence_Ind Reference_No ZipCode
    Tax1Amount Tax1Number Tax2Amount Tax2Number Customer_Ref Reference_3
    Language Client_IP Client_Email User_Name Currency PartialRedemption
    CAVV XID Ecommerce_Flag
 ));
   #TransarmorToken CardType EAN VirtualCard CardCost FraudSuspected
   #CheckNumber CheckType BankAccountNumber BankRoutingNumber CustomerName
   #CustomerIDType CustomerID

  my $wsdl = "$proxy/wsdl";
  my $client = SOAP::Lite->service($wsdl)->proxy($proxy)->readable(1);
  my $action_prefix = 'http://secure2.e-xact.com/vplug-in/transaction/rpc-enc';
  my $type_prefix = $action_prefix . '/encodedTypes';
  $client->on_action( sub { $action_prefix . '/' . $_[1] } );
  my $source = SOAP::Data->name('SendAndCommitSource')
                         ->value(\@transaction)
                         ->type("$type_prefix:Transaction");
  local $@;
  my $som = eval { $client->call('SendAndCommit', $source) };
  die $@ if $@;
  if ($som->fault) { # indicates a protocol error
    die $som->faultstring;
  }

  $DB::single = 1;
  $som->match('/Envelope/Body/SendAndCommitResponse/SendAndCommitResult');
  my $result = $som->valueof; # hashref of the result properties
  $self->is_success( $result->{Transaction_Approved} );
  $self->authorization( $result->{Authorization_Num} );
  $self->order_number( $result->{SequenceNo} );
  $self->avs_code( $result->{AVS} );
  $self->cvv2_response( $result->{CVV2} );

  if (!$self->is_success) {
    # note spelling of "EXact_Resp_Code"
    if ($result->{EXact_Resp_Code} ne '00') {
      # then there's something wrong with the transaction inputs
      # (invalid card number, malformed amount, attempt to refund a 
      # transaction that didn't happen, etc.)
      $self->error_message($result->{EXact_Message});
      $self->result_code($result->{EXact_Resp_Code});
      $self->failure_status('');
      # not a decline, as the transaction was never really detected
    } else {
      $self->error_message($result->{Bank_Message});
      $self->result_code($result->{Bank_Resp_Code});
      $self->failure_status(
        $failure_status{$result->{Bank_Resp_Code}} || 'declined'
      );
    }
  }
}

1;

__END__

=head1 NAME

Business::OnlinePayment::FirstDataGlobalGateway - First Data Global Gateway e4 backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $tx =
    new Business::OnlinePayment( 'FirstDataGlobalGateway' );

  $tx->content(
      login          => 'TEST88', # ExactID
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
      customer_ip    => '1.2.3.4',
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

=head2 (NOT YET) Check

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
  Authorization Only
  Post Authorization
  Credit
  Void

=head1 COMPATIBILITY

Business::OnlinePayment::FirstDataGlobalGateway uses the v11 version of the API
at this time.

=head1 AUTHORS

Ivan Kohler <ivan-firstdataglobalgateway@freeside.biz>

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=cut

