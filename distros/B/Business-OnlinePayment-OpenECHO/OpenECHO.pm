##############################################################################
# Business::OnlinePayment::OpenECHO
#
# Credit card transactions via SSL to
# Electronic Clearing House (ECHO) Systems
#
# Refer to ECHO's documentation for more info
# http://www.openecho.com/echo_gateway_guide.html
#
# AUTHOR
# Michael Lehmkuhl <michael@electricpulp.com>
#
# SPECIAL THANKS
# Jim Darden <jdarden@echo-inc.com>
# Dan Browning <db@kavod.com>
#
# BUSINESS::ONLINEPAYMENT IMPLEMENTATION
# Ivan Kohler <ivan-openecho@420.am>
#
# VERSION HISTORY
# + v1.2	08/17/2002 Corrected problem with certain string comparisons.
# + v1.3	08/23/2002 Converted Interchange GlobalSub to Vend::Payment module.
# + v1.3.1	11/12/2002 Updated the OpenECHO_example.perl test script.
# + v1.4	11/18/2002 Corrected a problem with Submit method when using LWP.
# + v1.5        03/29/2003 Updated for additional status and avs_result codes.
# + v1.6        08/26/2003 Cleaned up code (salim qadeer sqadeer@echo-inc.com)
# + v1.6.2      09/23/2003 Added DH transaction type (salim qadeer sqadeer@echo-inc.com)
# --------
# + v0.1        08/26/2004 Business::OnlinePayment implementation
# + v0.2        09/13/2004
# + v0.3        03/25/2006
#
# Copyright (C) 2002 Electric Pulp. <info@electricpulp.com>
# Copyright (C) 2004-2006 Ivan Kohler
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA  02111-1307  USA.
#
################################################################################

package Business::OnlinePayment::OpenECHO;

use strict;
use Carp;
use Business::OnlinePayment 3;
use Business::OnlinePayment::HTTPS;
use vars qw($VERSION @ISA $DEBUG);

@ISA = qw(Business::OnlinePayment::HTTPS);
$VERSION = '0.03';
$DEBUG = 0;

sub set_defaults {
	my $self = shift;

	$self->server('wwws.echo-inc.com');
	$self->port('443');
	$self->path('/scripts/INR200.EXE');

	$self->build_subs(qw(
	  order_number avs_code
	                 ));
        # order_type
	# md5 cvv2_response cavv_response

}

#map_fileds originally from AuthorizeNet.pm

sub map_fields {
    my($self) = @_;

    ##AD (Address Verification)  - 0.18 cents
    #AS (Authorization) - 0.18 cents
    #AV (Authorization with Address Verification) - 0.18 cents
    #CR (Credit) - 0.18 cents + 0.12 cents (discount fee returned to merchant)
    #DS (Deposit) - 0.18 cents + 0.12 cents
    #ES (Authorization and Deposit) - 0.18 cents + 0.12 cents + an extra 0.17%
    #EV (Authorization and Deposit with Address Verification) - 0.18 cents + 0.12 cents
    ##CK (System check) - 0.18 cents
    #DV (Electronic Check Verification) - check your contract
    #DD (Electronic Check Debit with Verification) - check your contract
    #DH (Electronic Check Debit ACH Only) - check your contract
    #DC (Electronic Check Credit) - check your contract

    my %content = $self->content();

    if ( lc($content{'action'}) eq 'void' ) {
      $self->is_success(0);
      $self->error_message( 'OpenECHO gateway does not support voids; '.
                            'try action => "Credit" '
                          );
      return;
    }

    my $avs = $self->require_avs;
    $avs = 1 unless defined($avs) && length($avs); #default AVS on unless explicitly turned off

    my %map;
    if (
      $content{'type'} =~ /^(cc|visa|mastercard|american express|discover)$/i
    ) {
      if ( $avs ) {
        %map = ( 'normal authorization' => 'EV',
                 'authorization only'   => 'AV',
                 'credit'               => 'CR',
                 'post authorization'   => 'DS',
                 #'void'                 => 'VOID',
               );
      } else {
        %map = ( 'normal authorization' => 'ES',
                 'authorization only'   => 'AS',
                 'credit'               => 'CR',
                 'post authorization'   => 'DS',
                 #'void'                 => 'VOID',
               );
      }
    } elsif ( $content{'type'} =~ /^e?check$/i ) {
      %map = ( 'normal authorization' => 'DD',
               'authorization only'   => 'DV',
               'credit'               => 'DC',
               'post authorization'   => 'DH',
               #'void'                 => 'VOID',
             );
    } else {
      croak 'Unknown type: '. $content{'type'};
    }

    $content{'type'} = $map{lc($content{'action'})}
      or croak 'Unknown action: '. $content{'action'};

    $self->transaction_type($content{'type'});

    # stuff it back into %content
    $self->content(%content);

}

