package Business::OnlinePayment::PaymentsGateway;

use strict;
use Carp;
use Business::OnlinePayment;
use Net::SSLeay qw(sslcat);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $DEBUG);

@ISA = qw( Business::OnlinePayment );
$VERSION = '0.02';

$DEBUG = 0;

my %pg_response_code = (
  'A01' => 'Transaction approved/completed',
  'U01' => 'Merchant not allowed to access customer account',
  'U02' => 'Customer account is in the ACH Direct "known bad" list',
  'U03' => 'Merchant daily limit exceeded',
  'U04' => 'Merchant monthly limit exceeded',
  'U05' => 'AVS state/zipcode check failed',
  'U06' => 'AVS state/area code check failed',
  'U07' => 'AVS anonymous email check failed',
  'U08' => 'Account has more transactions than the merchant\'s daily velocity'.
           ' limit allows for',
  'U09' => 'Account has more transactions than the merchant\'s velocity'.
           ' window allows for',
  'U10' => 'Transaction has the same attributes as another transaction'.
           ' within the time set by the merchant',
  'U11' => '(RECUR TRANS NOT FOUND) Transaction types 40-42 only',
  'U12' => 'Original transaction not voidable or capture-able',
  'U13' => 'Transaction to be voided or captured was not found',
  'U14' => 'void/capture and original transaction types do not agree (CC/EFT)',
  'U18' => 'Void or Capture failed',
  #'U19' => 'Account ABA number if invalid',
  'U19' => 'Account ABA number is invalid',
  'U20' => 'Credit card number is invalid',
  'U21' => 'Date is malformed',
  'U22' => 'Swipe data is malformed',
  'U23' => 'Malformed expiration date',
  'U51' => 'Merchant is not "live"',
  'U52' => 'Merchant not approved for transaction type (CC or EFT)',
  'U53' => 'Transaction amount exceeds merchant\'s per transaction limit',
  'U54' => 'Merchant\'s configuration requires updating - call customer'.
           ' support',
  'U80' => 'Transaction was declined due to preauthorization (ATM Verify)'.
           ' result',
  'U84' => 'Preauthorizer not responding',
  'U85' => 'Preauthorizer error',
  'U83' => 'Transaction was declined due to authorizer declination',
  'U84' => 'Authorizer not responding',
  'U85' => 'Authorizer error',
  'U86' => 'Authorizer AVS check failed',
  'F01' => 'Required field is missing',
  'F03' => 'Name is not recognized',
  'F04' => 'Value is not allowed',
  'F05' => 'Field is repeated in message',
  'F07' => 'Fields cannot both be present',
  #'E10' => 'Merchant id or password in incorrect',
  'E10' => 'Merchant id or password is incorrect',
  'E20' => 'Transaction message not received (I/O flush required?)',
  'E90' => 'Originating IP not on merchant\'s approved IP list',
  'E99' => 'An unspecified error has occurred',
);

sub set_defaults {
  my $self = shift;
  $self->server('paymentsgateway.net');
  $self->port( 5050 );
}

sub map_fields {
  my $self = shift;
  my %content = $self->content();

  #ACTION MAP
  my %actions = (
    'normal authorization' => 0,
    'authorization only'   => 1,
    'post authorization'   => 2,
    'credit'               => 3,
  );

  my %types = (
    'visa'             => 10,
    'mastercard'       => 10,
    'american express' => 10,
    'discover'         => 10,
    'cc'               => 10,
    'check'            => 20,
    'echeck'           => 20,
  );

  #pg_type/action = action + type  

  $self->transaction_type( $actions{ lc($content{'action'}) } 
                           + $types{ lc($content{'type'  }) }    );

  #$self->content(%content);
}

sub revmap_fields {
    my($self, %map) = @_;
    my %content = $self->content();
    foreach(keys %map) {
        $content{$_} = ref($map{$_})
                         ? ${ $map{$_} }
                         : $content{$map{$_}};
    }
    $self->content(%content);
}

