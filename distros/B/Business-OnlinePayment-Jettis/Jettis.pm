package Business::OnlinePayment::Jettis;

use strict;
use Carp;
use Business::OnlinePayment;
#use Business::CreditCard;
use Net::SSLeay qw( make_form post_https make_headers );
use URI;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $DEBUG);

require Exporter;

@ISA = qw(Exporter AutoLoader Business::OnlinePayment);
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '0.02';

$DEBUG = 0;

my %error = (
    0 => "Success",
    1 => "Missing Input",
    2 => "Missing CC Number",
    3 => "Missing First Name",
    4 => "Missing Last Name",
    5 => "Missing Zip Code",
    6 => "Missing Expiration Month",
    7 => "Missing Expiration Year",
    8 => "Missing Username",
    9 => "Missing V Password",
   10 => "No Agree Terms",
   11 => "No Agree Age",
   12 => "Missing City",
   13 => "Missing State",
   14 => "Username Length",
   15 => "Username Invalid Chars",
   16 => "Password Length",
   17 => "Different V Password",
   18 => "Same V Password",
   19 => "Invalid Email",
   20 => "Missing Address",
   21 => "Invalid Phone Number",
   22 => "Failed Mod 10",
   23 => "Invalid Expiration",
   24 => "Negative Database",
   25 => "Missing Data",
   26 => "Database Error",
   27 => "Username Exists",
   28 => "Invalid Store Params",
   29 => "Unknown",
   30 => "Procedure",
   31 => "CC Number",
   32 => "Invalid Version",
   33 => "Invalid Country Code",
   34 => "Country Bin",
   35 => "High Fraud Country",
   36 => "Different Country IP",
   37 => "No Account",
   38 => "IP Fraud",
   39 => "Password Maintenance",
   40 => "Password Invalid Chars",
   41 => "Duplicate Membership",
   42 => "Velocity",
   43 => "Too many consecutive errors",
   44 => "Missing Password",
   45 => "Zip Code Quotes",
   46 => "State Quotes",
   47 => "Street Quotes",
   48 => "Missing Country",
   49 => "Country Invalid Chars",
   50 => "Missing Quantity",
   51 => "Quantity Invalid Chars", 
   52 => "Missing IP Address",
   53 => "Invalid IP Address",  
   54 => "Merchant Text Area Quotes",
   55 => "First Name Length",
   56 => "Last Name Length",
   57 => "Zip Length",
   58 => "City Length",
   59 => "State Length",
   60 => "Email Length",
   61 => "Address Length",
   62 => "Merch Area Length",
   63 => "Quantity Limit Per Day Exceeded",
   64 => "Amount Limit Per Day Exceeded",
   65 => "Quantity Limit Per Month Exceeded",
   66 => "Amount Limit Per Month Exceeded",
   67 => "Credit CC Num Mismatch",
   68 => "Credit Price Mismatch",
   69 => "Merch ID Mismatch",
   70 => "Credit Prod ID Mismatch",
   71 => "Invalid Bill Item ID",
   72 => "Invalid Prod ID",
   73 => "Invalid Merch ID",
   74 => "Fraud Scrubbing", 
   75 => "Already Credited",
   76 => "Credit Card BIN Exclusion",
   77 => "Email Exclusion",
   78 => "IP not reversible",
   79 => "Invalid Bill ID",
   80 => "Auth already settled",
   81 => "Invalid Account Num",
   82 => "Mail Zip Code Exclusion",
   83 => "Missing IP Code",
   84 => "Username Mismatch",
   85 => "Password Mismatch",
  101 => "Bank Timeout",
  102 => "Invalid Request",
  103 => "Incomplete",
  104 => "Memory Allocation",
  105 => "Bugcheck",
  106 => "Inhibited",
  108 => "Reject",
  110 => "CC Number",
  111 => "Expiration Date",
  112 => "Prefix",
  113 => "Amount",
  114 => "Linkdown",
  115 => "SENO",
  116 => "Merchant Number",
  117 => "Request",
  118 => "Merchant Bank Down",
  119 => "Invalid Transaction Type",
  120 => "Call Center",
  121 => "Pickup",
  122 => "Declined",
  123 => "Account Declined",
  124 => "Fraud Alert",
  125 => "Overlimit",
  126 => "Too Small",
  127 => "Pin Error",
  128 => "Card Expired",
  129 => "Bank Invalid Email",
  130 => "Batch Unbalanced",
  131 => "Batch Unopened",
  140 => "Control Invalid",
  141 => "Control Readonly",
  142 => "Control Bad",
  150 => "Duplicate Address",
  151 => "Unknown Address",
  160 => "Duplicate Merchant Number",
  161 => "Merchant Busy",
  162 => "Merchant Inhibit",
  170 => "AVS",
  171 => "AVS Unmatched Void",
  172 => "AVS Void Failure",
  180 => "Invalid IP code",
  181 => "Invalid CVV2",
  182 => "Invalid Original Transaction Date",
  198 => "Server Timeout",
  199 => "Unrecognized",
  300 => "Re-Presented Check",
  301 => "Invalid ID",
  400 => "Failed Routing Mod 10",
  401 => "Missing Bank Name",
  402 => "Bank Name Quotes",
  403 => "Missing Bank Account Number",
  404 => "Invalid Bank Account Number", 
  405 => "Missing Bank Routing Number",
  406 => "Invalid Bank Routing Number",  
  407 => "Missing Check Number",
  408 => "Unsupported Transaction Type",
  409 => "Invalid Bank Name",
  999 => "Unknown Error",
);

