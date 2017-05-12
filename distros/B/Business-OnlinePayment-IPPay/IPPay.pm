package Business::OnlinePayment::IPPay;

use strict;
use Carp;
use Tie::IxHash;
use XML::Simple;
use XML::Writer;
use Locale::Country;
use Business::OnlinePayment;
use Business::OnlinePayment::HTTPS;
use vars qw($VERSION $DEBUG @ISA $me);

@ISA = qw(Business::OnlinePayment::HTTPS);
$VERSION = '0.09';
$VERSION = eval $VERSION; # modperlstyle: convert the string into a number

$DEBUG = 0;
$me = 'Business::OnlinePayment::IPPay';

sub _info {
  {
    'info_compat'           => '0.01',
    'module_version'        => $VERSION,
    'supported_types'       => [ qw( CC ECHECK ) ],
    'supported_actions'     => { 'CC' => [
                                     'Normal Authorization',
                                     'Authorization Only',
                                     'Post Authorization',
                                     'Void',
                                     'Credit',
                                     'Reverse Authorization',
                                   ],
                                   'ECHECK' => [
                                     'Normal Authorization',
                                     'Void',
                                     'Credit',
                                   ],
                                 },
    'CC_void_requires_card' => 1,
    'ECHECK_void_requires_account' => 1,
  };
}