sub submit {
    my($self) = @_;

    $self->map_fields();
    $self->remap_fields(
        #                => 'order_type',
        type             => 'transaction_type',
        #action          =>
        login            => 'merchant_echo_id',
        password         => 'merchant_pin',
        #                => 'isp_echo_id',
        #                => 'isp_pin',
        #transaction_key =>
        authorization    => 'authorization', # auth_code => 'authorization',
        customer_ip      => 'billing_ip_address',
        #                   'billing_prefix',
        name             => 'billing_name',
        first_name       => 'billing_first_name',
        last_name        => 'billing_last_name',
        company          => 'billing_company_name',
        address          => 'billing_address_1',
        #                => 'billing_address_2',
        city             => 'billing_city',
        state            => 'billing_state',
        zip              => 'billing_zip',
        country          => 'billing_country',
        phone            => 'billing_phone',
        fax              => 'billing_fax',
        email            => 'billing_email',
        card_number      => 'cc_number',
        #                => 'ccexp_month',
        #                => 'ccexp_year',
        #                => 'counter',
        #                => 'debug',

        #XXX#            => 'ec_*',

        'amount'         => 'grand_total',
        #                => 'merchant_email',
        #invoice_number  =>
        customer_id      => 'merchant_trace_nbr',
        #                => 'original_amount',
        #                => 'original_trandate_mm',
        #                => 'original_trandate_dd',
        #                => 'original_trandate_yyyy',
        #                => 'original_reference',
        order_number     => 'order_number',
        #                => 'shipping_flag',

        #description       =>
        #currency          =>

        #ship_last_name    =>
        #ship_first_name   =>
        #ship_company      =>
        #ship_address      =>
        #ship_city         =>
        #ship_state        =>
        #ship_zip          =>
        #ship_country      =>

        #expiration        =>
        cvv2              => 'cnp_security',

        #check_type        =>
        #account_name      => 'ec_last_name' & 'ec_first_name',
        account_number    => 'ec_account',
        #account_type      =>
        bank_name         => 'ec_bank_name',
        routing_code      => 'ec_rt',
        #customer_org      =>
        #customer_ssn      =>
        license_num       => 'ec_id_number',
        license_state     => 'ec_id_state',
        #license_dob       =>
        #get from new() args instead# payee             => 'ec_payee',
        check_number      => 'ec_serial_number',

        #recurring_billing => 'cnp_recurring',
    );

    #XXX hosted order_type?
    $self->{_content}{order_type} = 'S';

    #XXX counter field shouldn't be just a random integer (but it does need a
    #default this way i guess...
    $self->{_content}{counter} = int(rand(2**31));

    if ( $self->transaction_type =~ /^[EA][VS]$/ ) {
      #ccexp_month & ccexp_year
      $self->{_content}{'expiration'} =~ /^(\d+)\D+\d*(\d{2})$/
        or croak "unparsable expiration ". $self->{_content}{expiration};
      my( $month, $year ) = ( $1, $2 );
      $month = '0'. $month if $month =~ /^\d$/;
      $self->{_content}{ccexp_month} = $month;
      $self->{_content}{ccexp_year} = $year;
    }

    if ( $self->transaction_type =~ /^D[DVCH]$/ ) { #echeck

      #check number kludge... "periodic bill payments" don't have check #s!
      #$self->{_content}{ec_serial_number} = 'RECURRIN'
      $self->{_content}{ec_serial_number} = '00000000'
        if ! length($self->{_content}{ec_serial_number})
        && $self->{_content}{ec_payment_type} =~ /^(PPD)?$/i;

      ( $self->{_content}{ec_payee} = $self->payee )
        or croak "'payee' option required when instantiating new ".
                 "Business::OnlinePayment::OpenECHO object\n";
    }

    $self->{_content}{cnp_recurring} = 'Y'
      if exists($self->{_content}{recurring_billing})
      && $self->{_content}{recurring_billing} =~ /^y/i;

    #XXX echeck use customer_org and account_type to generate ec_account_type

    #XXX set required fields
    # https://wwws.echo-inc.com/ISPGuide-Fields2.asp
    $self->required_fields();

    my( $page, $response, %reply_headers) =
      $self->https_post( $self->get_fields( $self->fields ) );

    warn "raw echo response: $page" if $DEBUG;

    #XXX check $response and die if not 200?

    my $echotype1 = $self->GetEchoReturn($page, 1);
    my $echotype2 = $self->GetEchoReturn($page, 2);
    my $echotype3 = $self->GetEchoReturn($page, 3);
    my $openecho  = $self->GetEchoReturn($page, 'OPEN');

    #	server_response
    #	avs_code
    #	order_number
    #	is_success
    #	result_code
    #	authorization
    #md5 cvv2_response cavv_response ...?

    # Get all the metadata.
    $self->server_response($page);
    $self->authorization( $self->GetEchoProp($echotype3, 'auth_code') );
    $self->order_number(  $self->GetEchoProp($echotype3, 'order_number') );

    #XXX ???
    #$self->reference(     $this->GetEchoProp($echotype3, "echo_reference");

    $self->result_code(   $self->GetEchoProp($echotype3, 'status') );
    $self->avs_code(      $self->GetEchoProp($echotype3, 'avs_result') );

    #XXX ???
    #$self->security_result( $self->GetEchoProp($echotype3, 'security_result');
    #$self->mac( $self->GetEchoProp($echotype3, 'mac') );
    #$self->decline_code( $self->GetEchoProp($echotype3, 'decline_code') );

    if ($self->result_code =~ /^[GR]$/ ) { #success

      #XXX special case for AVS-only transactions we don't handle yet
      #if ($self->transaction_type eq "AD") {
      #  if ($self->avs_code =~ /^[XYDM]$/ ) {
      #    $self->is_success(1);
      #  } else {
      #    $self->is_success(0);
      #  }
      #} else {	
        $self->is_success(1);
      #}

    } else {
      $self->is_success(0);

      my $decline_code = $self->GetEchoProp($echotype3, 'decline_code');
      my $error_message = $self->error($decline_code);
      if ( $decline_code =~ /^(00)?30$/ ) {
        $echotype2 =~ s/<br>/\n/ig;
        $echotype2 =~ s'</?(b|pre)>''ig;
        $error_message .= ": $echotype2";
      }
      $self->error_message( $error_message );

    }

    $self->is_success(0) if $page eq '';

}


