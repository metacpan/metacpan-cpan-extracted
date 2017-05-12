<%@ LANGUAGE="PerlScript" %>
<html>
<body>

<%

#
# Esempio di implemetazione della Transazione numero 1
# così come descritta nelle Specifiche Tecniche di GestPay
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

use Business::GestPayCrypt;
my $objCrypt = new Business::GestPayCrypt;

$objCrypt->SetShopLogin($info{'ShopLogin'});
$objCrypt->SetCurrency($info{'Currency'});
$objCrypt->SetAmount($info{'Amount'});
$objCrypt->SetShopTransactionID($info{'ShopTransationID'});
#$objCrypt->SetBuyerName($info{'BuyerName'});
#$objCrypt->SetBuyerEmail($info{'BuyerEmail'});
#$objCrypt->SetCustomInfo($info{'CustomInfo'});
#$objCrypt->SetLanguage($info{'Language'});

$objCrypt->Encrypt();

%>

<% if ( $objCrypt->GetErrorCode() ) { %>
    An error occurs:
    <br>Code : <%= $objCrypt->GetErrorCode() %>
    <br>Description : <%= $objCrypt->GetErrorDescription() %>
<% } else {
    my $a = $objCrypt->GetShopLogin();
    my $b = $objCrypt->GetEncryptedString(); %>
    <form action="https://ecomm.sella.it/gestpay/pagam.asp">
      <input type="hidden" name="a" value="<%= $a %>">
      <input type="hidden" name="b" value="<%= $b %>">
      <input type="submit" value="Go to payment">
    </form>
<% } %>

</body>
</html>

