<%@ LANGUAGE="PerlScript" %>
<html>
<body>

<%

#
# Esempio di implemetazione della Transazione numero 1
# così come descritta nelle Specifiche Tecniche di GestPay
#
# Questo script è chiamato dal browser del cliente
# attraverso la redirezione di GestPay
#

my %info = (
    ShopLogin        => '900001',
);

require Business::GestPayCrypt;
my $objCrypt = new Business::GestPayCrypt;

$objCrypt->SetShopLogin($info{'ShopLogin'});
$objCrypt->SetEncryptedString($Request->Form('b')->Item);

$objCrypt->Decrypt();

%>

<% if ( $objCrypt->GetErrorCode() ) { %>
    Si è verificato un errore:
    <br>Codice : <%= $objCrypt->GetErrorCode() %>
    <br>Descrizione : <% $objCrypt->GetErrorDescription() %>
<% } else { %>
    <br>ShopLogin : <%= $objCrypt->GetShopLogin() %>
    <br>Currency : <%= $objCrypt->GetCurrency() %>
    <br>Amount : <%= $objCrypt->GetAmount() %>
    <br>ShopTransactionID : <%= $objCrypt->GetShopTransactionID() %>
    <br>BuyerName : <%= $objCrypt->GetBuyerName() %>
    <br>BuyerEmail : <%= $objCrypt->GetBuyerEmail() %>
    <br>TransactionResult : <%= $objCrypt->GetTransactionResult() %>
    <br>AuthorizationCode : <%= $objCrypt->GetAuthorizationCode() %>
    <br>BankTransactionID : <%= $objCrypt->GetBankTransactionID() %>
    <br>AlertCode : <%= $objCrypt->GetAlertCode() %>
    <br>AlertDescription : <%= $objCrypt->GetAlertDescription() %>
    <br>CustomInfo : <%= $objCrypt->GetCustomInfo() %>
<% } %>

</body>
</html>

