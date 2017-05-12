## Business::OnlinePayment::Skipjack
##
## Original Skipjack.pm developed by New York Connect Net (http://nyct.net)
## Michael Bacarella <mbac@nyct.net>
##
## Modified for GetCareer.com by Slipstream.com
## Troy Davis <troy@slipstream.com>
##
## 'Adapted' (completely rewritten) for Business::OnlinePayment 
## by Fire2Wire Internet Services (http://www.fire2wire.com)
## Mark Wells <mark@pc-intouch.com>
## Kristian Hoffmann <khoff@pc-intouch.com>
## James Switzer <jamess@fire2wire.com>

## Required packages:
## Net::SSLeay
## Text::CSV
## Business::OnlinePayment


package Business::OnlinePayment::Skipjack;

use strict;
use Carp;
use Business::OnlinePayment 3;
use Business::OnlinePayment::HTTPS;
use Text::CSV_XS;
use vars qw( @ISA $VERSION $DEBUG );

$VERSION = "0.5";
$DEBUG = 0;

@ISA = qw( Business::OnlinePayment::HTTPS );

my %CC_ERRORS = (
        '-1'    =>      'Invalid length (-1)',
        '-35'   =>      'Invalid credit card number (-35)',
        '-37'   =>      'Failed communication (-37)',
        '-39'   =>      'Serial number is too short (-39)',
        '-51'   =>      'The zip code is invalid',
        '-52'   =>      'The shipto zip code is invalid',
        '-53'   =>      'Length of expiration date (-53)',
        '-54'   =>      'Length of account number date (-54)',
        '-55'   =>      'Length of street address (-55)',
        '-56'   =>      'Length of shipto street address (-56)',
        '-57'   =>      'Length of transaction amount (-57)',
        '-58'   =>      'Length of name (-58)',
        '-59'   =>      'Length of location (-59)',
        '-60'   =>      'Length of state (-60)',
        '-61'   =>      'Length of shipto state (-61)',
        '-62'   =>      'Length of order string (-62)',
        '-64'   =>      'Invalid phone number (-64)',
        '-65'	=>	'Empty name (-65)', 
        '-66'   =>      'Empty email (-66)',
        '-67'   =>      'Empty street address (-66)',
        '-68'   =>      'Empty city (-68)',
        '-69'   =>      'Empty state (-69)',
        '-70'   =>      'Empty zip code (-70)',
        '-71'   =>      'Empty order number (-71)',
        '-72'   =>      'Empty account number (-72)',
        '-73'   =>      'Empty expiration month (-73)',
        '-74'   =>      'Empty expiration year (-74)',
        '-75'   =>      'Empty serial number (-75)',
        '-76'   =>      'Empty transaction amount (-76)',
        '-79'   =>      'Length of customer name (-79)',
        '-80'   =>      'Length of shipto customer name (-80)',
        '-81'   =>      'Length of customer location (-81)',
        '-82'   =>      'Length of customer state (-82)',
        '-83'   =>      'Length of shipto phone (-83)',
        '-84'   =>      'Pos Error duplicate ordernumber (-84)',
        '-91'   =>      'Pos Error CVV2 (-91)',
        '-92'   =>      'Pos Error Approval Code (-92)',
        '-93'   =>      'Pos Error Blind Credits Not Allowed (-93)',
        '-94'   =>      'Pos Error Blind Credits Failed (-94)',
        '-95'   =>      'Pos Error Voice Authorizations Not Allowed (-95)',
        );

my %AVS_CODES = (
	'X' => 'Exact match, 9 digit zip', 
	'Y' => 'Exact match, 5 digit zip', 
	'A' => 'Address match only', 
	'W' => '9 digit match only', 
	'Z' => '5 digit match only', 
	'N' => 'No address or zip match', 
	'U' => 'Address unavailable', 
	'R' => 'Issuer system unavailable', 
	'E' => 'Not a mail/phone order', 
	'S' => 'Service not supported' 
	);

my %FIELDS = (
	name	=> 'sjname',
	email	=> 'Email',
	address	=> 'Streetaddress',
	city	=> 'City',
	state	=> 'State',
	zip	=> 'Zipcode',
	order_number	=> 'Ordernumber',
	card_number	=> 'Accountnumber',
	exp_month	=> 'Month',
	exp_year	=> 'Year',
	amount	=> 'Transactionamount',
	orderstring	=> 'Orderstring',
	phone	=> 'Shiptophone',
	login	=> 'Serialnumber',
	);

my %CHANGE_STATUS_FIELDS = (
	login        => 'szSerialNumber',
	password     => 'szDeveloperSerialNumber',
	order_number => 'szOrderNumber',
	# => 'szTransactionId',
	amount       => 'szAmount',
);

