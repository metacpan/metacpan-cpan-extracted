package Business::OnlinePayment::NMI;

use strict;
use Carp;
use Business::OnlinePayment 3;
use Business::OnlinePayment::HTTPS;
use Digest::MD5 qw(md5_hex);
use URI::Escape;
use vars qw($VERSION @ISA $DEBUG);

@ISA = qw(Business::OnlinePayment::HTTPS);
$VERSION = '0.03';

$DEBUG = 0;

sub _info {
  {
    'info_compat'           => '0.01',
    'gateway_name'          => 'Network Merchants',
    'gateway_url'           => 'https://www.nmi.com',
    'module_version'        => $VERSION,
    'supported_types'       => [ 'CC', 'ECHECK' ],
    'supported_actions'     => {
                                  CC => [
                                    'Normal Authorization',
                                    'Authorization Only',
                                    'Post Authorization',
                                    'Credit',
                                    'Void',
                                    ],
                                  ECHECK => [
                                    'Normal Authorization',
                                    'Credit',
                                    'Void',
                                    ],
    },
  };
}

my %actions = (
  'normal authorization' => 'sale',
  'authorization only'   => 'auth',
  'post authorization'   => 'capture',
  'credit'               => 'refund',
  'void'                 => 'void',
);
my %types = (
  'cc'  => 'creditcard',
  'echeck' => 'check',
);

my %fields = (
# NMI Direct Post API, June 2007
  action          => 'type', # special
  login           => 'username',
  password        => 'password',
  card_number     => 'ccnumber',
  expiration      => 'ccexp',
  name            => 'checkname',
  routing_code    => 'checkaba',
  account_number  => 'checkaccount',
  account_holder_type => 'account_holder_type',
  account_type    => 'account_type',
  amount          => 'amount',
  cvv2            => 'cvv',
  payment         => 'payment', # special
  description     => 'orderdescription',
  invoice_number  => 'orderid',
  customer_ip     => 'ipaddress',
  tax             => 'tax',
  freight         => 'shipping',
  po_number       => 'ponumber',
  first_name      => 'firstname',
  last_name       => 'lastname',
  company         => 'company',
  address         => 'address1',
  city            => 'city',
  state           => 'state',
  zip             => 'zip',
  country         => 'country',
  order_number    => 'transactionid', # used for capture/void/refund
);

$fields{"ship_$_"} = 'shipping_'.$fields{$_} 
  foreach(qw(first_name last_name company address city state zip country)) ;

my %required = (
'ALL'             => [ qw( type username password payment ) ],
'sale'            => [ 'amount' ],
'sale:creditcard' => [ 'ccnumber', 'ccexp' ],
'sale:check'      => [ qw( checkname checkaba checkaccount account_holder_type account_type ) ],
'auth:creditcard' => [ qw( amount ccnumber ccexp ) ],
'capture'         => [ 'amount', 'transactionid' ],
'refund'          => [ 'amount', 'transactionid' ],
'void'            => [ 'transactionid' ],
# not supported: update
),

my %optional = (
'ALL'             => [],
'sale'            => [ qw( orderdescription orderid ipaddress tax 
                           shipping ponumber firstname lastname company 
                           address1 city state zip country phone fax email 
                           shipping_firstname shipping_lastname
                           shipping_company shipping_address1 shipping_city 
                           shipping_state shipping_zip shipping_country 
                           ) ],
'sale:creditcard' => [ 'cvv' ],
'sale:check' => [],
'auth:creditcard' => [ qw( orderdescription orderid ipaddress tax 
                           shipping ponumber firstname lastname company 
                           address1 city state zip country phone fax email 
                           shipping_firstname shipping_lastname
                           shipping_company shipping_address1 shipping_city 
                           shipping_state shipping_zip shipping_country 
                           cvv ) ],
'capture'         => [ 'orderid' ],
'refund'          => [ 'amount' ],
);

my %failure_status = (
200 => 'decline',
201 => 'decline',
202 => 'nsf',
203 => 'nsf',
223 => 'expired',
250 => 'pickup',
252 => 'stolen',
# add others here as needed; very little code uses failure_status at present
);

sub set_defaults {
    my $self = shift;
    $self->server('secure.networkmerchants.com');
    $self->port('443');
    $self->path('/api/transact.php');
    $self->build_subs(qw(avs_code cvv2_response failure_status));
}