sub set_defaults {
    my $self = shift;
    $self->server('join.billingservices.com');
    $self->port('443');
    $self->path('/psys/txnUrl');
    $self->build_subs(qw( product_id merchant_id ));
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
    my %content = $self->content();

    my $action = lc($content{'action'});
    if ( $action eq 'normal authorization' ) {
    } else {
      croak "$action not (yet) supported";
    }
    
    my $type = lc($content{'type'});
    if ( $type eq 'check' ) {
    } else {
      croak "$type not (yet) supported";
    }

    $self->revmap_fields(
        SUCCESS_URL     => \'https://secure.suicidegirls.com/',
	PRODUCT_ID      => \($self->product_id()),
	MERCHANT_ID     => 'login',
	VERSION         => \'1.0',
	SOR             => \'N',
	REMOTE_ADDR     => \'10.0.0.1',
	TERMS_AGREE     => \'Y',
	CHECK_AGE       => \'Y',
	PAY_METHOD_ID   => \'A', # ACH
	PRICE           => 'amount',
	QTY             => \'1',
	CHECK_NUM       => \'1000',
	BANK_ACCT_NUM   => 'account_number',
	BANK_ROUT_NUM   => 'routing_code',
	BANK_NAME       => 'bank_name',
	EMAIL           => 'email',
	FIRST_NAME      => 'first_name',
	LAST_NAME       => 'last_name',
	ADDR_STREET_1   => 'address',
	ADDR_CITY       => 'city',
	ADDR_STATE      => 'state',
	ADDR_ZIP        => 'zip',
	ADDR_COUNTRY    => \'840', # US
	MERCH_TEXT_AREA => 'description',
    );

    my %post_data = $self->get_fields(qw(
        SUCCESS_URL PRODUCT_ID MERCHANT_ID VERSION SOR REMOTE_ADDR
        TERMS_AGREE CHECK_AGE PAY_METHOD_ID PRICE QTY CHECK_NUM BANK_ACCT_NUM
        BANK_ROUT_NUM BANK_NAME EMAIL FIRST_NAME LAST_NAME ADDR_STREET_1
        ADDR_CITY ADDR_STATE ADDR_ZIP ADDR_COUNTRY MERCH_TEXT_AREA
    ));

    my $pd = make_form(%post_data);
    my $s = $self->server();
    my $p = $self->port();
    my $t = $self->path();
    my $headers = make_headers('Referer' => $content{'referer'} );
    my($page,$server_response,%headers) = post_https($s,$p,$t,$headers,$pd);

#    warn join('-',%headers);

    my $uri = new URI $headers{'LOCATION'} or die "no LOCATION: header!";
    my %response = $uri->query_form or die "no response in LOCATION: header!";

    if ( $response{'RESULT_MAIN'} eq '0' ) {
      $self->is_success(1);
      $self->result_code('0');
      $self->authorization($response{'AUTHORIZATION_CODE'});
    } else {
      $self->is_success(0);
      $self->result_code($response{'RESULT_MAIN'});
      $self->error_message($error{$response{'RESULT_MAIN'}});
    }

}

1;
__END__

=head1 NAME

Business::OnlinePayment::Jettis - Jettis backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $tx = new Business::OnlinePayment("Jettis");
  $tx->content(
      type           => 'CHECK',
      login          => 'test', #ClientID
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
      print "Check processed successfully: ".$tx->authorization."\n";
  } else {
      print "Check was rejected: ".$tx->error_message."\n";
  }

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 NOTE

This module only implements 'CHECK' (ACH) functionality at this time.  Credit
card transactions are not (yet) supported.

=head1 COMPATIBILITY

This module implements an interface to Jettis.com's HTTPS API.  Unfortunately,
no documentation is publicly available.  Jettis won't even send their full
manual to their customers - they insist on sending only few-page snippets at a
time.

=head1 AUTHOR

Steve Simitzis <steve@saturn5.com>
Ivan Kohler <ivan-jettis@420.am>

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>

=cut

