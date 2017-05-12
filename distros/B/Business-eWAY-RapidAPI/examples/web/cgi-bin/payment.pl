#!/usr/bin/perl

use strict;
use warnings;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use CGI::Session;
use DateTime;

$| = 1;

my $q       = new CGI();
my $session = new CGI::Session();
print $session->header();
$session->flush();

my $Response         = $session->param('Response');
my $TotalAmount      = $session->param('TotalAmount');
my $InvoiceReference = $session->param('InvoiceReference');
if ( !defined($Response) ) {
    header("Location: default.pl");
    exit();
}

my $lblError;    ##nu
my $dt = DateTime->now();

my $JSONPScript = "";
## Content
print
qq|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">|
  . qq|<html xmlns="http://www.w3.org/1999/xhtml">|
  . qq|<head>|
  . qq|    <title></title>|
  . qq|    <link href="../Styles/Site.css" rel="stylesheet" type="text/css" />|
  . qq|    <!-- Include for Ajax Calls -->|
  . qq|    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js" type="text/javascript"></script>|
  . qq|    <!-- This is the JSONP script include on the eWAY Rapid API Server - this must be included to use the Rapid API via JSONP -->|
  . qq|    <script type="text/javascript" src="$JSONPScript"></script>|
  . qq|</head>|
  .

  qq|<body>|
  . qq|    <form id="form1" action="$Response->{'FormActionURL'}" method='post'>|
  . qq|    <center>|
  . qq|        <div id="outer">|
  . qq|            <div id="toplinks">|
  . qq|                <img alt="eWAY Logo" class="logo" src="../Images/merchantlogo.gif" width="926px" height="65px" />|
  . qq|            </div>|
  . qq|            <div id="main">|
  . qq|                <div id="titlearea">|
  . qq|                    <h2>Sample Merchant Checkout</h2>|
  . qq|                </div>|;

if ( defined($lblError) ) {
    print qq|    <div id="error">|
      . qq|        <label style="color:red"> $lblError </label>|
      . qq|    </div>|;
}

print qq|                <div id="maincontent">|
  . qq|                    <div class="transactioncustomer">|
  . qq|                        <div class="header first">|
  . qq|                            Customer Address|
  . qq|                        </div>|
  . qq|                        <div class="fields">|
  . qq|                            <label for="lblStreet1">Street1</label>|
  . qq|                            <label id="lblStreet1">$Response->{'Customer'}{'Street1'}</label>|
  . qq|                        </div>|
  . qq|                        <div class="fields">|
  . qq|                            <label for="lblStreet2">Street2</label>|
  . qq|                            <label id="lblStreet2">$Response->{'Customer'}{'Street2'}</label>|
  . qq|                        </div>|
  . qq|                        <div class="fields">|
  . qq|                            <label for="lblCity">|
  . qq|                                City</label>|
  . qq|                            <label id="lblStreet">$Response->{'Customer'}{'City'}</label>|
  . qq|                        </div>|
  . qq|                        <div class="fields">|
  . qq|                            <label for="lblState">|
  . qq|                                State</label>|
  . qq|                            <label id="lblState">$Response->{'Customer'}{'State'}</label>|
  . qq|                        </div>|
  . qq|                        <div class="fields">|
  . qq|                            <label for="lblPostcode">|
  . qq|                                Post Code</label>|
  . qq|                            <label id="lblPostcode">$Response->{'Customer'}{'PostalCode'}</label>|
  . qq|                        </div>|
  . qq|                        <div class="fields">|
  . qq|                            <label for="lblCountry">|
  . qq|                                Country</label>|
  . qq|                            <label id="lblCountry">$Response->{'Customer'}{'Country'}</label>|
  . qq|                        </div>|
  . qq|                        <div class="fields">|
  . qq|                            <label for="lblEmail">|
  . qq|                                Email</label>|
  . qq|                            <label id="lblEmail">$Response->{'Customer'}{'Email;'}</label>|
  . qq|                        </div>|
  . qq|                        <div class="fields">|
  . qq|                            <label for="lblPhone">|
  . qq|                                Phone</label>|
  . qq|                            <label id="lblPhone">$Response->{'Customer'}{'Phone'}</label>|
  . qq|                        </div>|
  . qq|                        <div class="fields">|
  . qq|                            <label for="lblMobile">|
  . qq|                                Mobile</label>|
  . qq|                            <label id="lblMobile">$Response->{'Customer'}{'Mobile'}</label>|
  . qq|                        </div>|
  . qq|                        <div class="header">|
  . qq|                            Payment Details|
  . qq|                        </div>|
  . qq|                        <div class="fields">|
  . qq|                            <label for="lblAmount">|
  . qq|                                Total Amount</label>|
  . qq|                            <label id="lblAmount"> $TotalAmount </label>|
  . qq|                        </div>|
  . qq|                        <div class="fields">|
  . qq|                            <label for="lblInvoiceReference">|
  . qq|                                Invoice Reference</label>|
  . qq|                            <label id="lblInvoiceReference"> $InvoiceReference </label>|
  . qq|                        </div>|
  . qq|                    </div>|
  . qq|                    <div class="transactioncard">|
  . qq|                        <div class="header first">|
  . qq|                            Customer Details</div>|
  . qq|                        <div class="fields">|
  . qq|                            <label for="lblTitle">|
  . qq|                                Title</label>|
  . qq|                            <label id="lblTitle">$Response->{'Customer'}{'Title'}</label>|
  . qq|                        </div>|
  . qq|                        <div class="fields">|
  . qq|                            <label for="lblFirstName">|
  . qq|                                First Name</label>|
  . qq|                            <label id="lblFirstName">$Response->{'Customer'}{'FirstName'}</label>|
  . qq|                        </div>|
  . qq|                        <div class="fields">|
  . qq|                            <label for="lblLastName">|
  . qq|                                Last Name</label>|
  . qq|                            <label id="lblLastName">$Response->{'Customer'}{'LastName'}</label>|
  . qq|                        </div>|
  . qq|                        <div class="fields">|
  . qq|                            <label for="lblCompanyName">|
  . qq|                                Company Name</label>|
  . qq|                            <label id="lblCompanyName">$Response->{'Customer'}{'CompanyName'}</label>|
  . qq|                        </div>|
  . qq|                        <div class="fields">|
  . qq|                            <label for="lblJobDescription">|
  . qq|                                Job Description</label>|
  . qq|                            <label id="lblJobDescription">$Response->{'Customer'}{'JobDescription'}</label>|
  . qq|                        </div>|;