sub map_fields {
  my($self) = shift;

  my %content = $self->content();

  if($self->test_transaction) {
    # Public test account.
    $content{'login'} = 'demo';
    $content{'password'} = 'password';
  }

  $content{'payment'} = $types{lc($content{'type'})} or die "Payment method '$content{type}' not supported.\n";
  $content{'action'} = $actions{lc($content{'action'})} or die "Transaction type '$content{action}' not supported.\n";

  $content{'expiration'} =~ s/\D//g if defined($content{'expiration'});

  $content{'account_type'} ||= 'personal checking';
  @content{'account_holder_type', 'account_type'} = 
    map {lc} split /\s/, $content{'account_type'};
  $content{'ship_name'} = $content{'ship_first_name'} ? 
      ($content{'ship_first_name'}.' '.$content{'ship_last_name'}) : '';
  $self->content(%content);
}

sub submit {
    my($self) = @_;

    $self->map_fields();

    $self->remap_fields(%fields);

    my %content = $self->content;
    my $type = $content{'type'}; # what we call "action"
    my $payment = $content{'payment'}; # what we call "type"
    if ( $DEBUG >= 3  ) {
      warn "content:$_ => $content{$_}\n" foreach keys %content;
    }

    my @required_fields = ( @{$required{'ALL'}} );
    push @required_fields, @{$required{$type}} if exists($required{$type});
    push @required_fields, @{$required{"$type:$payment"}} if exists($required{"$type:$payment"});

    $self->required_fields(@required_fields);

    my @allowed_fields = @required_fields;
    push @allowed_fields, @{$optional{'ALL'}};
    push @allowed_fields, @{$optional{$type}} if exists($optional{$type});
    push @allowed_fields, @{$optional{"$type:$payment"}} if exists($required{"$type:$payment"});

    my %post_data = $self->get_fields(@allowed_fields);

    if ( $DEBUG ) {
      warn "post_data:$_ => $post_data{$_}\n" foreach keys %post_data;
    }

    my($page,$server_response) = $self->https_post(\%post_data);
    if ( $DEBUG ) {
      warn "response page: $page\n";
    }

    my $response;
    if ($server_response =~ /200/){
      $response = {map { split '=', $_, 2 } split '&', $page};
    }
    else {
      die "HTTPS error: '$server_response'\n";
    }

    $response->{$_} =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg
      foreach keys %$response;

    if ( $DEBUG ) {
      warn "response:$_ => $response->{$_}\n" foreach keys %$response;
    }

    $self->is_success(0);
    my $error;
    if( $response->{response} == 1 ) {
      $self->is_success(1);
    }
    elsif( $response->{response} == 2 ) {
      $error = $response->{responsetext};
      my $code = $response->{response_code};
      $self->failure_status($failure_status{$code}) if exists($failure_status{$code});
    }
    elsif( $response->{response} == 3 ) {
      $error = "Transaction error: '".$response->{responsetext}."'";
    }
    else {
      $error = "Could not interpret server response: '$page'";
    }
    $self->order_number($response->{transactionid});
    $self->authorization($response->{authcode});
    $self->avs_code($response->{avsresponse});
    $self->cvv2_response($response->{cvvresponse});
    $self->result_code($response->{response_code});
    $self->error_message($error);
    $self->server_response($response);
}

1;
__END__

=head1 NAME

Business::OnlinePayment::NMI - Network Merchants backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $tx = new Business::OnlinePayment("NMI");
  $tx->content(
      login          => 'mylogin',
      password       => 'mypass',
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      invoice_number => '100100',
      name           => 'Tofu Beast',
      card_number    => '46464646464646',
      expiration     => '11/08',
      address        => '1234 Bean Curd Lane, San Francisco',
      zip            => '94102',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 SUPPORTED TRANSACTION TYPES

=head2 Credit Card

Normal Authorization, Authorization Only, Post Authorization, Void, Credit.

=head2 Check

Normal Authorization, Void, Credit.

=head1 NOTES

Credit is handled using NMI's 'refund' action, which applies the credit against 
a specific payment.

Post Authorization, Void, and Credit require C<order_number> to be set with the 
transaction ID of the previous authorization.

=head1 COMPATIBILITY

This module implements the NMI Direct Post API, June 2007 revision.

=head1 AUTHOR

Mark Wells <mark@freeside.biz>

Based in part on Business::OnlinePayment::USAePay by Jeff Finucane 
<jeff@cmh.net>.

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=head1 ADVERTISEMENT

Need a complete, open-source back-office and customer self-service solution?
The Freeside software includes support for credit card and electronic check
processing, integrated trouble ticketing, and customer signup and self-service
web interfaces.

http://freeside.biz/freeside/

=cut

