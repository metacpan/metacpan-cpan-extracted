package Business::OnlinePayment::MerchantCommerce;

use strict;
use Carp;
use Net::SSLeay qw/make_form post_https/;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader Business::OnlinePayment);
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = 0.01;

sub set_defaults {
    my ($self) = @_;
    $self->server('trans.atsbank.com');
    $self->port('443');
    $self->path('/cgi-bin/ats.cgi');
}

sub _action {
  my ($self, $action) = @_;

  my %content = $self->content();

  $content{_action} = $content{action};
  delete $content{action};

  for
  (
  'normal authorization','authorization only',
  'post authorization','ns_quicksale_cc',
  'visa','mastercard','american express','discover'
  )
  {
    $content{action} = 'ns_quicksale_cc'
      if $content{_action} eq $_
      or $content{type}    eq $_;
  }

  unless ( $content{action} ) {
    for ('check','ns_quicksale_check') {
      $content{action} = 'ns_quicksale_check'
        if $content{_action} eq $_
        or $content{type}    eq $_;
    }
  }                          
 
  if ( $content{action} eq 'ns_quicksale_cc' ) {
    if ( ! $content{_action} ) {
      if ( $content{type} =~ /^(post authorization|authorization only)$/ ) {
        $content{_action} = $content{type};
      }
      else {
        $content{_action} = 'normal authorization';
      }
    }
  }
  elsif ( $content{action} eq 'ns_quicksale_check' ) {
    $content{_action} = 'check';
  }

  Carp::croak('Specified action or type not supported by Merchant Commerce')
    unless $content{action};

  $self->content(%content);
}

sub _map {
  my ($self) = @_;
  my %content = $self->content;

  my %map = (name           => $content{action} eq 'ns_quicksale_cc' ? 'ccname' : 'ckname',
             login          => 'acctid',
             description    => 'ci_memo',
             address        => 'ci_billaddr1',
             city           => 'ci_billcity',
             state          => 'ci_billstate',
             zip            => 'ci_billzip',
             country        => 'ci_billcountry',
             phone          => 'ci_phone',
             email          => 'ci_email',
             card_number    => 'ccnum',
             account_number => 'ckacct',
             routing_code   => 'ckaba');
             
  while ( my($base_identifier, $mc_identifier) = each (%map) ) {
    if (defined $content{$base_identifier}) {
      $content{$mc_identifier} = $content{$base_identifier};
    }
  }
  
  $self->content(%content);
}



sub _required {
  my ($self) = @_;

  Carp::croak('require_avs function not supported by Merchant Commerce')
    if $self->require_avs;
  
  my %content = $self->content;
  my $test    = $self->test_transaction;
  
  if ( $test ) {
    $content{acctid} = 'TEST0';
  }

  if ( $content{action} eq 'ns_quicksale_cc' ) {
    ($content{expmon}, $content{expyear}) = $self->_date(\%content);
    if ( $test ) {
      $self->required_fields(qw~ccname~);
      $content{'ccnum'} = '5454545454545454';
    }
    else {
      $self->required_fields(qw~ccname ccnum~);
    }
  }
  
  if ( $content{_action} eq 'authorization only' ) {
    $self->build_subs('authrefcode');
    $content{authonly} = 1;
  }
  elsif ( $content{_action} eq 'post authorization' ) {
    $self->build_subs('authrefcode');
    $self->required_fields(qw~authrefcode~);
  }
  elsif ( $content{_action} eq 'check' ) {
    $self->required_fields(qw~ckname ckacct ckaba~);
  }
  
  $self->content(%content);
  $self->required_fields(qw~acctid amount~);
}

sub _date {
  my ($self, $content) = @_;

  if ( !($content->{expmon} and $content->{expyear}) and $content->{exp_date} ) {
    ($content->{expmon}, $content->{expyear}) = split /\//, $content->{exp_date};
  }
  Carp::croak('Merchant Commerce requires exp_date(mm/yyyy) or expmon(mm) and expyear(yyyy)')
    unless $content->{expmon} and $content->{expyear};

  $content->{expmon}, $content->{expyear};
}

