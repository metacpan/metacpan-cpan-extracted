package Business::OnlinePayment::GlobalPayments;

use warnings;
use strict;
use Carp qw(croak);
use vars qw($VERSION $DEBUG @ISA $me);
use base 'Business::OnlinePayment::HTTPS';
use XML::Simple 'XMLin'; # for parsing reply

$VERSION = 0.02;
$DEBUG = 0;
$me = __PACKAGE__;

my %trans_type = (
  'normal authorization' => 'Sale',
  'authorization only'   => 'Auth',
  'post authorization'   => 'Force',
  'void'                 => 'Void',
  'credit'               => 'Return',
);

my %cc_fields = (
  'GlobalUserName'  => 'login',
  'GlobalPassword'  => 'password',
  'TransType'       => sub { my %c = @_; $trans_type{ lc($c{action}) } },
  'CardNum'         => 'card_number',
  'ExpDate'         => sub { my %c = @_; join('', split /\D/,$c{'expiration'}) },
  'MagData'         => 'track2',
  'NameOnCard'      => sub { my %c = @_; $c{'first_name'} . ' ' . $c{'last_name'} },
  'Amount'          => 'amount',
  'InvNum'          => 'invoice_number',
  'Zip'             => 'zip',
  'Street'          => 'address',
  'CVNum'           => 'cvv2',
  'PNRef'           => 'order_number',
  'ExtData'         => \&ext_data,
);

sub ext_data {
  my %c = @_; # = $self->{_content}
  my $ext_data = '';
  if($c{'authorization'}) {
    $ext_data .= '<AuthCode>'.$c{'authorization'}.'</AuthCode>';
  }
  if($c{'force_duplicate'}) { # set to any true value
    $ext_data .= '<Force>T</Force>';
  }
  return $ext_data;
}

my %required_fields = (
  'All'    => [ qw(GlobalUserName GlobalPassword TransType) ],
  'Sale'   => [ qw(CardNum ExpDate Amount) ],
  'Auth'   => [ qw(CardNum ExpDate Amount) ],
  'Force'  => [ ],
  'Void'   => [ 'PNRef' ],
  'Return' => [ ],
  'Return.blind' => [ qw(CardNum ExpDate Amount) ],
);

sub set_defaults {
  my $self = shift;
  $self->port(443);
  $self->path('/GlobalPay/transact.asmx/ProcessCreditCard');
  $self->build_subs('domain', 'avs_code', 'cvv2_response' );

  return;
}

sub remap_fields {
  my ($self, %map) = @_;
  my %content = $self->content();

  foreach (keys(%map)) {
    if(ref($map{$_}) eq 'CODE') {
      $content{$_} = $map{$_}->(%content);
    }
    else {
      $content{$_} = $content{$map{$_}} if defined( $content{$map{$_}} );
    }
  }

  if(lc($content{'action'}) eq 'post authorization') {
    # GlobalPayments uses this transaction type to complete an authorized 
    # transaction, given either its PNRef (if it was authorized by an Auth 
    # transaction to the gateway) or its AuthCode (if it was authorized by 
    # telephone).
    if(!exists($content{'PNRef'}) and !exists($content{'authorization'})) {
      croak("missing required field(s): PNRef or AuthCode\n");
    }
  }

  $self->content(%content);
  return;
}

sub submit {
  my $self = shift;
  my $content = $self->{_content};
  $DB::single = 1 if $DEBUG;
  
  $self->setup_test if $self->test_transaction();

  die "missing required option: domain\n" if !$self->domain();
  $self->server($self->domain() . '.globalpay.com');

  $self->remap_fields(%cc_fields);

  my $action = $content->{'TransType'} or
    croak "unknown action: '".$content->{'action'}."'\n";
  $self->required_fields(@{ $required_fields{'All'} });
  $self->required_fields(@{ $required_fields{$action} });

  if($action eq 'Return' and !exists($content->{'PNRef'})) {
    # This handles the case where a credit is ordered "blind", without
    # an order_number.  Card information must be supplied.  Allowing 
    # these is somewhat risky, and can be disabled at the account level 
    # by the "Require Original PNRef" flag.
    $self->required_fields(@{ $required_fields{'Return.blind'} });
  }
  
  tie my %request, 'Tie::IxHash', 
    map { $_ => $self->{_content}->{$_} } keys(%cc_fields);

  $Business::OnlinePayment::HTTPS::DEBUG = $DEBUG;
  $DB::single = 1 if $DEBUG;
  my ($page, $response, %headers) = $self->https_post(\%request);

  $self->server_response($page);
  $self->is_success(0);
  if(not $response =~ /^200/) {
    $self->error_message("Connection failed: '$response'\n");
    return;
  }
  my $data = XMLin($page);
  if(!$data or !exists($data->{'Result'})) {
    $self->error_message("Malformed server response: '$page'\n");
    return;
  }
  $self->result_code($data->{'Result'});
  $self->avs_code($data->{'GetAVSResult'});
  $self->cvv2_response($data->{'GetCVResult'});
  if($data->{'Result'} != 0) {
    $self->error_message($data->{'Message'});
    return;
  }
  else {
    $self->is_success(1);
    $self->authorization($data->{'AuthCode'});
    $self->order_number($data->{'PNRef'});
    return;
  }
}

sub setup_test {
  my $self = shift;
  $self->domain('certapia');
# For test card information, see Global Transport API documentation.
}


=head1 NAME

Business::OnlinePayment::GlobalPayments - Global Transport backend for Business::OnlinePayment

=head1 SYNOPSIS

=head2 Initialization

  my $trans = new Business::OnlinePayment('GlobalPayments',
    domain => 'mymerchant' # Your account rep will supply this
  );

=head2 Sale transaction

  $trans->content(
    login           => 'login',
    password        => 'password',
    type            => 'CC',
    card_number     => '5500000000000004',
    expiration      => '0211',
    cvv2            => '255',
    invoice_number  => '123321',
    first_name      => 'Joe',
    last_name       => 'Schmoe',
    address         => '123 Anystreet',
    city            => 'Sacramento',
    state           => 'CA',
    zip             => '95824',
    action          => 'normal authorization',
    amount          => '24.99'
  );

=head2 Processing

  $trans->submit;
  if($trans->is_approved) {
    print "Approved\n",
          "Authorization: ", $trans->authorization, "\n",
          "Order ID: ", $trans->order_number, "\n"
  }
  else {
    print "Failed: ".$trans->error_message;
  }

=head2 Void transaction
  (or Return (credit) for full amount of original sale)

  $trans->content(
    login           => 'login',
    password        => 'password',
    action          => 'void', # or 'credit' for a Return
    order_number    => '1001245',
  );
  $trans->submit;

=head1 NOTES

The following transaction types are supported:
  Normal Authorization
  Authorization Only
  Post Authorization
  Credit
  Void

For Post Authorization, Credit, and Void, I<order_number> should be set to 
the order_number of the previous transaction.

Alternately, Post Authorization can be sent with I<authorization> set to an 
auth code obtained by telephone.  Similarly, Credit can be sent with credit 
account information instead of an I<order_number>.

By default, Global Transport will reject duplicate transactions (identical 
card number, expiration date, and amount) sent on the same day.  This can be 
overridden by setting I<force_duplicate> => 1.

=head1 AUTHOR

Mark Wells <mark@freeside.biz>

=head1 SUPPORT

Support for commercial users is available from Freeside Internet Services, 
Inc. <http://www.freeside.biz>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mark Wells, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Business::OnlinePayment::GlobalPayments
