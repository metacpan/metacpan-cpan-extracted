#!/usr/bin/perl

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

my $self_url = $q->url( -absolute );
$self_url =~ s/default\.pl/results\.pl/;
my $redirect_url = $self_url;

my $lblError;

if ( defined( $q->param('btnSubmit') ) ) {
    my $rapidapi = Business::eWAY::RapidAPI->new(
        mode => 'test',
        username =>
"44DD7C70Jre1dVgIsULcEyi+A+/cX9V5SAHkIiyVdWrHRG2tZm0rdintfZz85Pa/kGwq/1",
        password => "Abcd1234",
    );

    ## Create AccessCode Request Object
    my $request = Business::eWAY::RapidAPI::CreateAccessCodeRequest->new();

    ## Populate values for Customer Object
    if ( defined $q->param('txtTokenCustomerID') ) {
        $request->Customer->TokenCustomerID( $q->param('txtTokenCustomerID') );
    }
    $request->Customer->Reference( $q->param('txtCustomerRef') );
    $request->Customer->Title( $q->param('ddlTitle') );

    # Note: FirstName is Required Field When Create/Update a TokenCustomer
    $request->Customer->FirstName( $q->param('txtFirstName') );

    # Note: LastName is Required Field When Create/Update a TokenCustomer
    $request->Customer->LastName( $q->param('txtLastName') );
    $request->Customer->CompanyName( $q->param('txtCompanyName') );
    $request->Customer->JobDescription( $q->param('txtJobDescription') );
    $request->Customer->Street1( $q->param('txtStreet1') );
    $request->Customer->Street2( $q->param('txtStreet2') );
    $request->Customer->City( $q->param('txtCity') );
    $request->Customer->State( $q->param('txtState') );
    $request->Customer->PostalCode( $q->param('txtPostalcode') );

    # Note: Country is Required Field When Create/Update a TokenCustomer
    $request->Customer->Country( $q->param('txtCountry') );
    $request->Customer->Email( $q->param('txtEmail') );
    $request->Customer->Phone( $q->param('txtPhone') );
    $request->Customer->Mobile( $q->param('txtMobile') );
    $request->Customer->Comments("Some Comments Here");
    $request->Customer->Fax("0131 208 0321");
    $request->Customer->Url("http://www.yoursite.com");

    ## Populate values for ShippingAddress Object.
    ## This values can be taken from a Form POST as well. Now is just some dummy data.
    $request->ShippingAddress->FirstName("John");
    $request->ShippingAddress->LastName("Doe");
    $request->ShippingAddress->Street1("9/10 St Andrew");
    $request->ShippingAddress->Street2(" Square");
    $request->ShippingAddress->City("Edinburgh");
    $request->ShippingAddress->State("");
    $request->ShippingAddress->Country("gb");
    $request->ShippingAddress->PostalCode("EH2 2AF");
    $request->ShippingAddress->Email('sales@eway.co.uk');
    $request->ShippingAddress->Phone("0131 208 0321");

# ShippingMethod, e.g. "LowCost", "International", "Military". Check the spec for available values.
    $request->ShippingAddress->ShippingMethod("LowCost");

    ## Populate values for LineItems
    my $item1 = Business::eWAY::RapidAPI::LineItem->new();
    $item1->SKU("SKU1");
    $item1->Description("Description1");
    my $item2 = Business::eWAY::RapidAPI::LineItem->new();
    $item2->SKU("SKU2");
    $item2->Description("Description2");
    $request->Items->LineItem( [ $item1, $item2 ] );

    ## Populate values for Options
    my $opt1 =
      Business::eWAY::RapidAPI::Option->new( Value => $q->param('txtOption1') );
    my $opt2 =
      Business::eWAY::RapidAPI::Option->new( Value => $q->param('txtOption2') );
    my $opt3 =
      Business::eWAY::RapidAPI::Option->new( Value => $q->param('txtOption3') );
    $request->Options->Option( [ $opt1, $opt2, $opt3 ] );

    $request->Payment->TotalAmount( $q->param('txtAmount') );
    $request->Payment->InvoiceNumber( $q->param('txtInvoiceNumber') );
    $request->Payment->InvoiceDescription( $q->param('txtInvoiceDescription') );
    $request->Payment->InvoiceReference( $q->param('txtInvoiceReference') );
    $request->Payment->CurrencyCode( $q->param('txtCurrencyCode') );

    ## Url to the page for getting the result with an AccessCode
    $request->RedirectUrl( $q->param('txtRedirectURL') );
    ## Method for this request. e.g. ProcessPayment, Create TokenCustomer, Update TokenCustomer & TokenPayment
    $request->Method( $q->param('ddlMethod') );

    my $result;
    eval { $result = $rapidapi->CreateAccessCode($request); };

    if ($@) {
        print $session->header();
        print $@;
        exit;
    }

    ## Save result into Session. payment.pl and results.pl will retrieve this result from Session
    $session->param( 'TotalAmount',      $q->param('txtAmount') );
    $session->param( 'InvoiceReference', $q->param('txtInvoiceReference') );
    $session->param( 'Response',         $result );
    $session->flush();

    ## Check if any error returns
    if ( defined( $result->{'Errors'} ) ) {
        $lblError = $rapidapi->ErrorsToString( $result->{'Errors'} );
    }
    else {
        ## All good then redirect to the payment page
        print $session->header( -location => 'payment.pl' );
        exit();
    }
}

