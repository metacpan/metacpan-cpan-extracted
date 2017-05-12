package Business::OnlinePayment::Vanco;

use strict;
use Carp;
use Tie::IxHash;
use XML::Simple;
use XML::Writer;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Request::Common qw (POST);
use Date::Calc qw(Add_Delta_YM Add_Delta_Days);
use Business::OnlinePayment;
#use Business::OnlinePayment::HTTPS;
use vars qw($VERSION $DEBUG @ISA $me);

@ISA = qw(Business::OnlinePayment);  # Business::OnlinePayment::HTTPS 
$VERSION = '0.02';
$DEBUG = 0;
$me = 'Business::OnlinePayment::Vanco';

sub set_defaults {
    my $self = shift;
    my %opts = @_;

    # standard B::OP methods/data
    $self->server('www.vancoservices.com') unless $self->server;
    $self->port('443') unless $self->port;
    $self->path('/cgi-bin/ws.vps') unless $self->path;

    $self->build_subs(qw( order_number avs_code cvv2_response
                          response_page response_code response_headers
                     ));

    # module specific data
    foreach (qw( ClientID ProductID )) {
      $self->build_subs($_);

      if ( $opts{$_} ) {
          $self->$_( $opts{$_} );
          delete $opts{$_};
      }
    }

}