my @CHANGE_STATUS_RESPONSE = (
  'Serial Number',
  'Error Code',
  'NumRecs',
  #'Reserved',
  #'Reserved',
  #'Reserved',
  #'Reserved',
  #'Reserved',
  #'Reserved',
  #'Reserved',
  #'Reserved',
);

my @CHANGE_STATUS_RESPONSE_RECORD = (
  'Serial Number (Record)',
  'Amount',
  'Desired Status',
  'Status Response',
  'Status Response Message',
  'Order Number',
  'Transaction Id'
);

my %CHANGE_STATUS_ERROR_CODES = (
    '0' => 'Success',
   '-1' => 'Invalid Command',
   '-2' => 'Parameter Missing',
   '-3' => 'Failed retrieving response',
   '-4' => 'Invalid Status',
   '-5' => 'Failed reading security flags',
   '-6' => 'Developer serial number not found',
   '-7' => 'Invalid Serial Number',
   '-8' => 'Expiration year not four characters',
   '-9' => 'Credit card expired',
  '-10' => 'Invalid starting date (recurring payment)',
  '-11' => 'Failed adding recurring payment',
  '-12' => 'Invalid frequency (recurring payment)',
);

my %GET_STATUS_FIELDS = (
  login        => 'szSerialNumber',
  password     => 'szDeveloperSerialNumber',
  order_number => 'szOrderNumber',
  #date         => 'szDate', # would probably need some massaging
                             # and parse_SJAPI_TransactionStatusRequest would
                             # need to handle multiple records...
);

my @GET_STATUS_RESPONSE = (
  'Serial Number',
  'Error Code',
  'NumRecs',
  #'Reserved',
  #'Reserved',
  #'Reserved',
  #'Reserved',
  #'Reserved',
  #'Reserved',
  #'Reserved',
  #'Reserved',
);

my @GET_STATUS_RESPONSE_RECORD = (
  'Serial Number (Record)',
  'Amount',
  'Transaction Status Code',
  'Transaction Status Message',
  'Order Number',
  'Transaction Date',
  'Transaction Id',
  'Approval Code',
  'Batch Number',
);

my %GET_STATUS_ERROR_CODES = (
   '0' => 'Success',
  '-1' => 'Invalid Command',
  '-2' => 'Parameter Missing',
  '-3' => 'Failed retrieving response',
  '-4' => 'Invalid Status',
  '-5' => 'Failed reading security flags',
  '-6' => 'Developer serial number not found',
  '-7' => 'Invalid Serial Number',
  '-8' => 'Expiration year not four characters',
  '-9' => 'Credit card expired',
);

my %CUR_STATUS_CODES = (
  '0' => 'Idle',
  '1' => 'Authorized',
  '2' => 'Denied',
  '3' => 'Settled',
  '4' => 'Credited',
  '5' => 'Deleted',
  '6' => 'Archived',
  '7' => 'Pre-Auth',
);

my %PEND_STATUS_CODES = (
  '0' => 'Idle',
  '1' => 'Pending Credit',
  '2' => 'Pending Settlement ',
  '3' => 'Pending Delete',
  '4' => 'Pending Authorization',
  '5' => 'Pending Settle Force (for Manual Accts)',
  '6' => 'Pending Recurring',
);

sub _gen_ordernum { return int(rand(4000000000)); }

sub set_defaults
{
  my $self = shift;

  # For production
  $self->server('www.skipjackic.com');

  $self->port(443);

  return;
}