print $session->header();
$session->flush();
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
  . qq|    <script type="text/javascript" src="../Scripts/tooltip.js"></script>|
  . qq|</head>|
  . qq|<body>|
  . qq|    <form method="POST">|
  . qq|    <center>|
  . qq|        <div id="outer">|
  . qq|            <div id="toplinks">|
  . qq|                <img alt="eWAY Logo" class="logo" src="../Images/companylogo.gif" width="960px" height="65px" />|
  . qq|            </div>|
  . qq|            <div id="main">| . qq||
  . qq|    <div id="titlearea">|
  . qq|        <h2>Sample Merchant Page</h2>|
  . qq|    </div>|;

if ( defined($lblError) ) {
    print qq|    <div id="error">|
      . qq|        <label style="color:red"> $lblError </label>|
      . qq|    </div>|;
}

print qq|    <div id="maincontent">|
  . qq|        <div class="transactioncustomer">|
  . qq|            <div class="header first">|
  . qq|                Request Options|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtRedirectURL">Redirect URL</label>|
  . qq|                <input id="txtRedirectURL" name="txtRedirectURL" type="text" value="$redirect_url" />|
  . qq|            </div>|
  . qq|            <div class="header">|
  . qq|                Payment Details|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtAmount">Amount &nbsp;<img src="../Images/question.gif" alt="Find out more" id="amountTipOpener" border="0" /></label>|
  . qq|                <input id="txtAmount" name="txtAmount" type="text" value="100" />|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtCurrencyCode">Currency Code </label>|
  . qq|                <input id="txtCurrencyCode" name="txtCurrencyCode" type="text" value="AUD" />|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtInvoiceNumber">Invoice Number</label>|
  . qq|                <input id="txtInvoiceNumber" name="txtInvoiceNumber" type="text" value="Inv 21540" />|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtInvoiceReference">Invoice Reference</label>|
  . qq|                <input id="txtInvoiceReference" name="txtInvoiceReference" type="text" value="513456" />|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtInvoiceDescription">Invoice Description</label>|
  . qq|                <input id="txtInvoiceDescription" name="txtInvoiceDescription" type="text" value="Individual Invoice Description" />|
  . qq|            </div>|
  . qq|            <div class="header">|
  . qq|                Custom Fields|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtOption1">Option 1</label>|
  . qq|                <input id="txtOption1" name="txtOption1" type="text" value="Option1" />|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtOption2">Option 2</label>|
  . qq|                <input id="txtOption2" name="txtOption2" type="text" value="Option2" />|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtOption3">Option 3</label>|
  . qq|                <input id="txtOption3" name="txtOption3" type="text" value="Option3" />|
  . qq|            </div>|
  . qq|        </div>|
  . qq|        <div class="transactioncard">|
  . qq|            <div class="header first">|
  . qq|                Customer Details|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtTokenCustomerID">Token Customer ID &nbsp;<img src="../Images/question.gif" alt="Find out more" id="tokenCustomerTipOpener" border="0" /></label>|
  . qq|                <input id="txtTokenCustomerID" name="txtTokenCustomerID" type="text" value="" />|
  . qq|            </div>| . qq||
  . qq|            <div class="fields">|
  . qq|                <label for="ddlTitle">Title</label>|
  . qq|                <select id="ddlTitle" name="ddlTitle">|
  . qq|                <option value="Mr." selected="selected">Mr.</option>|
  . qq|                <option value="Ms.">Ms.</option>|
  . qq|                <option value="Mrs.">Mrs.</option>|
  . qq|                <option value="Miss">Miss</option>|
  . qq|                <option value="Dr.">Dr.</option>|
  . qq|                <option value="Sir.">Sir.</option>|
  . qq|                <option value="Prof.">Prof.</option>|
  . qq|                </select>|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtCustomerRef">Customer Reference</label>|
  . qq|                <input id="txtCustomerRef" name="txtCustomerRef" type="text" value="A12345" />|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtFirstName">First Name</label>|
  . qq|                <input id="txtFirstName" name="txtFirstName" type="text" value="John" />|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtLastName">Last Name</label>|
  . qq|                <input id="txtLastName" name="txtLastName" type="text" value="Doe" />|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtCompanyName">Company Name</label>|
  . qq|                <input id="txtCompanyName" name="txtCompanyName" type="text" value="WEB ACTIVE" />|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtJobDescription">Job Description</label>|
  . qq|                <input id="txtJobDescription" name="txtJobDescription" type="text" value="Developer" />|
  . qq|            </div>|
  . qq|            <div class="header">|
  . qq|                Customer Address|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtStreet1">Street1</label>|
  . qq|                <input id="txtStreet1" name="txtStreet1" type="text" value="15 Smith St" />|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtStreet2">Street2</label>|
  . qq|                <input id="txtStreet2" name="txtStreet2" type="text" value="" />|
  . qq|            </div>| . qq||
  . qq|            <div class="fields">|
  . qq|                <label for="txtCity">City</label>|
  . qq|                <input id="txtCity" name="txtCity" type="text" value="Phillip" />|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtState">State</label>|
  . qq|                <input id="txtState" name="txtState" type="text" value="ACT" />|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtPostalcode">Post Code</label>|
  . qq|                <input id="txtPostalcode" name="txtPostalcode" type="text" value="2602" />|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtCountry">Country</label>|
  . qq|                <input id="txtCountry" name="txtCountry" type="text" value="au" maxlength="2" />|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtEmail">Email</label>|
  . qq|                <input id="txtEmail" name="txtEmail" type="text" value="" />|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtPhone">Phone</label>|
  . qq|                <input id="txtPhone" name="txtPhone" type="text" value="1800 10 10 65" />|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="txtMobile">Mobile</label>|
  . qq|                <input id="txtMobile" name="txtMobile" type="text" value="1800 10 10 65" />|
  . qq|            </div>|
  . qq|            <div class="header">|
  . qq|                Method|
  . qq|            </div>|
  . qq|            <div class="fields">|
  . qq|                <label for="ddlMethod">Method Type</label>|
  . qq|                <select id="ddlMethod" name="ddlMethod" style="width:140px;">|
  . qq|                <option value="ProcessPayment">ProcessPayment</option>|
  . qq|                <option value="CreateTokenCustomer">CreateTokenCustomer</option>|
  . qq|                <option value="UpdateTokenCustomer">UpdateTokenCustomer</option>|
  . qq|                <option value="TokenPayment">TokenPayment</option>|
  . qq|                </select>|
  . qq|            </div>|
  . qq|        </div>|
  . qq|        <div class="button">|
  . qq|            <br />|
  . qq|            <br />|
  . qq|            <input type="submit" id="btnSubmit" name="btnSubmit" value="Get Access Code" />|
  . qq|        </div>|
  . qq|    </div>| . qq||
  . qq|    <div id="maincontentbottom">|
  . qq|    </div>| . qq||
  . qq|    <div id="amountTip" style="font-size: 8pt !important">|
  . qq|        The amount in cents. For example for an amount of \$1.00, enter 100.|
  . qq|    </div>|
  . qq|    <div id="tokenCustomerTip" style="font-size: 8pt !important">|
  . qq|        If this field has a value, the details of an existing customer will be loaded when the request is sent.|
  . qq|    </div>| . qq||
  . qq|        </div>|
  . qq|            <div id="footer"></div>|
  . qq|        </div>|
  . qq|    </center>|
  . qq|    </form>|
  . qq|</body>|
  . qq|</html>|;

1;
