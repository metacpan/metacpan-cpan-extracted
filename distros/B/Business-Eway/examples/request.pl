#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib';
use Business::Eway;
use CGI;

my $q = CGI->new;
my $params = $q->Vars;

# init eway
my $CustomerID = $params->{'lblMerchID'} || 87654321;
my $UserName = $params->{'lblUserName'} || 'TestAccount';
my $eway = Business::Eway->new(
    CustomerID => $CustomerID,
    UserName => $UserName,
);

my $print_form = 1;
my $error;
if ( $params->{txtAmount} ) {
    my $args = {
          Amount => $params->{txtAmount},
          Currency => $params->{txtCurrency},
          PageTitle => $params->{txtPageTitle},
          PageDescription => $params->{txtPageDescription},
          PageFooter => $params->{txtPageFooter},
          Language => $params->{ddlLanguage},
          CompanyName => $params->{txtCompanyName},
          CustomerFirstName => $params->{txtFirstName},
          CustomerLastName => $params->{txtLastName},
          CustomerAddress => $params->{txtAddress},
          CustomerCity => $params->{txtCity},
          CustomerState => $params->{txtState},
          CustomerPostCode => $params->{txtPostcode},
          CustomerCountry => $params->{txtCountry},
          CustomerEmail => $params->{txtEmail},
          CustomerPhone => $params->{txtCustomerPhone},
          InvoiceDescription => $params->{txtInvoiceDescription},
          CancelURL => $params->{txtCancelUrl},
          ReturnUrl => $params->{txtReturnUrl},
          MerchantReference => $params->{txtRefNum},
          MerchantInvoice => $params->{txtInvoice},
          MerchantOption1 => $params->{txtOption1},
          MerchantOption2 => $params->{txtOption2},
          MerchantOption3 => $params->{txtOption3},
          PageBanner => $params->{txtPageBanner},
          CompanyLogo => $params->{txtCompanyLogo},
          ModifiableCustomerDetails => $params->{ddlModDetails},
    };
    my $rtn = $eway->request($args);
    if ( $rtn->{Result} eq 'True' ) {
        print $q->redirect( $rtn->{URI} );
        $print_form = 0;
    } else {
        $error = $rtn->{Error};
    }

}

if ( $print_form ) {
    print $q->header; # print header
    open(my $fh, '<', 'PaymentForm.html');
    local $/;
    my $content = <$fh>;
    close($fh);
    my $script = $ENV{SCRIPT_URI}; # return to request.pl
    my $return_url = $script;
    $return_url =~ s/request\.pl$/result\.pl/; # use result.pl at the same dir
    $content =~ s/\$ERROR/$error/s;
    $content =~ s/\$CancelUrl/$script/s;
    $content =~ s/\$ReturnUrl/$return_url/s;
    print $content;
}

1;