sub fields {
	my $self = shift;

	my @fields = qw(
	  order_type
	  transaction_type
	  merchant_echo_id
	  merchant_pin
	  isp_echo_id
	  isp_pin
	  authorization
	  billing_ip_address
	  billing_prefix
	  billing_name
	  billing_first_name
	  billing_last_name
	  billing_company_name
	  billing_address1
	  billing_address2
	  billing_city
	  billing_state
	  billing_zip
	  billing_country
	  billing_phone
	  billing_fax
	  billing_email
	  cc_number
	  ccexp_month
	  ccexp_year
	  counter
	  debug
	);

	if ($self->transaction_type =~ /^D[DCVH]$/) {
	  push @fields, qw(
	    ec_account
	    ec_account_type
	    ec_payment_type
	    ec_address1
	    ec_address2
	    ec_bank_name
	    ec_business_acct
	    ec_city
	    ec_email
	    ec_first_name
	    ec_id_country
	    ec_id_exp_mm
	    ec_id_exp_dd
	    ec_id_exp_yy
	    ec_id_number
	    ec_id_state
	    ec_id_type
	    ec_last_name
	    ec_merchant_ref
	    ec_nbds_code
	    ec_other_name
	    ec_payee
	    ec_rt
	    ec_serial_number
	    ec_state
	    ec_transaction_dt
	    ec_zip
	  );
	}

	push @fields, qw(
	  grand_total
	  merchant_email
	  merchant_trace_nbr
	  original_amount
	  original_trandate_mm
	  original_trandate_dd
	  original_trandate_yyyy
	  original_reference
	  order_number
	  shipping_flag
	  shipping_prefix
	  shipping_name
	  shipping_address1
	  shipping_address2
	  shipping_city
	  shipping_state
	  shipping_zip
	  shipping_comments
	  shipping_country
	  shipping_phone
	  shipping_fax
	  shipper
	  shipper_tracking_nbr
	  track1
	  track2
	  cnp_security
	  cnp_recurring
	);

	return @fields;
}

