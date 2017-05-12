#! /usr/bin/perl

#
# REPLACE THE FIRST LINE OF THIS SCRIPT WITH THE PATH OF PERL ON YOUR SERVER
#

#
# Esempio di implemetazione della Transazione numero 1
# così come descritta nelle Specifiche Tecniche di GestPay
#
# Questo script è chiamato dal browser del cliente
# dopo che ha effettuato l'ordine
#

my %info = (
    ShopLogin        => '9000001',
    Currency         => '242',
    Amount           => '1828.45',
    ShopTransationID => '34az85ord19',
#    BuyerName        => 'My Name',
#    BuyerEmail       => 'myname@myhost.mydomain',
#    CustomInfo       => 'BV_CODCLIENTE=12*P1*BV_SESSIONID=398',
#    Language         => '2',
);

require Business::GestPayCrypt;
my $objCrypt = new Business::GestPayCrypt;

$objCrypt->SetShopLogin($info{'ShopLogin'});
$objCrypt->SetCurrency($info{'Currency'});
$objCrypt->SetAmount($info{'Amount'});
$objCrypt->SetShopTransactionID($info{'ShopTransationID'});
#$objCrypt->SetBuyerName($info{'BuyerName'});
#$objCrypt->SetBuyerEmail($info{'BuyerEmail'});
#$objCrypt->SetLanguage($info{'Language'});
#$objCrypt->SetCustomInfo($info{'CustomInfo'});

$objCrypt->Encrypt();

print "Content-Type: text/html\n\n";
print "
<html>
<body>";

if ( $objCrypt->GetErrorCode() ) {
    print '
    An error occurs:
    <br>Code : ', $objCrypt->GetErrorCode(), '
    <br>Description : ', $objCrypt->GetErrorDescription();
} else {
    my $a = $objCrypt->GetShopLogin();
    my $b = $objCrypt->GetEncryptedString();
    print qq~
    <form action="https://ecomm.sella.it/gestpay/pagam.asp">
      <input type="hidden" name="a" value="$a">
      <input type="hidden" name="b" value="$b">
      <input type="submit" value="Go to payment">
    </form>~;
}

print "
</body>
</html>";
