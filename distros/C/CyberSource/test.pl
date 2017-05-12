#!/usr/bin/perl

use ExtUtils::testlib;
use CyberSource;

%arg =  (
	"merchant_id"		=> "YourMerchanID",
	"ics_applications"	=> "ics_score,ics_auth,ics_bill",
	"customer_firstname"	=> "John",
	"customer_lastname"	=> "Doe",
	"customer_email"	=> "nobody\@cybersource.com",
	"customer_phone"	=> "408-556-9100",
	"bill_address1"		=> "1295 Charleston Rd.",
	"bill_city"		=> "Mountain View",
	"bill_state"		=> "CA",
	"bill_zip"		=> "94043-1307",
	"bill_country"		=> "US",
	"customer_cc_number"	=> "4111111111111111",
	"customer_cc_expmo"	=> "12",
	"customer_cc_expyr"	=> "2004",
	"merchant_ref_number"	=> "12",
	"currency"		=> "USD",
	"offer0"		=> "offerid:0^amount:4.59",
	);

%values = CyberSource::ics_send( \%arg );

