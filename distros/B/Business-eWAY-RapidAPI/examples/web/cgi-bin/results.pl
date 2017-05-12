#!/usr/bin/perl -W

use strict;
use warnings;
use Data::Dumper;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use CGI::Session;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";       # for plackup
use lib "$Bin/../../../lib";    # the path to lib/Business/eWAY/RapidAPI.pm
use Business::eWAY::RapidAPI;

$| = 1;

my $q       = new CGI();
my $session = new CGI::Session();

my $Response = $session->param('Response');
if ( !defined($Response) ) {
    print $q->header("Location: default.pl");
    exit();
}

print $session->header();
$session->flush();

## Build request for getting the result with the access code.
my $request = Business::eWAY::RapidAPI::GetAccessCodeResultRequest->new();
$request->AccessCode( $q->param('AccessCode') );

my $rapidapi = Business::eWAY::RapidAPI->new(
    mode => 'test',
    username =>
      "44DD7C70Jre1dVgIsULcEyi+A+/cX9V5SAHkIiyVdWrHRG2tZm0rdintfZz85Pa/kGwq/1",
    password => "Abcd1234",
);

## Call RapidAPI to get the result
my $result = $rapidapi->GetAccessCodeResult($request);

## Check if any error returns
my $lblError;
if ( defined( $result->{'Errors'} ) ) {
    $lblError = $rapidapi->ErrorsToString( $result->{'Errors'} );
}

## Content
print
qq|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">|
  . qq|<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">|
  . qq|<head>|
  . qq|    <title></title>|
  . qq|    <link href="../Styles/Site.css" rel="stylesheet" type="text/css" />|
  . qq|    <link href="../Styles/jquery-ui-1.8.11.custom.css" rel="stylesheet" type="text/css" />|
  . qq|    <script src="../Scripts/jquery-1.4.4.min.js" type="text/javascript"></script>|
  . qq|    <script src="../Scripts/jquery-ui-1.8.11.custom.min.js" type="text/javascript"></script>|
  . qq|    <script src="../Scripts/jquery.ui.datepicker-en-GB.js" type="text/javascript"></script>|
  . qq|</head>|
  . qq|<body>|
  . qq|        <center>|
  . qq|        <div id="outer">|
  . qq|            <div id="toplinks">|
  . qq|                <img alt="eWAY Logo" class="logo" src="../Images/companylogo.gif" width="960px" height="65px" />|
  . qq|            </div>|
  . qq|            <div id="main">|
  . qq|<div id="titlearea">|
  . qq|    <h2>|
  . qq|        Sample Response|
  . qq|    </h2>|
  . qq|</div>|;