sub set_defaults {
    my $self = shift;
    my %opts = @_;

    # standard B::OP methods/data
    $self->server('gtwy.ippay.com') unless $self->server;
    $self->port('443') unless $self->port;
    $self->path('/ippay') unless $self->path;

    $self->build_subs(qw( order_number avs_code cvv2_response
                          response_page response_code response_headers
                     ));

    $DEBUG = exists($opts{debug}) ? $opts{debug} : 0;

    # module specific data
    my %_defaults = ();
    foreach my $key (keys %opts) {
      $key =~ /^default_(\w*)$/ or next;
      $_defaults{$1} = $opts{$key};
      delete $opts{$key};
    }
    $self->{_defaults} = \%_defaults;
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
      ( 'normal authorization'            => 'SALE',
        'authorization only'              => 'AUTHONLY',
        'post authorization'              => 'CAPT',
        'reverse authorization'           => 'REVERSEAUTH',
        'void'                            => 'VOID',
        'credit'                          => 'CREDIT',
      );
    my %check_actions =
      ( 'normal authorization'            => 'CHECK',
        'void'                            => 'VOIDACH',
        'credit'                          => 'REVERSAL',
      );

    if ($self->transaction_type eq 'CC') {
      $content{'TransactionType'} = $actions{$action} || $action;
    } elsif ($self->transaction_type eq 'ECHECK') {

      $content{'TransactionType'} = $check_actions{$action} || $action;

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

    $content{Origin} = 'RECURRING' 
      if ($content{recurring_billing} &&$content{recurring_billing} eq 'YES' );

    # stuff it back into %content
    $self->content(%content);

}

sub expdate_month {
  my ($self, $exp) = (shift, shift);
  my $month;
  if ( defined($exp) and $exp =~ /^(\d+)\D+\d*\d{2}$/ ) {
    $month  = sprintf( "%02d", $1 );
  }elsif ( defined($exp) and $exp =~ /^(\d{2})\d{2}$/ ) {
    $month  = sprintf( "%02d", $1 );
  }
  return $month;
}

sub expdate_year {
  my ($self, $exp) = (shift, shift);
  my $year;
  if ( defined($exp) and $exp =~ /^\d+\D+\d*(\d{2})$/ ) {
    $year  = sprintf( "%02d", $1 );
  }elsif ( defined($exp) and $exp =~ /^\d{2}(\d{2})$/ ) {
    $year  = sprintf( "%02d", $1 );
  }
  return $year;
}

sub revmap_fields {
  my $self = shift;
  tie my(%map), 'Tie::IxHash', @_;
  my %content = $self->content();
  map {
        my $value;
        if ( ref( $map{$_} ) eq 'HASH' ) {
          $value = $map{$_} if ( keys %{ $map{$_} } );
        }elsif( ref( $map{$_} ) ) {
          $value = ${ $map{$_} };
        }elsif( exists( $content{ $map{$_} } ) ) {
          $value = $content{ $map{$_} };
        }

        if (defined($value)) {
          ($_ => $value);
        }else{
          ();
        }
      } (keys %map);
}

sub submit {
  my($self) = @_;

  $self->is_success(0);
  $self->map_fields();

  my @required_fields = qw(action login password type);

  my $action = lc($self->{_content}->{action});
  my $type = $self->transaction_type();
  if ( $action eq 'normal authorization'
    || $action eq 'credit'
    || $action eq 'authorization only' && $type eq 'CC')
  {
    push @required_fields, qw( amount );

    push @required_fields, qw( card_number expiration )
      if ($type eq "CC"); 
        
    push @required_fields,
      qw( routing_code account_number name ) # account_type
      if ($type eq "ECHECK");
        
  }elsif ( $action eq 'post authorization' && $type eq 'CC') {
    push @required_fields, qw( order_number );
  }elsif ( $action eq 'reverse authorization' && $type eq 'CC') {
    push @required_fields, qw( order_number card_number expiration amount );
  }elsif ( $action eq 'void') {
    push @required_fields, qw( order_number amount );

    push @required_fields, qw( authorization card_number )
      if ($type eq "CC");

    push @required_fields,
      qw( routing_code account_number name ) # account_type
      if ($type eq "ECHECK");

  }else{
    croak "$me can't handle transaction type: ".
      $self->{_content}->{action}. " for ".
      $self->transaction_type();
  }

  my %content = $self->content();
  foreach ( keys ( %{($self->{_defaults})} ) ) {
    $content{$_} = $self->{_defaults}->{$_} unless exists($content{$_});
  }
  if ($self->test_transaction()) {
    $content{'login'} = 'TESTTERMINAL';
  }
  $self->content(%content);

  $self->required_fields(@required_fields);

  #quick validation because ippay dumps an error indecipherable to the end user
  if (grep { /^routing_code$/ } @required_fields) {
    unless( $content{routing_code} =~ /^\d{9}$/ ) {
      $self->_error_response('Invalid routing code');
      return;
    }
  }

  my $transaction_id = $content{'order_number'};
  unless ($transaction_id) {
    my ($page, $server_response, %headers) = $self->https_get('dummy' => 1);
    warn "fetched transaction id: (HTTPS response: $server_response) ".
         "(HTTPS headers: ".
         join(", ", map { "$_ => ". $headers{$_} } keys %headers ). ") ".
         "(Raw HTTPS content: $page)"
      if $DEBUG > 1;
    return unless $server_response=~ /^200/;
    $transaction_id = $page;
  }

  my $cardexpmonth = $self->expdate_month($content{expiration});
  my $cardexpyear  = $self->expdate_year($content{expiration});
  my $cardstartmonth = $self->expdate_month($content{card_start});
  my $cardstartyear  = $self->expdate_year($content{card_start});
 
  my $amount;
  if (defined($content{amount})) {
    $amount = sprintf("%.2f", $content{amount});
    $amount =~ s/\.//;
  }

  my $check_number = $content{check_number} || "100"  # make one up
    if($content{account_number});

  my $terminalid = $content{login} if $type eq 'CC';
  my $merchantid = $content{login} if $type eq 'ECHECK';

  my $country = country2code( $content{country}, LOCALE_CODE_ALPHA_3 );
  $country  = country_code2code( $content{country},
                                 LOCALE_CODE_ALPHA_2,
                                 LOCALE_CODE_ALPHA_3
                               )
    unless $country;
  $country = $content{country}
    unless $country;
  $country = uc($country) if $country;

  my $ship_country =
    country2code( $content{ship_country}, LOCALE_CODE_ALPHA_3 );
  $ship_country  = country_code2code( $content{ship_country},
                                 LOCALE_CODE_ALPHA_2,
                                 LOCALE_CODE_ALPHA_3
                               )
    unless $ship_country;
  $ship_country = $content{ship_country}
    unless $ship_country;
  $ship_country = uc($ship_country) if $ship_country;

  tie my %ach, 'Tie::IxHash',
    $self->revmap_fields(
                          #wtf, this is a "Type"" attribute of the ACH element,
                          # not a child element like the others
                          #AccountType         => 'account_type',
                          AccountNumber       => 'account_number',
                          ABA                 => 'routing_code',
                          CheckNumber         => \$check_number,
                        );

  tie my %industryinfo, 'Tie::IxHash',
    $self->revmap_fields(
                          Type                => 'IndustryInfo',
                        );

  tie my %shippingaddr, 'Tie::IxHash',
    $self->revmap_fields(
                          Address             => 'ship_address',
                          City                => 'ship_city',
                          StateProv           => 'ship_state',
                          Country             => \$ship_country,
                          Phone               => 'ship_phone',
                        );

  unless ( $type ne 'CC' || keys %shippingaddr ) {
    tie %shippingaddr, 'Tie::IxHash',
      $self->revmap_fields(
                            Address             => 'address',
                            City                => 'city',
                            StateProv           => 'state',
                            Country             => \$country,
                            Phone               => 'phone',
                          );
  }
  delete $shippingaddr{Country} unless $shippingaddr{Country};

  tie my %shippinginfo, 'Tie::IxHash',
    $self->revmap_fields(
                          CustomerPO          => 'CustomerPO',
                          ShippingMethod      => 'ShippingMethod',
                          ShippingName        => 'ship_name',
                          ShippingAddr        => \%shippingaddr,
                        );

  tie my %req, 'Tie::IxHash',
    $self->revmap_fields(
                          TransactionType     => 'TransactionType',
                          TerminalID          => 'login',
#                          TerminalID          => \$terminalid,
#                          MerchantID          => \$merchantid,
                          TransactionID       => \$transaction_id,
                          RoutingCode         => 'RoutingCode',
                          Approval            => 'authorization',
                          BatchID             => 'BatchID',
                          Origin              => 'Origin',
                          Password            => 'password',
                          OrderNumber         => 'invoice_number',
                          CardNum             => 'card_number',
                          CVV2                => 'cvv2',
                          Issue               => 'issue_number',
                          CardExpMonth        => \$cardexpmonth,
                          CardExpYear         => \$cardexpyear,
                          CardStartMonth      => \$cardstartmonth,
                          CardStartYear       => \$cardstartyear,
                          Track1              => 'track1',
                          Track2              => 'track2',
                          ACH                 => \%ach,
                          CardName            => 'name',
                          DispositionType     => 'DispositionType',
                          TotalAmount         => \$amount,
                          FeeAmount           => 'FeeAmount',
                          TaxAmount           => 'TaxAmount',
                          BillingAddress      => 'address',
                          BillingCity         => 'city',
                          BillingStateProv    => 'state',
                          BillingPostalCode   => 'zip',
                          BillingCountry      => \$country,
                          BillingPhone        => 'phone',
                          Email               => 'email',
                          UserIPAddr          => 'customer_ip',
                          UserHost            => 'UserHost',
                          UDField1            => 'UDField1',
                          UDField2            => 'UDField2',
                          UDField3            => \"$me $VERSION", #'UDField3',
                          ActionCode          => 'ActionCode',
                          IndustryInfo        => \%industryinfo,
                          ShippingInfo        => \%shippinginfo,
                        );
  delete $req{BillingCountry} unless $req{BillingCountry};

  my $post_data;
  my $writer = new XML::Writer( OUTPUT      => \$post_data,
                                DATA_MODE   => 1,
                                DATA_INDENT => 1,
                                ENCODING    => 'us-ascii',
                              );
  $writer->xmlDecl();
  $writer->startTag('JetPay');
  foreach ( keys ( %req ) ) {
    $self->_xmlwrite($writer, $_, $req{$_});
  }
  $writer->endTag('JetPay');
  $writer->end();

  warn "$post_data\n" if $DEBUG > 1;

  my ($page,$server_response,%headers) = $self->https_post($post_data);

  warn "$page\n" if $DEBUG > 1;

  my $response = {};
  if ($server_response =~ /^200/){
    $response = XMLin($page);
    if (  exists($response->{ActionCode}) && !exists($response->{ErrMsg})) {
      $self->error_message($response->{ResponseText});
    }else{
      $self->error_message($response->{ErrMsg});
    }
#  }else{
#    $self->error_message("Server Failed");
  }

  $self->result_code($response->{ActionCode} || '');
  $self->order_number($response->{TransactionID} || '');
  $self->authorization($response->{Approval} || '');
  $self->cvv2_response($response->{CVV2} || '');
  $self->avs_code($response->{AVS} || '');

  $self->is_success($self->result_code() eq '000' ? 1 : 0);

  unless ($self->is_success()) {
    unless ( $self->error_message() ) {
      if ( $DEBUG ) {
        #additional logging information, possibly too sensitive for an error msg
        # (IPPay seems to have a failure mode where they return the full
        #  original request including card number)
        $self->error_message(
          "(HTTPS response: $server_response) ".
          "(HTTPS headers: ".
            join(", ", map { "$_ => ". $headers{$_} } keys %headers ). ") ".
          "(Raw HTTPS content: $page)"
        );
      } else {
        $self->error_message('No ResponseText or ErrMsg was returned by IPPay (enable debugging for raw HTTPS response)');
      }
    }
  }

}

sub _error_response {
  my ($self, $error_message) = (shift, shift);
  $self->result_code('');
  $self->order_number('');
  $self->authorization('');
  $self->cvv2_response('');
  $self->avs_code('');
  $self->is_success( 0);
  $self->error_message($error_message);
}

sub _xmlwrite {
  my ($self, $writer, $item, $value) = @_;

  my %att = ();
  if ( $item eq 'ACH' ) {
    $att{'Type'} = $self->{_content}->{'account_type'}
      if $self->{_content}->{'account_type'}; #necessary so we don't pass empty?
    $att{'SEC'}  = 'PPD';
  }

  $writer->startTag($item, %att);

  if ( ref( $value ) eq 'HASH' ) {
    foreach ( keys ( %$value ) ) {
      $self->_xmlwrite($writer, $_, $value->{$_});
    }
  }else{
    $writer->characters($value);
  }

  $writer->endTag($item);
}

1;

__END__

=head1 NAME

Business::OnlinePayment::IPPay - IPPay backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $tx =
    new Business::OnlinePayment( "IPPay",
                                 'default_Origin' => 'PHONE ORDER',
                               );
  $tx->content(
      type           => 'VISA',
      login          => 'testdrive',
      password       => '', #password 
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment test',
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

Returns the response error description text.

=head2 server_response

Returns the complete response from the server.

=head1 Handling of content(%content) data:

=head2 action

The following actions are valid

  normal authorization
  authorization only
  reverse authorization
  post authorization
  credit
  void

=head1 Setting IPPay parameters from content(%content)

The following rules are applied to map data to IPPay parameters
from content(%content):

      # param => $content{<key>}
      TransactionType     => 'TransactionType',
      TerminalID          => 'login',
      TransactionID       => 'order_number',
      RoutingCode         => 'RoutingCode',
      Approval            => 'authorization',
      BatchID             => 'BatchID',
      Origin              => 'Origin',
      Password            => 'password',
      OrderNumber         => 'invoice_number',
      CardNum             => 'card_number',
      CVV2                => 'cvv2',
      Issue               => 'issue_number',
      CardExpMonth        => \( $month ), # MM from MM(-)YY(YY) of 'expiration'
      CardExpYear         => \( $year ), # YY from MM(-)YY(YY) of 'expiration'
      CardStartMonth      => \( $month ), # MM from MM(-)YY(YY) of 'card_start'
      CardStartYear       => \( $year ), # YY from MM(-)YY(YY) of 'card_start'
      Track1              => 'track1',
      Track2              => 'track2',
      ACH
        AccountNumber       => 'account_number',
        ABA                 => 'routing_code',
        CheckNumber         => 'check_number',
      CardName            => 'name',
      DispositionType     => 'DispositionType',
      TotalAmount         => 'amount' reformatted into cents
      FeeAmount           => 'FeeAmount',
      TaxAmount           => 'TaxAmount',
      BillingAddress      => 'address',
      BillingCity         => 'city',
      BillingStateProv    => 'state',
      BillingPostalCode   => 'zip',
      BillingCountry      => 'country',           # forced to ISO-3166-alpha-3
      BillingPhone        => 'phone',
      Email               => 'email',
      UserIPAddr          => 'customer_ip',
      UserHost            => 'UserHost',
      UDField1            => 'UDField1',
      UDField2            => 'UDField2',
      ActionCode          => 'ActionCode',
      IndustryInfo
        Type                => 'IndustryInfo',
      ShippingInfo
        CustomerPO          => 'CustomerPO',
        ShippingMethod      => 'ShippingMethod',
        ShippingName        => 'ship_name',
        ShippingAddr
          Address             => 'ship_address',
          City                => 'ship_city',
          StateProv           => 'ship_state',
          Country             => 'ship_country',  # forced to ISO-3166-alpha-3
          Phone               => 'ship_phone',

=head1 NOTE

=head1 COMPATIBILITY

Version 0.07 changes the server name and path for IPPay's late 2012 update.

Business::OnlinePayment::IPPay uses IPPay XML Product Specifications version
1.1.2.

See http://www.ippay.com/ for more information.

=head1 AUTHORS

Original author: Jeff Finucane

Current maintainer: Ivan Kohler <ivan-ippay@freeside.biz>

Reverse Authorization patch from dougforpres

=head1 ADVERTISEMENT

Need a complete, open-source back-office and customer self-service solution?
The Freeside software includes support for credit card and electronic check
processing with IPPay and over 50 other gateways, invoicing, integrated
trouble ticketing, and customer signup and self-service web interfaces.

http://freeside.biz/freeside/

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=cut