sub submit
{
  my $self = shift;
  my %c = $self->content;
  my (%input, %output);

  unless ( $c{type} =~ /(cc|visa|mastercard|american express|discover)/i ) {
    croak 'Business::OnlinePayment::Skipjack does not support "' . 
          $c{type}. '" transactions';
  }

  # skipjack kicks out "Length of transaction amount (-57)" or "Invalid amount"
  # if the amount is missing .XX
  $c{amount} = sprintf('%.2f', $c{amount})
    if defined($c{amount}) && length($c{amount});

  if ( lc($c{action}) eq 'normal authorization' ) {
    $self->{_action} = 'normal authorization';
    $self->path('/scripts/evolvcc.dll?AuthorizeAPI');

    $c{expiration} =~ /(\d\d?)\D*(\d\d?)/; # Slightly less crude way to extract the exp date.
    $c{exp_month} = sprintf('%02d',$1);
    $c{exp_year} = sprintf('%02d',$2);

    $c{order_number} = _gen_ordernum unless $c{order_number};

    $c{orderstring} = '0~'.$c{description}.'~'.$c{amount}.'~1~N~||'
        unless $c{orderstring};

    %input = map { ($FIELDS{$_} || $_), $c{$_} } keys(%c);

  } elsif ( $c{action} =~ /^(credit|void|post authorization)$/i ) {

    $self->path('/scripts/evolvcc.dll?SJAPI_TransactionChangeStatusRequest');

    %input = map { ($CHANGE_STATUS_FIELDS{$_} || $_), $c{$_} } keys %c;

    if ( lc($c{action} ) eq 'credit' ) {
      $self->{_action} = 'credit';
      $input{szDesiredStatus} = 'CREDIT';
    } elsif ( lc($c{action} ) eq 'void' ) {
      $self->{_action} = 'void';
      $input{szDesiredStatus} = 'DELETE';
    } elsif ( lc($c{action} ) eq 'post authorization' ) {
      $self->{_action} = 'postauth';
      $input{szDesiredStatus} = 'SETTLE';
    } else {
      die "fatal: $c{action} is not credit or void!";
    }

  } elsif ( lc($c{action}) eq 'status' ) {

    $self->{_action} = 'status';
    $self->path('/scripts/evolvcc.dll?SJAPI_TransactionStatusRequest');
    %input = map { ($GET_STATUS_FIELDS{$_} || $_), $c{$_} } keys(%c);

  } else {

    croak 'Business::OnlinePayment::Skipjack does not support "'.
          $c{action}. '" actions';

  }

  $self->server('developer.skipjackic.com') # test mode
    if $self->test_transaction();

  my( $page, $response ) = $self->https_post( %input );
  warn "\n$page\n" if $DEBUG;

  if ( $self->{_action} eq 'normal authorization' ) {
    %output = parse_Authorize_API($page);
  } elsif ( $self->{_action} =~ /^(credit|void|postauth)$/ ) {
    %output = parse_SJAPI_TransactionChangeStatusRequest($page);
  } elsif ( $self->{_action} eq 'status' ) {
    %output = parse_SJAPI_TransactionStatusRequest($page);
  } else {
    die "fatal: unknown action: ". $self->{_action};
  }

  $self->{_result} = \%output;
  $self->authorization($output{'AUTHCODE'});
  return;
}

sub is_success
{
  my $self = shift;

  if ( $self->{_action} eq 'normal authorization' ) {

    return( $self->{_result}->{'szIsApproved'} == 1 );

  } elsif ( $self->{_action} =~ /^(credit|void|postauth)$/ ) {

    return(       $self->{_result}{'Error Code'}       eq '0' # == 0 matches ''
            && uc($self->{_result}{'Status Response'}) eq 'SUCCESSFUL'
          );

  } elsif ( $self->{_action} eq 'status' ) {

    return( $self->{_result}{'Error Code'} eq '0' ); # == 0 matches ''

  } else {
    die "fatal: unknown action: ". $self->{_action};
  }

}

sub error_message
{
  my $self = shift;
  my $r;

  if($self->is_success) { return ''; }

  if ( $self->{_action} eq 'normal authorization' ) {

    if(($r = $self->{_result}->{'szReturnCode'}) < 0) { return $CC_ERRORS{$r}; }
    if($r = $self->{_result}->{'szAVSResponseMessage'}) { return $r; }
    if($r = $self->{_result}->{'szAuthorizationDeclinedMessage'}) { return $r; }

  } elsif ( $self->{_action} =~ /^(credit|void|postauth)$/ ) {

    if ( ( $r = $self->{_result}{'Error Code'} ) < 0 ) {
      return $CHANGE_STATUS_ERROR_CODES{$r};
    } else {
      return $self->{_result}{'Status Response Message'};
    }

  } elsif ( $self->{_action} eq 'status' ) {

    if ( ( $r = $self->{_result}{'Error Code'} ) < 0 ) {
      return $CHANGE_STATUS_ERROR_CODES{$r};
    } else {
      return $self->{_result}{'Status Response Message'};
    }

  } else {
    die "fatal: unknown action: ". $self->{_action};
  }

}


#sub result_code   { shift->{_result}->{'ezIsApproved'};              }
sub authorization { shift->{_result}{'szAuthorizationResponseCode'}; }
sub avs_code      { shift->{_result}{'szAVSResponseCode'};           }
sub order_number  { shift->{_result}{'szOrderNumber'};               }
sub cvv2_response { shift->{_result}{'szCVV2ResponseCode'};          } 
sub cavv_response { shift->{_result}{'szCAVVResponseCode'};          } 

sub status {
  my $self = shift;
  $CUR_STATUS_CODES{
    substr( $self->{_result}{'Transaction Status Code'}, 0, 1 )
  };
}

sub pending_status {
  my $self = shift;
  $PEND_STATUS_CODES{
    substr( $self->{_result}{'Transaction Status Code'}, 1, 2 )
  };
}

sub parse_Authorize_API
{

  my $page = shift;
  my %output;
  my $csv_keys = new Text::CSV_XS;
  my $csv_values = new Text::CSV_XS;

  my ($keystring, $valuestring) = split(/\r\n/, $page);
  $csv_keys->parse($keystring);
  $csv_values->parse($valuestring);
  @output{$csv_keys->fields()} = $csv_values->fields();

  return %output;

}

