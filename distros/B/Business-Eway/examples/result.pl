#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib';
use Business::Eway;
use CGI;
use Data::Dumper;

my $q = CGI->new;
print $q->header; # print header

# init eway
my $CustomerID = 87654321;
my $UserName = 'TestAccount';
my $eway = Business::Eway->new(
    CustomerID => $CustomerID,
    UserName => $UserName,
);

my $AccessPaymentCode = $q->param('AccessPaymentCode');
my $rtn = $eway->result($AccessPaymentCode);

if ( $rtn->{TrxnStatus} eq 'true' ) {
    print "<p>Transaction Success!</p>\n";
} else {
    print "<p>Transaction Failed!</p>\n";
}

foreach my $k ('TrxnStatus', 'AuthCode', 'ResponseCode', 'ReturnAmount', 'TrxnNumber', 'TrxnResponseMessage', 'MerchantOption1', 'MerchantOption2', 'MerchantOption3', 'MerchantInvoice', 'MerchantReference') {
    print "$k: $rtn->{$k}<br />\n";
}

1;