if ( defined($lblError) ) {
    print qq|    <div id="error">|
      . qq|        <label style="color:red"> $lblError </label>|
      . qq|    </div>|;
}
else {
    print qq|    <div id="maincontent">|
      . qq|        <div class="response">|
      . qq|            <div class="fields">|
      . qq|                <label for="lblAccessCode">|
      . qq|                    Access Code</label>|
      . qq|                <label id="lblAccessCode"> $result->{'AccessCode'} </label>|
      . qq|            </div>|
      . qq|            <div class="fields">|
      . qq|                <label for="lblAuthorisationCode">|
      . qq|                    Authorisation Code</label>|
      . qq|                <label id="lblAuthorisationCode"> $result->{'AuthorisationCode'} </label>|
      . qq|            </div>|
      . qq|            <div class="fields">|
      . qq|                <label for="lblInvoiceNumber">|
      . qq|                    Invoice Number</label>|
      . qq|                <label id="lblInvoiceNumber"> $result->{'InvoiceNumber'} </label>|
      . qq|            </div>|
      . qq|            <div class="fields">|
      . qq|                <label for="lblInvoiceReference">|
      . qq|                    Invoice Reference</label>|
      . qq|                <label id="lblInvoiceReference"> $result->{'InvoiceReference'} </label>|
      . qq|            </div>|;

    my $valOpt1 = (
        defined( $result->{'Options'}[0]{'Value'} )
        ? $result->{'Options'}[0]{'Value'}
        : "" );
    my $valOpt2 = (
        defined( $result->{'Options'}[1]{'Value'} )
        ? $result->{'Options'}[1]{'Value'}
        : "" );
    my $valOpt3 = (
        defined( $result->{'Options'}[2]{'Value'} )
        ? $result->{'Options'}[2]{'Value'}
        : "" );

    print qq|            <div class="fields">|
      . qq|                <label for="lblOption1">|
      . qq|                    Option1</label>|
      . qq|                <label id="lblOption1">$valOpt1</label>|
      . qq|            </div>|
      . qq|            <div class="fields">|
      . qq|                <label for="lblOption2">|
      . qq|                    Option2</label>|
      . qq|                <label id="lblOption2">$valOpt2</label>|
      . qq|            </div>|
      . qq|            <div class="fields">|
      . qq|                <label for="lblOption3">|
      . qq|                    Option3</label>|
      . qq|                <label id="lblOption3">$valOpt3</label>|
      . qq|            </div>|;

    print qq|            <div class="fields">|
      . qq|                <label for="lblResponseCode">|
      . qq|                    Response Code</label>|
      . qq|                <label id="lblResponseCode"> $result->{'ResponseCode'} </label>|
      . qq|            </div>|
      . qq|            <div class="fields">|
      . qq|                <label for="lblResponseMessage">|
      . qq|                    Response Message</label>|
      . qq|                <label id="lblResponseMessage">|;
    if ( defined( $result->{'ResponseMessage'} ) ) {
        print $rapidapi->ErrorsToString( $result->{'ResponseMessage'} );
    }
    print qq|                </label>|
      . qq|            </div>|
      . qq|            <div class="fields">|
      . qq|                <label for="lblTokenCustomerID">|
      . qq|                    TokenCustomerID|
      . qq|                </label>|
      . qq|                <label id="lblTokenCustomerID">|;
    if ( defined( $result->{'TokenCustomerID'} ) ) {
        print $result->{'TokenCustomerID'};
    }
    print qq|                </label>|
      . qq|            </div>|
      . qq|            <div class="fields">|
      . qq|                <label for="lblTotalAmount">|
      . qq|                    Total Amount</label>|
      . qq|                <label id="lblTotalAmount">|;
    if ( defined( $result->{'TotalAmount'} ) ) {
        print $result->{'TotalAmount'};
    }
    print qq|                </label>|
      . qq|            </div>|
      . qq|            <div class="fields">|
      . qq|                <label for="lblTransactionID">|
      . qq|                    TransactionID</label>|
      . qq|                <label id="lblTransactionID">|;
    if ( defined( $result->{'TransactionID'} ) ) {
        print $result->{'TransactionID'};
    }
    print qq|                </label>|
      . qq|            </div>|
      . qq|            <div class="fields">|
      . qq|                <label for="lblTransactionStatus">|
      . qq|                    Transaction Status</label>|
      . qq|                <label id="lblTransactionStatus">|;
    if ( defined( $result->{'TransactionStatus'} ) ) {
        print ucfirst( $result->{'TransactionStatus'} );
    }
    print qq|                </label>|
      . qq|            </div>|
      . qq|            <div class="fields">|
      . qq|                <label for="lblBeagleScore">|
      . qq|                    Beagle Score</label>|
      . qq|                <label id="lblBeagleScore">|;
    if ( defined( $result->{'BeagleScore'} ) ) {
        print $result->{'BeagleScore'};
    }
    print qq|                </label>|
      . qq|            </div>|
      . qq|        </div>|
      . qq|    </div>| . qq||
      . qq|        <br />|
      . qq|        <br />|
      . qq|        <a href="default.pl">[Start Over]</a>| . qq||
      . qq|    <div id="maincontentbottom">|
      . qq|    </div>|;
}

print qq|            </div>|
  . qq|            <div id="footer"></div>|
  . qq|        </div>|
  . qq|    </center>|
  . qq|</body>|
  . qq|</html>|;

1;