sub submit {
  my($self) = @_;

  $self->_action;
  $self->_map;
  $self->_required;
  
  my %post_data = $self->get_fields(qw~ckname ckacct ckaba
                                       ccname ccnum expmon expyear authonly authrefcode
                                       acctid action amount subid usepost
                                       ci_companyname ci_phone ci_email ci_memo ci_dlnum ci_ssnum
                                       ci_billaddr1 ci_billaddr2 ci_billcity ci_billstate ci_billzip ci_billcountry
                                       ci_shipaddr1 ci_shipaddr2 ci_shipcity ci_shipstate ci_shipzip ci_shipcountry
                                       emailto emailfrom emailsubject emailtext
                                       recur_create recur_billingcycle recur_billingmax recur_start recur_amount~);

  while (my ($key,$value) = each (%post_data)) {
    delete $post_data{$key} unless defined $post_data{$key};
  }
  
  my $query  = make_form(%post_data);
  my $server = $self->server;
  my $port   = $self->port;
  my $path   = $self->path;

  $self->build_subs(qw/response_headers server_status accepted 
                       historyid orderid refcode unknown_result_code
                       unknown_response_format unknown_methods
                       declined error post_data conversation
                       server_response/);

  my ($content,$server_status,%headers) = post_https($server,$port,$path,'',$query);

  $self->post_data(\%post_data);
  $self->server_status($server_status);
  $self->server_response($content);
  $self->response_headers(\%headers);

  my @post_data       = map { "$_ => $post_data{$_}" } keys %post_data;
  my @headers         = map { "$_: $headers{$_}" }     keys %headers;
  my $conversation    = join "\n", @post_data,
                                   $server_status,
                                   @headers,
                                   $content;
  $self->conversation($conversation);  
  my $response_format = $content =~ s/^<html><body><plaintext>//;
  chomp $content;
  
  if ( $response_format ) {

    my @unknown_methods = ();
    for ( split /\n/, $content ) {
      my ($meth, $val) = split /=/, lc $_;
      unless ( $self->can($meth) )  {
        $self->build_subs($meth);
        push @unknown_methods, $meth;  
      }
      $self->$meth($val);
    }
    $self->unknown_functions(\@unknown_methods)
        if defined $unknown_methods[0];
        
    $self->result_code($self->accepted || $self->declined || $self->error);

    if ( $self->accepted ) {
      $self->is_success(1);
      $self->authorization($self->accepted);
    }
    elsif ( $self->declined || $self->error ) {
      $self->error_message($self->declined || $self->error);
    }
    else {
      $self->unknown_result_code(1);
      $self->error_message($conversation);
    };
    
  }
  else {
    $self->unknown_response_format(1);
    $self->error_message($conversation);
  }
}

1;

__END__

=head1 NAME

Business::OnlinePayment::MerchantCommerce

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $transaction = new Business::OnlinePayment("MerchantCommerce");
  $transaction->content(type        => 'VISA',
                        login       => '12345',
                        action      => 'Normal Authorization',
                        amount      => '5.00',
                        name        => 'Tim McIntyre',
                        card_number => '5454545454545454',
                        exp_date    => '12/2005');
  $transacton->submit;

  if($transaction->is_success) {
      print "Success! Authorization Code: " . $transaction->authorization."\n";
  } else {
      print "Failure!: " . $transaction->error_message."\n";
  }

=head1 DESCRIPTION

Merchant Commerce backend for Business::OnlinePayment.  Please see Buisness::OnlinePayment for details.

=head2 Supported transaction types

Visa, MasterCard, American Express, Discover, Check

=head2 Required content for all transactions

=over 4

=item * login or acctid

These keys are synonamous

=item * name

Alternatively you may use ccname for credit cards or ckname for checking withhdrawls.

=item * action or type

One of authorization only, post authorization, check, ns_quicksale_check, normal authorization, ns_quicksale_cc, visa, mastercard, american express, or discover.  

If set to authorization only MerchantCommerce will create a method(authrefcode) that will return an authrefcode for use in a post authorization.
 
If set to post authorization then authrefcode becomes a required field. 

Use check or ns_quicksale_check for checking withdrawls.  

The last six possibilities, normal authorization, ns_quicksale_cc, visa, mastercard, american express, and discover are all synonymous as far as MerchantCommerce is concerned.  