sub map_fields {
    my($self) = @_;

    my %content = $self->content();
    my $action = lc($content{'action'});

    # ACTION MAP 
    my %actions =
      ( 'normal authorization'            => 'EFTAddCompleteTransaction',
        'recurring authorization'         => 'EFTAddCompleteTransaction',
        'cancel recurring authorization'  => 'EFTDeleteTransaction',
      );
    $content{'RequestType'} = $actions{$action} || $action;

    # TYPE MAP
    my %types = ( 'visa'               => 'CC',
                  'mastercard'         => 'CC',
                  'american express'   => 'CC',
                  'discover'           => 'CC',
                  'check'              => 'ECHECK',
                );
    $content{'type'} = $types{lc($content{'type'})} || $content{'type'};
    $self->transaction_type($content{'type'});
    
    # CHECK/TRANSACTION TYPE MAP
    $content{'TransactionTypeCode'} = $content{'check_type'} || 'PPD'
      unless ( $content{'TransactionTypeCode'} 
            || $content{'RequestType'} eq 'EFTDeleteTransaction'); # kludgy

    # let FrequencyCode, StartDate, and EndDate be specified directly;
    unless($content{FrequencyCode}){
      my ($length,$unit) =
        ($self->{_content}->{interval} or '') =~
          /^\s*(\d+)\s+(day|month)s?\s*$/;

      my %daily   = (  '7' => 'W',
                      '14' => 'BW',
                    );
       
      my %monthly = (  '1' => 'M',
                       '3' => 'Q',
                      '12' => 'A',
                    );
       
      if ($length && $unit) {
        $content{'FrequencyCode'} = $daily{$length}
          if ($unit eq 'day');

        $content{'FrequencyCode'} = $monthly{$length}
          if ($unit eq 'month');
      }
    }

    unless($content{StartDate}){
      $content{'StartDate'} = $content{'start'};
    }

    unless($content{EndDate}){
      my ($year,$month,$day) =
        $content{StartDate} =~ /^\s*(\d{4})-(\d{1,2})-(\d{1,2})\s*$/
        if $content{StartDate};

      my ($periods) = $content{periods} =~/^\s*(\d+)\s*$/
        if $content{periods};

      my %daily   = (  'W' => '7',
                      'BW' => '14',
                    );
       
      my %monthly = (  'M' => '1',
                       'Q' => '3',
                       'A' => '12',
                    );

      if ($year && $month && $day && $periods) {
        if ($daily{$content{FrequencyCode}}) {
          my $days = ($periods - 1) * $daily{$content{FrequencyCode}};
          ($year, $month, $day) = Add_Delta_Days( $year, $month, $day, $days);
          $content{EndDate} = sprintf("%04d-%02d-%02d", $year, $month, $day);
        } 

        if ($monthly{$content{FrequencyCode}}) {
          my $months = ($periods - 1) * $monthly{$content{FrequencyCode}};
          ($year, $month, $day) = Add_Delta_YM( $year, $month, $day, 0, $months);
          $content{EndDate} = sprintf("%04d-%02d-%02d", $year, $month, $day);
        } 
      }

    }

    if ($action eq 'normal authorization'){
      my $time = time + 86400 if $self->transaction_type() eq 'ECHECK';
      $content{'FrequencyCode'} = 'O';
      $content{'StartDate'} = $content{'start'} || substr(today($time),0,10);
      $content{'EndDate'} = $content{'StartDate'};
    }


    # ACCOUNT TYPE MAP
    my %account_types = ('personal checking'   => 'C',
                         'personal savings'    => 'S',
                         'business checking'   => 'C',
                         'business savings'    => 'S',
                         'checking'            => 'C',
                         'savings'             => 'S',
                        );
    $content{'account_type'} = $account_types{lc($content{'account_type'})}
                               || $content{'account_type'};
    $content{'account_type'} = 'CC' if lc($content{'type'}) eq 'cc';

    # SHIPPING INFORMATION
    foreach (qw(name address city state zip)) {
      $content{"ship_$_"} = $content{$_} unless $content{"ship$_"};
    }

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

sub today {  
  my @time = localtime($_[0] ? shift : time);
  $time[5] += 1900;
  $time[4]++;
  sprintf("%04d-%02d-%02d %02d:%02d:%02d", reverse(@time[0..5]));
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
  unless($self->ClientID() && $self->ProductID()) {
    croak "ClientID and ProductID are required";
  }

  my $requestid = time . sprintf("%010u", rand() * 2**32);
  my $auth_requestid = $requestid . '0';
  my $req_requestid  = $requestid . '1';

  $self->map_fields();

  my @required_fields = qw(action login password);

  if ( lc($self->{_content}->{action}) eq 'normal authorization' ) {
    push @required_fields, qw( type amount name );

    push @required_fields, qw( card_number expiration )
      if ($self->transaction_type() eq "CC"); 
        
    push @required_fields,
      qw( routing_code account_number account_type )
      if ($self->transaction_type() eq "ECHECK");
        
  }elsif ( lc($self->{_content}->{action}) eq 'recurring authorization' ) {
    push @required_fields, qw( type interval start periods amount name );

    push @required_fields, qw( card_number expiration )
      if ($self->transaction_type() eq 'CC' ); 

    push @required_fields,
      qw( routing_code account_number account_type )
      if ($self->transaction_type() eq "ECHECK");

  }elsif ( lc($self->{_content}->{action}) eq 'cancel recurring authorization' ) {
    push @required_fields, qw( subscription );

  }else{
    croak "$me can't handle transaction type: ".
      $self->{_content}->{action}. " for ".
      $self->transaction_type();
  }

  $self->required_fields(@required_fields);

  tie my %auth, 'Tie::IxHash', (
                                 RequestType => 'Login',
                                 RequestID   => $auth_requestid,
                                 RequestTime => today(),
                               );

  tie my %requestvars, 'Tie::IxHash',
    $self->revmap_fields(
                          UserID      => 'login',
                          Password    => 'password',
                        );
  $requestvars{'ProductID'} = $self->ProductID();

  tie my %req, 'Tie::IxHash',
    $self->revmap_fields (
                           Auth    => \%auth,
                           Request => { RequestVars => \%requestvars },
                         );

  my $response = $self->_my_https_post(%req);
  return if $self->result_code();

  tie %auth, 'Tie::IxHash',
    $self->revmap_fields( RequestType => 'RequestType');
  $auth{'RequestID'}   = $req_requestid;
  $auth{'RequestTime'} = today();
  $auth{'SessionID'}   = $response->{Response}->{SessionID};

  my $client_id = $self->ClientID();
  my $cardexpmonth = $self->expdate_month($self->{_content}->{expiration});
  my $cardexpyear  = $self->expdate_year($self->{_content}->{expiration});
  my $account_number = ( defined($self->transaction_type())
                         && $self->transaction_type() eq 'CC')
                       ? $self->{_content}->{card_number}
                       : $self->{_content}->{account_number}
  ;

  tie %requestvars, 'Tie::IxHash',
    $self->revmap_fields(
                          ClientID            => \$client_id,
                          CustomerID          => 'customer_id',
                          CustomerName        => 'ship_name',   # defaults to 
                          CustomerAddress1    => 'ship_address',# values without
                          CustomerCity        => 'ship_city',   # ship_ prefix
                          CustomerState       => 'ship_state',  #
                          CustomerZip         => 'ship_zip',    #
                          CustomerPhone       => 'phone',
                          AccountType         => 'account_type',
                          AccountNumber       => \$account_number,
                          RoutingNumber       => 'routing_code',
                          CardBillingName     => 'name',
                          CardExpMonth        => \$cardexpmonth,
                          CardExpYear         => \$cardexpyear,
                          CardCVV2            => 'cvv2',
                          CardBillingAddr1    => 'address',
                          CardBillingCity     => 'city',
                          CardBillingState    => 'state',
                          CardBillingZip      => 'zip',
                          Amount              => 'amount',
                          StartDate           => 'StartDate',
                          EndDate             => 'EndDate',
                          FrequencyCode       => 'FrequencyCode',
                          TransactionTypeCode => 'TransactionTypeCode',
                          TransactionRef      => 'subscription',
                        );

  tie %req, 'Tie::IxHash',
    $self->revmap_fields (
                           Auth    => \%auth,
                           Request => { RequestVars => \%requestvars },
                         );

  $response = $self->_my_https_post(%req);
  $self->order_number($response->{Response}->{TransactionRef});

  $self->is_success(1);
  if ($self->result_code()) {
    $self->is_success(0);
    unless ( $self->error_message() ) { #additional logging information
      my %headers = %{$self->response_headers()};
      $self->error_message(
        "(HTTPS response: ". $self->result_code(). ") ".
        "(HTTPS headers: ".
          join(", ", map { "$_ => ". $headers{$_} } keys %headers ). ") ".
        "(Raw HTTPS content: ". $self->server_response(). ")"
      );
    }
  }

}

sub _my_https_post {
  my $self = shift;
  my %req = @_;
  my $post_data;
  my $writer = new XML::Writer( OUTPUT      => \$post_data,
                                DATA_MODE   => 1,
                                DATA_INDENT => 1,
#                                ENCODING    => 'us-ascii',
                              );
  $writer->xmlDecl();
  $writer->startTag('VancoWS');
  foreach ( keys ( %req ) ) {
    $self->_xmlwrite($writer, $_, $req{$_});
  }
  $writer->endTag('VancoWS');
  $writer->end();

  if ($self->test_transaction()) {
    $self->server('www.vancodev.com');
    $self->port('443');
    $self->path('/cgi-bin/wstest.vps');
  }

  my $url = "https://" . $self->server. ':';
  $url .= $self->port || '443';
  $url .= $self->path;

  my $ua = new LWP::UserAgent;
  my $res = $ua->request( POST( $url, 'Content_Type' => 'form-data',
                                      'Content' => [ 'xml' => $post_data ])
                        );

  warn $post_data if $DEBUG;
  my($page,$server_response,%headers) =  (
    $res->content,
    $res->code. ' ' . $res->message,
    map { $_ => $res->header($_) } $res->header_field_names
  );

  warn $page if $DEBUG;

  my $response;
  my $error;
  if ($server_response =~ /200/){
    $response = XMLin($page);
    if (  exists($response->{Response})
      && !exists($response->{Response}->{Errors})) {     # so much for docs
      $error->{ErrorDescription} = '';
      $error->{ErrorCode} = '';
    }elsif (ref($response->{Response}->{Errors}) eq 'ARRAY') {
      $error = $response->{Response}->{Errors}->[0];
    }else{
      $error = $response->{Response}->{Errors}->{Error};
    }
  }else{
    $error->{ErrorDescription} = "Server Failed";
    $error->{ErrorCode} = $server_response;
  }

  $self->result_code($error->{ErrorCode});
  $self->error_message($error->{ErrorDescription});

  $self->server_response($page);
  $self->response_page($page);
  $self->response_headers(\%headers);
  return $response;
}

sub _xmlwrite {
  my ($self, $writer, $item, $value) = @_;
  $writer->startTag($item);
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

Business::OnlinePayment::Vanco - Vanco Services backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  ####
  # One step transaction, the simple case.
  ####

  my $tx = new Business::OnlinePayment( "Vanco",
                                        ClientID  => 'CL1234',
                                        ProductID => 'EFT',
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

  ####
  # One step subscription, the simple case.
  ####

  my $tx = new Business::OnlinePayment( "Vanco",
                                        ClientID  => 'CL1234',
                                        ProductID => 'EFT',
                                      );
  $tx->content(
      type           => 'CC',
      login          => 'testdrive',
      password       => 'testpass',
      action         => 'Recurring Authorization',
      interval       => '7 days',
      start          => '2008-3-10',
      periods        => '16',
      amount         => '99.95',
      description    => 'Business::OnlinePayment test',
      customer_id    => 'vip',
      name           => 'Tofu Beast',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'GA',
      zip            => '84058',
      card_number    => '4111111111111111',
      expiration     => '09/02',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->order_number."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }
  my $subscription = $tx->order_number


  ####
  # Subscription cancellation.   It happens.
  ####

  $tx->content(
      subscription   => '99W2D',
      login          => 'testdrive',
      password       => 'testpass',
      action         => 'Cancel Recurring Authorization',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Cancellation processed successfully."\n";
  } else {
      print "Cancellation was rejected: ".$tx->error_message."\n";
  }


=head1 SUPPORTED TRANSACTION TYPES

=head2 CC, Visa, MasterCard, American Express, Discover

Content required: type, login, password, action, amount, name, card_number, expiration.

=head2 Check

Content required: type, login, password, action, amount, name, account_number, routing_code, account_type.

=head2 Subscriptions

Additional content required: interval, start, periods.

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
  recurring authorization
  cancel recurring authorization

=head2 interval

  Interval contains a number of digits, whitespace, and the units of days or months in either singular or plural form.
  
=head1 Setting Vanco parameters from content(%content)

The following rules are applied to map data to AuthorizeNet ARB parameters
from content(%content):

      # param => $content{<key>}
      Auth
        UserId                   =>  'login',
        Password                 =>  'password',
      Request
        RequestVars
          CustomerID             => 'customer_id',
          CustomerName           => 'ship_name',
          CustomerAddress1       => 'ship_address',
          CustomerCity           => 'ship_city',
          CustomerState          => 'ship_state',
          CustomerZip            => 'ship_zip',
          CustomerPhone          => 'phone',
          AccountType            => 'account_type',  # C, S, or CC
          AccountNumber          => 'account_number' # or card_number 
          RoutingNumber          => 'routing_code',
          CardBillingName        => 'name',
          CardExpMonth           => \( $month ), # YYYY-MM from 'expiration'
          CardExpYear            => \( $year ), # YYYY-MM from 'expiration'
          CardCVV2               => 'cvv2',
          CardBillingAddr1       => 'address',
          CardBillingCity        => 'city',
          CardBillingState       => 'state',
          CardBillingZip         => 'zip',
          Amount                 => 'amount',
          StartDate              => 'start',
          EndDate                => calculated_from start, periods, interval,
          FrequencyCode          => [O,M,W,BW,Q, or A determined from interval],
          TransactionTypeCode    => 'check_type', # (or PPD by default)

=head1 NOTE

To cancel a recurring authorization transaction, submit the TransactionRef
in the field "subscription" with the action set to "Cancel Recurring
Authorization".  You can get the TransactionRef from the authorization by
calling the order_number method on the object returned from the authorization.

=head1 COMPATIBILITY

Business::OnlinePayment::Vanco uses Vanco Services' "Standard Web Services
XML API"  as described on February 29, 2008.  The describing documents
are protected by a non-disclosure agreement.

See http://www.vancoservices.com/ for more information.

=head1 AUTHOR

Jeff Finucane, vanco@weasellips.com

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=cut