sub GetEchoProp {
	my( $self, $raw, $prop ) = @_;
	local $^W=0;

	my $data;
	($data) = $raw =~ m"<$prop>(.*?)</$prop>"gsi;
	$data =~ s/<.*?>/ /gs;
	chomp $data;
	return $data;
}

# Get's a given Echo return type and strips all HTML style tags from it.
# It also strips any new line characters from the returned string.
#
# This function based on Ben Reser's <breser@vecdev.com> Echo::Process
# module.
sub GetEchoReturn {
	my( $self, $page, $type ) = @_;
	local $^W=0;

	my $data;
	if ($type eq 'OPEN') {
		($data) = $page =~ m"<OPENECHO>(.*?)</OPENECHO>"gsi;
	}
	else {
		($data) = $page =~ m"<ECHOTYPE$type>(.*?)</ECHOTYPE$type>"gsi;
	}
#	$data =~ s"<.*?>" "g;

        #unless (length($data)) {
        #  warn "$self $page $type";
        #}

	chomp $data;
	return $data;
}

use vars qw(%error);
%error = (
  "01" => [ "Refer to card issuer", "The merchant must call the issuer before the transaction can be approved." ],
  "02" => [ "Refer to card issuer, special condition", "The merchant must call the issuer before the transaction can be approved." ],
  "03" => [ "Invalid merchant number", "The merchant ID is not valid." ],
  "04" => [ "Pick-up card. Capture for reward", "The card is listed on the Warning Bulletin.  Merchant may receive reward money by capturing the card." ],
  "05" => [ "Do not honor. The transaction was declined by the issuer without definition or reason", "The transaction was declined without explanation by the card issuer." ],
  "06" => [ "Error", "The card issuer returned an error without further explanation." ],
  "07" => [ "Pick-up card, special condition", "The card is listed on the Warning Bulletin.  Merchant may receive reward money by capturing the card." ],
  "08" => [ "Honor with identification", "Honor with identification." ],
  "09" => [ "Request in progress", "Request in progress." ],
  "10" => [ "Approved for partial amount", "Approved for partial amount." ],
  "11" => [ "Approved, VIP", "Approved, VIP program." ],
  "12" => [ "Invalid transaction", "The requested transaction is not supported or is not valid for the card number presented." ],
  "13" => [ "Invalid amount", "The amount exceeds the limits established by the issuer for this type of transaction." ],
  "14" => [ "Invalid card #", "The issuer indicates that this card is not valid." ],
  "15" => [ "No such issuer", "The card issuer number is not valid." ],
  "16" => [ "Approved, update track 3", "Approved, update track 3." ],
  "17" => [ "Customer cancellation", "Customer cancellation." ],
  "18" => [ "Customer dispute", "Customer dispute." ],
  "19" => [ "Re enter transaction", "Customer should resubmit transaction." ],
  "20" => [ "Invalid response", "Invalid response." ],
  "21" => [ "No action taken", "No action taken. The issuer declined with no other explanation." ],
  "22" => [ "Suspected malfunction", "Suspected malfunction." ],
  "23" => [ "Unacceptable transaction fee", "Unacceptable transaction fee." ],
  "24" => [ "File update not supported", "File update not supported." ],
  "25" => [ "Unable to locate record", "Unable to locate record." ],
  "26" => [ "Duplicate record", "Duplicate record." ],
  "27" => [ "File update edit error", "File update edit error." ],
  "28" => [ "File update file locked", "File update file locked." ],
  "30" => [ "Format error, call ECHO", "The host reported that the transaction was not formatted properly." ],
  "31" => [ "Bank not supported", "Bank not supported by switch." ],
  "32" => [ "Completed partially", "Completed partially." ],
  "33" => [ "Expired card, pick-up", "The card is expired.  Merchant may receive reward money by capturing the card." ],
  "34" => [ "Issuer suspects fraud, pick-up card", "The card issuer suspects fraud.  Merchant may receive reward money by capturing the card." ],
  "35" => [ "Contact acquirer, pick-up", "Contact card issuer.  Merchant may receive reward money by capturing the card." ],
  "36" => [ "Restricted card, pick-up", "The card is restricted by the issuer.  Merchant may receive reward money by capturing the card." ],
  "37" => [ "Call ECHO security, pick-up", "Contact ECHO security.  Merchant may receive reward money by capturing the card." ],
  "38" => [ "PIN tries exceeded, pick-up", "PIN attempts exceed issuer limits.  Merchant may receive reward money by capturing the card." ],
  "39" => [ "No credit account", "No credit account." ],
  "40" => [ "Function not supported", "Requested function not supported." ],
  "41" => [ "Lost Card, capture for reward", "The card has been reported lost." ],
  "42" => [ "No universal account", "No universal account." ],
  "43" => [ "Stolen Card, capture for reward", "The card has been reported stolen." ],
  "44" => [ "No investment account", "No investment account." ],
  "51" => [ "Not sufficient funds", "The credit limit for this account has been exceeded." ],
  "54" => [ "Expired card", "The card is expired." ],
  "55" => [ "Incorrect PIN", "The cardholder PIN is incorrect." ],
  "56" => [ "No card record", "No card record." ],
  "57" => [ "Transaction not permitted to cardholder", "The card is not allowed the type of transaction requested." ],
  "58" => [ "Transaction not permitted on terminal", "The Merchant is not allowed this type of transaction." ],
  "59" => [ "Suspected fraud", "Suspected fraud." ],
  "60" => [ "Contact ECHO", "Contact ECHO." ],
  "61" => [ "Exceeds withdrawal limit", "The amount exceeds the allowed daily maximum." ],
  "62" => [ "Restricted card", "The card has been restricted." ],
  "63" => [ "Security violation.", "The card has been restricted." ],
  "64" => [ "Original amount incorrect", "Original amount incorrect." ],
  "65" => [ "Exceeds withdrawal frequency", "The allowable number of daily transactions has been exceeded." ],
  "66" => [ "Call acquirer security, call ECHO", "Call acquirer security, call ECHO." ],
  "68" => [ "Response received too late", "Response received too late." ],
  "75" => [ "PIN tries exceeded", "The allowed number of PIN retries has been exceeded." ],
  "76" => [ "Invalid \"to\" account", "The debit account does not exist." ],
  "77" => [ "Invalid \"from\" account", "The credit account does not exist." ],
  "78" => [ "Invalid account specified (general)", "The associated card number account is invalid or does not exist." ],
  "79" => [ "Already reversed", "Already reversed." ],
  "84" => [ "Invalid authorization life cycle", "The authorization life cycle is invalid." ],
  "86" => [ "Cannot verify PIN", "Cannot verify PIN." ],
  "87" => [ "Network Unavailable", "Network Unavailable." ],
  "89" => [ "Ineligible to receive financial position information", "Ineligible to receive financial position information." ],
  "90" => [ "Cut-off in progress", "Cut-off in progress." ],
  "91" => [ "Issuer or switch inoperative", "The bank is not available to authorize this transaction." ],
  "92" => [ "Routing error", "The transaction cannot be routed to the authorizing agency." ],
  "93" => [ "Violation of law", "Violation of law." ],
  "94" => [ "Duplicate transaction", "Duplicate transaction." ],
  "95" => [ "Reconcile error", "Reconcile error." ],
  "96" => [ "System malfunction", "A system error has occurred." ],
  "98" => [ "Exceeds cash limit", "Exceeds cash limit." ],
  "1000" => [ "Unrecoverable error.", "An unrecoverable error has occurred in the ECHONLINE processing." ],
  "1001" => [ "Account closed", "The merchant account has been closed." ],
  "1002" => [ "System closed", "Services for this system are not available. (Not used by ECHONLINE)" ],
  "1003" => [ "E-Mail Down", "The e-mail function is not available. (Not used by ECHONLINE)" ],
  "1012" => [ "Invalid trans code", "The host computer received an invalid transaction code." ],
  "1013" => [ "Invalid term id", "The ECHO-ID is invalid." ],
  "1015" => [ "Invalid card number", "The credit card number that was sent to the host computer was invalid" ],
  "1016" => [ "Invalid expiry date", "The card has expired or the expiration date was invalid." ],
  "1017" => [ "Invalid amount", "The dollar amount was less than 1.00 or greater than the maximum allowed for this card." ],
  "1019" => [ "Invalid state", "The state code was invalid. (Not used by ECHONLINE)" ],
  "1021" => [ "Invalid service", "The merchant or card holder is not allowed to perform that kind of transaction" ],
  "1024" => [ "Invalid auth code", "The authorization number presented with this transaction is incorrect. (deposit transactions only)" ],
  "1025" => [ "Invalid reference number", "The reference number presented with this transaction is incorrect or is not numeric." ],
  "1029" => [ "Invalid contract number", "The contract number presented with this transaction is incorrect or is not numeric. (Not used by ECHONLINE)" ],
  "1030" => [ "Invalid inventory data", "The inventory data presented with this transaction is not ASCII \"printable\". (Not used by ECHONLINE)" ],
  "1508" => [ " ", "Invalid or missing order_type." ],
  "1509" => [ " ", "The merchant is not approved to submit this order_type." ],
  "1510" => [ " ", "The merchant is not approved to submit this transaction_type." ],
  #"1511" => [ " ", "Duplicate transaction attempt (see counterin Part I of this Specification</EM>)." ],
  "1511" => [ " ", "Duplicate transaction attempt (set counter field?)." ],
  "1599" => [ " ", "An system error occurred while validating the transaction input." ],
  "1801" => [ "Return Code \"A\"", "Address matches; ZIP does not match." ],
  "1802" => [ "Return Code \"W\"", "9-digit ZIP matches; Address does not match." ],
  "1803" => [ "Return Code \"Z\"", "5-digit ZIP matches; Address does not match." ],
  "1804" => [ "Return Codes \"U\"", "Issuer unavailable; cannot verify." ],
  "1805" => [ "Return Code \"R\"", "Retry; system is currently unable to process." ],
  "1806" => [ "Return Code \"S\" or \"G\"", "Issuer does not support AVS." ],
  "1807" => [ "Return Code \"N\"", "Nothing matches." ],
  "1808" => [ "Return Code \"E\"", "Invalid AVS only response." ],
  "1809" => [ "Return Code \"B\"", "Street address match. Postal code not verified because of incompatible formats." ],
  "1810" => [ "Return Code \"C\"", "Street address and Postal code not verified because of incompatible formats." ],
  "1811" => [ "Return Code \"D\"", "Street address match and Postal code match." ],
  "1812" => [ "Return Code \"I\"", "Address information not verified for international transaction." ],
  "1813" => [ "Return Code \"M\"", "Street address match and Postal code match." ],
  "1814" => [ "Return Code \"P\"", "Postal code match. Street address not verified because of incompatible formats." ],
  "1897" => [ "invalid response", "The host returned an invalid response." ],
  "1898" => [ "disconnect", "The host unexpectedly disconnected." ],
  "1899" => [ "timeout", "Timeout waiting for host response." ],
  "2071" => [ "Call VISA", "An authorization number from the VISA Voice Center is required to approve this transaction." ],
  "2072" => [ "Call Master Card", "An authorization number from the Master Card Voice Center is required to approve this transaction." ],
  "2073" => [ "Call Carte Blanche", "An authorization number from the Carte Blanche Voice Center is required to approve this transaction." ],
  "2074" => [ "Call Diners Club", "An authorization number from the Diners' Club Voice Center is required to approve this transaction." ],
  "2075" => [ "Call AMEX", "An authorization number from the American Express Voice Center is required to approve this transaction." ],
  "2076" => [ "Call Discover", "An authorization number from the Discover Voice Center is required to approve this transaction." ],
  "2078" => [ "Call ECHO", "The merchant must call ECHOCustomer Support for approval.or because there is a problem with the merchant's account." ],
  "2079" => [ "Call XpresscheX", "The merchant must call ECHOCustomer Support for approval.or because there is a problem with the merchant's account." ],
  "3001" => [ "No ACK on Resp", "The host did not receive an ACK from the terminal after sending the transaction response." ],
  "3002" => [ "POS NAK'd 3 Times", "The host disconnected after the terminal replied 3 times to the host response with a NAK." ],
  "3003" => [ "Drop on Wait", "The line dropped before the host could send a response to the terminal." ],
  "3005" => [ "Drop on Resp", "The line dropped while the host was sending the response to the terminal." ],
  "3007" => [ "Drop Before EOT", "The host received an ACK from the terminal but the line dropped before the host could send the EOT." ],
  "3011" => [ "No Resp to ENQ", "The line was up and carrier detected, but the terminal did not respond to the ENQ." ],
  "3012" => [ "Drop on Input", "The line disconnected while the host was receiving data from the terminal." ],
  "3013" => [ "FEP NAK'd 3 Times", "The host disconnected after receiving 3 transmissions with incorrect LRC from the terminal." ],
  "3014" => [ "No Resp to ENQ", "The line disconnected during input data wait in Multi-Trans Mode." ],
  "3015" => [ "Drop on Input", "The host encountered a full queue and discarded the input data." ],
);
for ( 9000..9999 ) {
  $error{$_} = [ "Host Error", "The host encountered an internal error and was not able to process the transaction." ]; 
}
sub error {
  my( $self, $num ) = @_;
  $num =~ s/^00(\d\d)$/$1/;
  return $num. ': '. $error{$num}[0]. ': '. $error{$num}[1];
}