If for some reason type and action are both set action will take precidence.

=item * amount

=back

=head2 Additionally required content for credit cards

=over 4

=item * card_number or ccnum:

These keys are synonamous

=item * exp_date(mm/yyyy) or expmon(mm) and expyear(yyyy)

=back

=head2 Optional content for credit cards

=over 4

=item * authrefcode

A reference code returned from a previous authorization only action.  Only used with an action of post authorization.

=back

=head2 Additionally required content for checks

=over 4

=item * type or action

Must be set to check, or ns_quicksale_check.  

=item * account_number or ckacct

=item * routing_code or ckaba

=back

=head2 Optional content for all transactons

=over 4

=item * address or ci_billaddr1

=item * ci_billaddr2

=item * city or ci_billcity

=item * state or ci_billstate

=item * zip or ci_billzip

=item * country or ci_billcountry

=item * description or ci_memo

=item * subid

=item * usepost

=item * ci_companyname

=item * ci_phone

=item * ci_email

=item * ci_dlnum

=item * ci_ssnum 

=item * ci_shipaddr1

=item * ci_shipaddr2

=item * ci_shipcity

=item * ci_shipstate

=item * ci_shipzip

=item * ci_shipcountry

=item * emailto

=item * emailfrom

=item * emailsubject

=item * emailtext

=item * recur_create

=item * recur_billingcycle

=item * recur_billingmax

=item * recur_start

=item * recur_amount

=back

=head2 Content not supported

=over 4

=item * password

=item * bank_name

=item * invoice_number

=item * customer_id

=item * require_avs

=item * fax

=item * action => credit

=back

=head2 Methods

=over 4

=item * orderid

Can be called on any successful authorization.

=item * authrefcode

Can be called on successful authorization only.  Returns a reference code to be used in a later post authorization.

=item * historyid

Can be called on success or failure.  Usually but not always returned for unknown reasons.  Seems to be of dubious usefullness but is provided just in case.

=item * conversation

Returns a string showing the (almost) entire transaction.  The first lines are the content that was posted in the traditional hash name => value format.  After that is the server status line hopefully HTTP/1.1 200 OK.  Next come the response headers in their traditional NAME: value format.  Last but certainly not least is content of the response in the format of name=value.  The first line of the content part of the string should also contain the string <html><body><plaintext>.

=item * post_data

Returns a reference to a hash of the data that was posted to the server.

=item * server_response

Returns a string showing the content of the response from the server.  These will be in the form of name=value deliminated by \n.

=item * response_headers

Returns a reference to a hash containing the response headers.

=item * server_status

Returns the server status from the server response.

=item * accepted

On a successful transaction this method returns the same value as the authorization method.  This would also mean that is_success is true.

=item * declined

On a failed transaction this method will return the same value as error_message. This would also mean that is_success is false.

=item * error

On a failed transaction this method will return the same value as error_message. This would also mean that is_success is false.

=back

=head2 Please Note

If any of the following three methods are ever set it essentially means that you have found a bug in this module.  If you should decide to use them and you find that they are set please email me the string returned from the conversation method so that I can determine the problem.  Better yet fix it and send me that.  If you decide not to use them you should be fine.

=over 4

=item * unknown_result_code

Merchant Commerce has three known possible result codes, accepted, declined, and error.  If for some reason a different result code is returned this method will be set to true and error_message will contain the same value as the conversation method described above.  The result code should be contained on the first line of the content of the response.  That is the one containing <html><body><plaintext>.

=item * unknown_response_format
       
If the content part of the server response does not contain the <html><body><plaintext> as part of its first line this method will be set to true and error_message will contain the same value as the conversation method described above.

=item * unknown_methods

The Merchant Commerce server returns the content of its response as name=value pairs. This MerchantCommerce module parses the content and creates a method named name and sets it's value to value.  The methods orderid, refcode, and historyid are known content responses.  This method returns a reference to an array of method names that are unknown.  You could then call these methods to get the corresponding value.

=back

=head1 AUTHOR

Tim McIntyre, tmac@transport.com

=head1 DISCLAIMER

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

perl(1) L<Business::OnlinePayment>

=cut