my $valueCustomerCardName =
  ( defined( $Response->{'Customer'}{'CardName'} )
      && !( $Response->{'Customer'}{'CardName'} eq '' )
    ? $Response->{'Customer'}{'CardName'}
    : "TestUser" );
my $valueCustomerCardNumber =
  ( defined( $Response->{'Customer'}{'CardNumber'} )
      && !( $Response->{'Customer'}{'CardNumber'} eq '' )
    ? $Response->{'Customer'}{'CardNumber'}
    : "4444333322221111" );

my $expiry_month =
  ( defined( $Response->{'Customer'}{'CardExpiryMonth'} )
      && !( $Response->{'Customer'}{'CardExpiryMonth'} eq '' )
    ? $Response->{'Customer'}{'CardExpiryMonth'}
    : $dt->month );
my $selectoptions_expiry_month = "";
for ( my $i = 1 ; $i <= 12 ; $i++ ) {
    my $s = sprintf( '%02d', $i );
    $selectoptions_expiry_month .= "<option value='$s'";
    if ( $expiry_month == $i ) {
        $selectoptions_expiry_month .= " selected='selected'";
    }
    $selectoptions_expiry_month .= ">$s</option>\n";
}

my $selectoptions_CardExpiryYear = "";
for ( my $i = 12 ; $i <= 23 ; $i++ ) {
    $selectoptions_CardExpiryYear .= "<option value='$i'";
    if (    $Response->{'Customer'}{'CardExpiryYear'}
        and $Response->{'Customer'}{'CardExpiryYear'} == $i )
    {
        $selectoptions_CardExpiryYear .= " selected='selected'";
    }
    $selectoptions_CardExpiryYear .= ">$i</option>\n";
}

my $start_month =
  ( defined( $Response->{'Customer'}{'CardStartMonth'} )
      && !( $Response->{'Customer'}{'CardStartMonth'} eq '' )
    ? $Response->{'Customer'}{'CardStartMonth'}
    : $dt->month );
my $selectoptions_CardStartMonth = "";
for ( my $i = 1 ; $i <= 12 ; $i++ ) {
    my $s = sprintf( '%02d', $i );
    $selectoptions_CardStartMonth .= "<option value='$s'";
    if ( $start_month == $i ) {
        $selectoptions_CardStartMonth .= " selected='selected'";
    }
    $selectoptions_CardStartMonth .= ">$s</option>\n";
}