sub parse_SJAPI_TransactionChangeStatusRequest
{
  my $page = shift;

  my $csv = new Text::CSV_XS;

  my %output;

  my @records = split(/\r\n/, $page);

  $csv->parse(shift @records)
    or die "CSV parse failed on " . $csv->error_input;
  @output{@CHANGE_STATUS_RESPONSE} = $csv->fields();

  # we only handle a single record reponse, as that's all this module will
  #  currently submit...
  $csv->parse(shift @records)
    or die "CSV parse failed on " . $csv->error_input;
  @output{@CHANGE_STATUS_RESPONSE_RECORD} = $csv->fields();

  return %output;

}

sub parse_SJAPI_TransactionStatusRequest
{
  my $page = shift;

  my $csv = new Text::CSV_XS;

  my %output;

  my @records = split(/\r\n/, $page);

  #$csv->parse(shift @records)
  $csv->parse(shift @records)
    or die "CSV parse failed on " . $csv->error_input;
  @output{@GET_STATUS_RESPONSE} = $csv->fields();

  # we only handle a single record reponse, as that's all this module will
  #  currently submit...
  $csv->parse(shift @records)
    or die "CSV parse failed on " . $csv->error_input;
  @output{@GET_STATUS_RESPONSE_RECORD} = $csv->fields();

  return %output;

}

1;

__END__

=head1 NAME

Business::OnlinePayment::Skipjack - Skipjack backend module for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  ####
  # One step transaction, the simple case.
  ####

  my $tx = new Business::OnlinePayment("Skipjack");
  $tx->content(
      type           => 'VISA',
      login          => '000178101827', # "HTML serial number"
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      invoice_number => '100100',
      customer_id    => 'jsk',
      first_name     => 'Jason',
      last_name      => 'Kohles',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'UT',
      zip            => '84058',
      card_number    => '4007000000027',
      expiration     => '09/02',
      cvv2           => '1234', #optional
      #referer        => 'http://valid.referer.url/',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

  ###
  # Process a credit...
  ###

  my $tx = new Business::OnlinePayment( "Skipjack" );

  $tx->content(
      type           => 'VISA',
      login          => '000178101827', # "HTML serial number"
      password       => '100594217288', # "developer serial number"
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      invoice_number => '100100',
      customer_id    => 'jsk',
      first_name     => 'Jason',
      last_name      => 'Kohles',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'UT',
      zip            => '84058',
      card_number    => '4007000000027',
      expiration     => '09/02',
      cvv2           => '1234', #optional
      #referer        => 'http://valid.referer.url/',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card credited successfully: ".$tx->authorization."\n";
  } else {
      print "Credit was rejected: ".$tx->error_message."\n";
  }


=head1 SUPPORTED TRANSACTION TYPES

=head2 CC, Visa, MasterCard, American Express, Discover

Content required for Normal Authorization : login, action, amount, card_number,
expiration, name, address, city, state, zip, phone, email

Content required for Void or Credit: login, password, action, order_number

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>

=head1 PREREQUISITES

Net::SSLeay _or_ ( Crypt::SSLeay and LWP )

=head1 NOTE ON CREDITS

If you want to process credits, you must have your developer serial number
applied to your production account.  See
http://www.skipjack.com/resources/Education/serialnumbers.htm

=head1 STATUS

This modules supports a non-standard "status" action that corresponds to
Skipjack's TransactionStatusRequest.  It should be documented.

=head1 AUTHOR

Inspiried by (but no longer contains) code from:

  Original Skipjack.pm developed by New York Connect Net (http://nyct.net)
  Michael Bacarella <mbac@nyct.net>

  Modified for GetCareer.com by Slipstream.com
  Troy Davis <troy@slipstream.com>

'Adapted' (completely rewritten) for Business::OnlinePayment 
by Fire2Wire Internet Services (http://www.fire2wire.com)
Mark Wells <mark@pc-intouch.com>
Kristian Hoffmann <khoff@pc-intouch.com>
James Switzer <jamess@fire2wire.com>

Boring 0.2 update by Ivan Kohler <ivan-skipjack@420.am>

=head1 COPYRIGHT

Copyright (c) 2006 Fire2Wire Internet Services (http://www.fire2wire.com)
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

Inspiried by (but no longer contains) code from:

  Original Skipjack.pm developed by New York Connect Net (http://nyct.net)
  Michael Bacarella <mbac@nyct.net>

  Modified for GetCareer.com by Slipstream.com
  Troy Davis <troy@slipstream.com>

=head1 SEE ALSO

L<Business::OnlinePayment>

=cut
