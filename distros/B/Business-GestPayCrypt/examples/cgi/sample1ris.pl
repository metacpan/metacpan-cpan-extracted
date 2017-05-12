#! /usr/bin/perl

#
# REPLACE THE FIRST LINE OF THIS SCRIPT WITH THE PATH OF PERL ON YOUR SERVER
#

#
# Esempio di implemetazione della Transazione numero 1
# così come descritta nelle Specifiche Tecniche di GestPay
#

my %info = (
    ShopLogin => '9000001',
);

print "Content-Type: text/html\n\n";

use CGI;
my $query = new CGI;

require Business::GestPayCrypt;
my $objCrypt = new Business::GestPayCrypt;

$objCrypt->SetShopLogin($info{'ShopLogin'});
$objCrypt->SetEncryptedString($query->param('b'));

$objCrypt->Decrypt();

print "
<html>
<body>";

if ( $objCrypt->GetErrorCode() ) {
    print '
    An error occurs:
    <br>Code : ', $objCrypt->GetErrorCode(), '
    <br>Description : ', $objCrypt->GetErrorDescription();
} else {
    print '<br>ShopLogin : ', $objCrypt->GetShopLogin();
    print '<br>Currency :', $objCrypt->GetCurrency();
    print '<br>Amount : ', $objCrypt->GetAmount();
    print '<br>ShopTransactionID : ', $objCrypt->GetShopTransactionID();
    print '<br>BuyerName : ', $objCrypt->GetBuyerName();
    print '<br>BuyerEmail : ', $objCrypt->GetBuyerEmail();
    print '<br>TransactionResult : ', $objCrypt->GetTransactionResult();
    print '<br>AuthorizationCode : ', $objCrypt->GetAuthorizationCode();
    print '<br>BankTransactionID : ', $objCrypt->GetBankTransactionID();
    print '<br>AlertCode : ', $objCrypt->GetAlertCode();
    print '<br>AlertDescription : ', $objCrypt->GetAlertDescription();
    print '<br>CustomInfo : ', $objCrypt->GetCustomInfo();
}

print "
</body>
</html>";