my $selectoptions_CardStartYear = "";
for ( my $i = 12 ; $i <= 23 ; $i++ ) {
    $selectoptions_CardStartYear .= "<option value='$i'";
    if ( defined( $Response->{'Customer'}{'CardStartMonth'} ) ) {
        if ( defined $Response->{'Customer'}{'CardStartYear'}
            and $Response->{'Customer'}{'CardStartYear'} == $i )
        {
            $selectoptions_CardStartYear .= " selected='selected'";
        }
    }
    $selectoptions_CardStartYear .= ">$i</option>\n";
}

my $valueCustomerCardIssueNumber =
  ( defined( $Response->{'Customer'}{'CardIssueNumber'} )
      && !( $Response->{'Customer'}{'CardIssueNumber'} eq '' )
    ? $Response->{'Customer'}{'CardIssueNumber'}
    : "22" );

print qq|                        <div class="header">|
  . qq|                            Card Details|
  . qq|                        </div>|
  . qq|                        <!-- The following fields are the ones that eWAY looks for in the POSTed data when the form is submitted. -->|
  .

qq|                        <!-- This field should contain the access code received from eWAY -->|
  . qq|                        <input type='hidden' name='EWAY_ACCESSCODE' value="$Response->{'AccessCode'}" />|
  .

  qq|                        <div class="fields">|
  . qq|                            <label for="EWAY_CARDNAME">|
  . qq|                                Card Holder</label>|
  . qq|                            <input type='text' name='EWAY_CARDNAME' id='EWAY_CARDNAME' value="$valueCustomerCardName" />|
  . qq|                        </div>|
  . qq|                        <div class="fields">|
  . qq|                            <label for="EWAY_CARDNUMBER">|
  . qq|                                Card Number</label>|
  . qq|                            <input type='text' name='EWAY_CARDNUMBER' id='EWAY_CARDNUMBER' value="$valueCustomerCardNumber" />|
  . qq|                        </div>|
  . qq|                        <div class="fields">|
  . qq|                            <label for="EWAY_CARDEXPIRYMONTH">|
  . qq|                                Expiry Date</label>|
  . qq|                            <select ID="EWAY_CARDEXPIRYMONTH" name="EWAY_CARDEXPIRYMONTH">|;
print $selectoptions_expiry_month;
print qq|                            </select>|
  . qq|                            /|
  . qq|                            <select ID="EWAY_CARDEXPIRYYEAR" name="EWAY_CARDEXPIRYYEAR">|;
print $selectoptions_CardExpiryYear;
print qq|                            </select>|
  . qq|                        </div>|
  . qq|                        <div class="fields">|
  . qq|                            <label for="EWAY_CARDSTARTMONTH">|
  . qq|                                Valid From Date</label>|
  . qq|                            <select ID="EWAY_CARDSTARTMONTH" name="EWAY_CARDSTARTMONTH">|;
print $selectoptions_CardStartMonth;
print qq|                            </select>|
  . qq|                            /|
  . qq|                            <select ID="EWAY_CARDSTARTYEAR" name="EWAY_CARDSTARTYEAR">|;
print $selectoptions_CardStartYear;
print qq|                            </select>|
  . qq|                        </div>|
  . qq|                        <div class="fields">|
  . qq|                            <label for="EWAY_CARDISSUENUMBER">|
  . qq|                                Issue Number</label>|
  . qq|                            <input type='text' name='EWAY_CARDISSUENUMBER' id='EWAY_CARDISSUENUMBER' |
  . qq|                        	value="$valueCustomerCardIssueNumber" maxlength="2" style="width:40px;"/> <!-- This field is optional but highly recommended -->|
  . qq|                        </div>|
  . qq|                        <div class="fields">|
  . qq|                            <label for="EWAY_CARDCVN">|
  . qq|                                CVN</label>|
  . qq|                            <input type='text' name='EWAY_CARDCVN' id='EWAY_CARDCVN' value="123" maxlength="4" style="width:40px;"/> <!-- This field is optional but highly recommended -->|
  . qq|                        </div>|
  . qq|                    </div>|
  . qq|                    <div class="paymentbutton">|
  . qq|                        <br />|
  . qq|                        <br />|
  . qq|                        <input type='submit' ID="btnSubmit" name='btnSubmit' value="Submit" />|
  . qq|                    </div>|
  . qq|                </div>|
  . qq|                <div id="maincontentbottom">|
  . qq|                </div>|
  . qq|            </div>|
  . qq|        </div>|
  . qq|    </center>|
  . qq|    </form>|
  . qq|</body>|
  . qq|</html>|;

1;