1;

__END__

=head1 NAME

Business::OnlinePayment::OpenECHO - ECHO backend module for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  ####
  # One step transaction, the simple case.
  ####

  my $tx = new Business::OnlinePayment("OpenECHO");
  $tx->content(
      type           => 'VISA',
      login          => '1234684752',
      password       => '43400210',
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      invoice_number => '100100',
      customer_id    => 'jsk',
      first_name     => 'Tofu',
      last_name      => 'Beast',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'UT',
      zip            => '84058',
      card_number    => '4005550000000019',
      expiration     => '08/06',
      cvv2           => '1234', #optional
      referer        => 'http://valid.referer.url/',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

=head1 SUPPORTED TRANSACTION TYPES

=head2 CC, Visa, MasterCard, American Express, Discover

Content required: type, login, password, action, amount, first_name, last_name, card_number, expiration.

=head2 Check

Content required: type, login, password, action, amount, first_name, last_name, account_number, routing_code, bank_name. (...more)

=head1 PREREQUISITES

  URI::Escape
  Tie::IxHash

  Net::SSLeay _or_ ( Crypt::SSLeay and LWP )

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 AUTHOR

Original Author
Michael Lehmkuhl <michael@electricpulp.com>

Special Thanks
Jim Darden <jdarden@echo-inc.com>
Dan Browning <db@kavod.com>

Business::OnlinePayment Implementation
Ivan Kohler <ivan-openecho@420.am>

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=cut