sub submit {
  my $self = shift;
  $self->map_fields();

  #my %content = $self->content();

  $self->revmap_fields( 
    'PG_MERCHANT_ID'                   => 'login',
    'pg_password'                      => 'password',
    'pg_transaction_type'              => \($self->transaction_type()),
    #'pg_merchant_data_1'
    #...
    #'pg_merchant_data_9'
    'pg_total_amount'                  => 'amount',
    #'pg_sales_tax_amount'
    'pg_consumer_id'                   => 'customer_id',
    'ecom_consumerorderid'             => 'invoice_number', #???
    #'ecom_walletid'                    =>
    'pg_billto_postal_name_company'    => 'company', #????
    'ecom_billto_postal_name_first'    => 'first_name', #????
    'ecom_billto_postal_name_last'     => 'last_name', # ????
    'ecom_billto_postal_street_line1'  => 'address',
    #'ecom_billto_postal_street_line2'
    'ecom_billto_postal_city'          => 'city',
    'ecom_billto_postal_stateprov'     => 'state',
    'ecom_billto_postal_postalcode'    => 'zip',
    'ecom_billto_postal_countrycode'   => 'country',
    'ecom_billto_telecom_phone_number' => 'phone',
    'ecom_billto_online_email'         => 'email',
    #'pg_billto_ssn'
    #'pg_billto_dl_number'
    #'pg_billto_dl_state'
    'ecom_payment_check_trn'           => 'routing_code',
    'ecom_payment_check_account'       => 'account_number',
    'ecom_payment_check_account_type'  => \'C', #checking
    #'ecom_payment_check_checkno'       =>
  );
  my %content = $self->content();

  # name (first_name & last_name ) ?
  # fax

  # card_number exp_date

  #account_number routing_code bank_name

  my @fields = (
    qw( PG_MERCHANT_ID pg_password pg_transaction_type ),
    ( map { "pg_merchant_$_" } ( 1 .. 9 ) ),
    qw( pg_total_amount pg_sales_tax_amount pg_consumer_id
        ecom_consumerorderid ecom_walletid
        pg_billto_postal_name_company
        ecom_billto_postal_name_first ecom_billto_postal_name_last
        ecom_billto_postal_street_line1
        ecom_billto_postal_street_line2
        ecom_billto_postal_city ecom_billto_postal_stateprov
        ecom_billto_postal_postalcode ecom_billto_postal_countrycode
        ecom_billto_telecom_phone_number ecom_billto_online_email
        pg_billto_ssn pg_billto_dl_number pg_billto_dl_state
    )
  );

  if ( $content{'type'} =~ /^e?check$/i ) {
    push @fields, qw( ecom_payment_check_trn
                      ecom_payment_check_account
                      ecom_payment_check_account_type );
  } else {
    croak $content{'type'}. ' not (yet) supported';
  }

  my $request = join("\n", map { "$_=". $content{$_} }
                           grep { defined($content{$_}) && $content{$_} ne '' }
                           @fields                     ).
                "\nendofdata\n";

  warn $request if $DEBUG;

  warn "TEST: ". $self->test_transaction(). "\n" if $DEBUG;

  $self->port( $self->port() + 1000 ) if $self->test_transaction();

  warn "SERVER ". $self->server(). "\n" if $DEBUG;
  warn "PORT ". $self->port(). "\n" if $DEBUG;

  my $reply = sslcat( $self->server(), $self->port(), $request );
  die "no reply from server" unless $reply;

  warn "reply from server: $reply\n" if $DEBUG;

  my %response = map { /^(\w+)=(.*)$/ or /^(endofdata)()$/
                         or warn "can't parse response line: $_";
                       ($1, $2);
                     } split(/\n/, $reply);

  if ( $response{'pg_response_type'} eq 'A' ) {
    $self->is_success(1);
    $self->result_code($response{'pg_response_code'});
    $self->authorization($response{'pg_authorization_code'});
  } else {
    $self->is_success(0);
    $self->result_code($response{'pg_response_code'});
    $self->error_message( $pg_response_code{$response{'pg_response_code'}}.
                          ': '. $response{'pg_response_description'} );
  }
}

1;

__END__

=head1 NAME

Business::OnlinePayment::PaymentsGateway - PaymentsGateway.Net backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $tx = new Business::OnlinePayment("PaymentsGateway");
  $tx->content(
      type           => 'CHECK',
      login          => 'test',
      password       => 'test',
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      invoice_number => '100100',
      name           => 'Tofu Beast',
      account_number => '12345',
      routing_code   => '123456789',
      bank_name      => 'First National Test Bank',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 NOTE

This module only implements 'ECHECK' (ACH) transactions at this time.  Credit
card transactions are not (yet) supported.

=head1 COMPATIBILITY

This module implements the interface documented in the
"PaymentsGateway.net Integration Guide, Version 2.1, September 2002"

=head1 AUTHOR

Ivan Kohler <ivan-paymentsgateway@420.am>

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>

=cut

