package Business::OnlinePayment::PPIPayMover::CreditCardRequest;

use strict;
use vars qw(@ISA);
use Business::OnlinePayment::PPIPayMover::TransactionRequest;
use Business::OnlinePayment::PPIPayMover::CreditCardResponse;
use Business::OnlinePayment::PPIPayMover::AdditionalField;
use Business::OnlinePayment::PPIPayMover::constants;
use Business::OnlinePayment::PPIPayMover::CountryCodes;
use Business::OnlinePayment::PPIPayMover::URLEncoder;

@ISA = qw(Business::OnlinePayment::PPIPayMover::TransactionRequest);
1;

#default constructor
sub new {
  my $class = shift;
  my $self = $class->SUPER::new();

# Misc identification fields
  $self->{strCartridgeType}       = "";           # v1.5
  $self->{strEcommerceIndicator}  = "";           # v1.5

# credit card fields.
  
  $self->{strCreditCardNumber}    = "";
  $self->{strCreditCardVerificationNumber} = "";  # v1.5
  $self->{strAVSCode}             = "";           # v1.5
  $self->{strExpireMonth}         = "";
  $self->{strExpireYear}          = "";
  $self->{strChargeType}          = "";
  $self->{strChargeTotal}         = "";
  $self->{dChargeTotal}           = -1.0;
  $self->{strCardBrand}           = "";
  $self->{strCurrency}            = "";
  $self->{strOrderId}             = "";
  $self->{strBankApprovalCode}    = ""; # Required if chargetype is FORCE_AUTH or FORCE_SALE
  $self->{strDuplicateCheck} 		  = ""; #v1.7.1
  $self->{strReferenceId}  				= ""; 	# Required if chargetype is CAPTURE, QUERY_CREDIT, QUERY_PAYMENT or ADJUSTMENT
  $self->{strOrderDescription}    = "";
  $self->{strOrderUserId}         = "";
  $self->{strTaxAmount}           = "";
  $self->{dTaxAmount}             = -1.0;
  $self->{strShippingCharge}      = "";
  $self->{dShippingCharge}        = -1.0;
  
#   Billing info fields ...
  
  $self->{strBillFirstName}       = "";
  $self->{strBillLastName}        = "";
  $self->{strBillMiddleName}      = "";
  $self->{strBillCustomerTitle}   = "";
  $self->{strBillCompany}         = "";
  $self->{strBillAddressOne}      = "";
  $self->{strBillAddressTwo}      = "";
  $self->{strBillCity}            = "";
  $self->{strBillStateOrProvince} = "";
  $self->{strBillPostalCode}      = "";
  $self->{strBillCountryCode}     = "";
  $self->{strBillEmail}           = "";
  $self->{strBillPhone}           = "";
  $self->{strBillFax}             = "";
  $self->{strBillNote}            = "";
  
# Shipping info fields default values.
  
  $self->{strShipFirstName}       = "";
  $self->{strShipLastName}        = "";
  $self->{strShipMiddleName}      = "";
  $self->{strShipCustomerTitle}   = "";
  $self->{strShipCompany}         = "";
  $self->{strShipAddressOne}      = "";
  $self->{strShipAddressTwo}      = "";
  $self->{strShipCity}            = "";
  $self->{strShipStateOrProvince} = "";
  $self->{strShipPostalCode}      = "";
  $self->{strShipCountryCode}     = "";
  $self->{strShipEmail}           = "";
  $self->{strShipPhone}           = "";
  $self->{strShipFax}             = "";
  $self->{strShipNote}            = "";
  
# Authentication fields
  $self->{strAuthenticationTransactionId}       = "";
  $self->{strAuthenticationPayload}        	= "";
  $self->{boolSuccessOnAuthenticationInconclusive}      = "";


# Others
  $self->{strBuyerCode}           = "";
  $self->{strCAVV}                = "";
  $self->{strCustomerIPAddress}   = "";
  $self->{strPurchaseOrderNumber} = "";
  $self->{dStateTax}              = -1.0;
  $self->{strTrack1}              = "";
  $self->{strTrack2}              = "";
  $self->{strXID}                 = "";
  $self->{boolTaxExempt}          = "";
  $self->{strInvoiceNumber}       = "";
  
# Industry Fields
  $self->{strIndustry}	  	  = "";
  $self->{strFolioNumber}	  = "";
  
  $self->{boolChargeTotalIncludesRestaurant}     = "";
  $self->{boolChargeTotalIncludesGiftshop}       = "";
  $self->{boolChargeTotalIncludesMinibar}        = "";
  $self->{boolChargeTotalIncludesPhone}          = "";
  $self->{boolChargeTotalIncludesLaundry}        = "";
  $self->{boolChargeTotalIncludesOther}          = "";
  
  $self->{dServiceRate}           = -1.0;
  $self->{strServiceRate}           = "";
  $self->{intServiceEndDay}	  = "";
  $self->{intServiceEndMonth}	  = "";
  $self->{intServiceEndYear}	  = "";
  $self->{intServiceStartDay}	  = "";
  $self->{intServiceStartMonth}	  = "";
  $self->{intServiceStartYear}	  = "";
  $self->{boolServiceNoShow}     = "";
  
  return $self;
}



#**
# * Set the value of the cartridge type.
# * <p>
# */
sub SetCartridgeType {
  my $self = shift;
  my $cartType = shift;  # take one string arguement to get cartridgeType
  if (!defined($cartType)) {
    $self->{strError} = "Cartridge type is undefined.";
    return CCR_ERROR;
  }
  if ($cartType eq ""){
    $self->{strError} = "Invalid cartridge type.";
    return CCR_ERROR;
  }
  $self->{strCartridgeType} = $cartType;
  return CCR_NO_ERROR;
}


#**
# * Set the value of the Ecommerce Indicator number.
# * <p>
# */
sub SetEcommerceIndicator {
  my $self = shift;
  my $ecommerceIndicator = shift;  # take one string arguement to get EcommerceIndicator
  if (!defined($ecommerceIndicator)) {
    $self->{strError} = "Ecommerce indicator is undefined.";
    return CCR_ERROR;
  }
  if ($ecommerceIndicator eq ""){
    $self->{strError} = "Invalid ecommerce indicator.";
    return CCR_ERROR;
  }
  $self->{strEcommerceIndicator} = $ecommerceIndicator;
  return CCR_NO_ERROR;
}




#**
# * Set the value of the credit card number.
# * <p>
# * @param creditCardNumber must be numeric characters
# * @exception TransactionProtocolException thrown if creditCardNumber is non-numeric or the empty String.
# */
sub SetCreditCardNumber {
  my $self = shift;
  my $ccNo = shift;  # take one string arguement to get creditcard number
  if (!defined($ccNo)) {
    $self->{strError} = "Credit card number is undefined.";
    return CCR_ERROR;
  }
  if ($ccNo eq ""){
    $self->{strError} = "Invalid credit card number.";
    return CCR_ERROR;
  }
  if ($ccNo =~ /\D/) {
    $self->{strError} = "Non-numeric credit card number.";
    return CCR_ERROR;
  }
  if ( ( length $ccNo < 13 ) || ( length $ccNo > 19 ) ) {
    $self->{strError} = "Invalid credit card number length.";
    return CCR_ERROR;
  }
  $self->{strCreditCardNumber} = $ccNo;
  return CCR_NO_ERROR;
}

#**
# * Set the value of the credit card verification number.
# * <p>
# * @param creditCardVerificationNumber must be numeric characters
# */
sub SetCreditCardVerificationNumber {
  my $self = shift;
  my $ccVerNo = shift;  # take one string arguement to get creditCardVerification number
  if (!defined($ccVerNo)) {
    $self->{strError} = "Credit card verification number is undefined.";
    return CCR_ERROR;
  }
  if ($ccVerNo eq ""){
    $self->{strError} = "Invalid credit card verification number.";
    return CCR_ERROR;
  }
  if ($ccVerNo =~ /\D/) {
    $self->{strError} = "Non-numeric credit card verification number.";
    return CCR_ERROR;
  }
  $self->{strCreditCardVerificationNumber} = $ccVerNo;
  return CCR_NO_ERROR;
}


#**
# * Set the value of the credit card expiration month.
# * <p>
# * @param expireMonth Must be an integer in ASCII characters in the range "1" to "12, inclusive.
# * @exception TransactionProtocolException thrown if expireMonth is not >= 1 and <= 12.
# */
sub SetExpireMonth
{
  my $self = shift;
  my $expireMonth = shift; #take one string arguement
  if (!defined($expireMonth)) {
    $self->{strError} = "Expire month is undefined.";
    return CCR_ERROR;
  }
  if ($expireMonth eq ""){
    $self->{strError} = "Invalid expire month.";
    return CCR_ERROR;
  }
  
  if ($expireMonth =~ /\D/) {
    $self->{strError} = "Invalid credit expire month (non-digit).";
    return CCR_ERROR;
  }
  
  my $iExpireMonth = 1 * $expireMonth;
  if ($iExpireMonth < 1 || $iExpireMonth > 12) {
    $self->{strError} .= "Invalid expire month (not 1 through 12).";
    return CCR_ERROR;
  }
  $self->{strExpireMonth} = $expireMonth;
  
  return 1;
}


#**
# * Set the value of the credit card expiration year.
# * <p>
# * @param expireYear Must be a four-digit integer in ASCII characters. E.g. "2001".
# * @exception TransactionProtocolException thrown if expireYear is not a four digit year.
#
sub SetExpireYear
{
  my $self = shift;
  my $expireYear = shift; # take a string arguement
  if (!defined($expireYear)) {
    $self->{strError} = "Expire year is undefined.";
    return CCR_ERROR;
  }
  if (length($expireYear) != 4) {
    $self->{strError} = "Invalid expire year, must be 4 numeric characters.";
    return CCR_ERROR;
  }
  if($expireYear =~ /\D/){
    $self->{strError} = "Invalid credit expire year (non-numeric).";
    return CCR_ERROR;
  }
  
  $self->{strExpireYear} = $expireYear;
  return CCR_NO_ERROR;
}
#**
# * Set the charge type.
# * <p>
# * @param chargeType Must be one of the following constants: SALE, AUTH, CAPTURE, FORCE_AUTH,
# * FORCE_SALE, VOID, QUERY_CREDIT, QUERY_PAYMENT, ADJUSTMENT or CREDIT.
# * @exception TransactionProtocolException thrown if chargeType is not a valid charge type
# * defined by this class.
# */
sub SetChargeType
{
  my $self = shift;
  my $chargeType = shift;  # take one string arguement
  
  if (!defined($chargeType)) {
    $self->{strError} = "Charge type is undefined.";
    return CCR_ERROR;
  }
  if ($chargeType eq "") {
    $self->{strError} = "Invalid charge type";
    return CCR_ERROR;
  }
  
  if (!($chargeType eq SALE || $chargeType eq AUTH || 
        $chargeType eq CAPTURE || $chargeType eq VOID ||
        $chargeType eq FORCE_AUTH || $chargeType eq FORCE_SALE ||
        $chargeType eq QUERY_PAYMENT || $chargeType eq QUERY_CREDIT ||
        $chargeType eq CLOSE_ORDER || $chargeType eq CANCEL_ORDER ||
        $chargeType eq VOID_AUTH || $chargeType eq VOID_CAPTURE ||
        $chargeType eq VOID_CREDIT || $chargeType eq CREATE_ORDER ||
        $chargeType eq CREDIT || $chargeType eq ADJUSTMENT)) {
    $self->{strError} = "Invalid charge type.";
    return CCR_ERROR;
  }
  $self->{strChargeType} = $chargeType;
  return CCR_NO_ERROR;
}


#**
# * Set the transaction amount using a floating point value.  Other amounts, such
# * as tax amount or shipping charges, do not affect the charge total
# * <p>
# * @param chargeTotal Must be a positive floating-point number.
# * E.g. Use <i>12.34</i> to represent $12.34.
# * @exception TransactionProtocolException thrown if chargeTotal less than zero
# */
sub SetChargeTotal
{
  my $self = shift;
  my $chargeTotal = shift; # take either one string  or float arguement
  
  if (!defined($chargeTotal)) {
    $self->{strError} = "Charge total is undefined.";
    return CCR_ERROR;
  }
  
  if ( $chargeTotal !~ /^(\d+\.?\d*|\.\d+)$/ ) {
    $self->{strError} = "Non-numeric charge.";
    return CCR_ERROR;
  }
  
  my $dChargeTotal = $chargeTotal * 1.0;
  if ($dChargeTotal < 0){
    $self->{strError} = "Charge total cannot be negative.";
    return CCR_ERROR;
  }
  
  $self->{dChargeTotal} = $dChargeTotal;
  $self->{strChargeTotal} = "".$chargeTotal;
  
  return CCR_NO_ERROR;
}




#**
# * Set the transaction credit card brand.
# * <p>
# * @param cardBrand Must be one of the following constants:
# *	VISA, MASTERCARD, AMERICAN_EXPRESS, DISCOVER, NOVA, AMEX, DINERS, EUROCARD,
# *	CARD_BRAND_1, CARD_BRAND_2, CARD_BRAND_3, CARD_BRAND_4, CARD_BRAND_5, or CARD_BRAND_6.
# * @exception TransactionProtocolException thrown if cardBrand not one of the card brand constants
# * defined by this class.
# */
sub SetCardBrand
{
  my $self = shift;
  my $CardBrand = shift; # take a string arguement
  
  if (!defined($CardBrand) || $CardBrand eq ""){
    $self->{strError} = "Blank or undefined card type.";
    return CCR_ERROR;
  }
  
  if ($CardBrand ne VISA &&
    $CardBrand ne MASTERCARD &&
    $CardBrand ne AMERICAN_EXPRESS &&
    $CardBrand ne DISCOVER &&
    $CardBrand ne NOVA &&
    $CardBrand ne AMEX &&
    $CardBrand ne DINERS &&
    $CardBrand ne EUROCARD &&
    $CardBrand ne CARD_BRAND_1 &&
    $CardBrand ne CARD_BRAND_2 &&
    $CardBrand ne CARD_BRAND_3 &&
    $CardBrand ne CARD_BRAND_4 &&
    $CardBrand ne CARD_BRAND_5 &&
    $CardBrand ne CARD_BRAND_6) {
    $self->{strError} = "Invalid card brand:$CardBrand.";
    return CCR_ERROR;
  }
  $self->{strCardBrand} = $CardBrand;
  return CCR_NO_ERROR;
}

#**
# * Set the order ID.
# */
sub SetOrderId
{
  my $self = shift;
  my $OrderId = shift; # take a string arguement
  if (!defined($OrderId)) {
    $self->{strError} = "Order id is undefined.";
    return CCR_ERROR;
  }
  $self->{strOrderId} = $OrderId;
  return CCR_NO_ERROR;
}

#**
# * Set the capture reference ID (used in tracking captures / deposits).
# * This field is required if chargeType is CAPTURE.
# */
sub SetCaptureReferenceId
{
  my $self = shift;
  my $CaptureReferenceId = shift; #take a string arguement
  if (!defined($CaptureReferenceId)){
    $self->{strError} = "Capture reference id is undefined.";
    return CCR_ERROR;
  }
  $self->{strReferenceId} = $CaptureReferenceId;
  return CCR_NO_ERROR;
}

#
# Set Reference Id
# This should be used instead of SetCaptureReferenceId
# Added in v1.6
#
sub SetReferenceId
{
  my $self = shift;
  my $ReferenceId = shift; #take a string arguement
  if (!defined($ReferenceId)){
    $self->{strError} = "Reference id is undefined.";
    return CCR_ERROR;
  }
  $self->{strReferenceId} = $ReferenceId;
  return CCR_NO_ERROR;
}

#**
# * Set a comment describing the order.
# */
sub SetOrderDescription
{
  my $self = shift;
  my $OrderDescription = shift;  #take a string arguement
  if (!defined($OrderDescription)) {
    $self->{strError} = "Order description is undefined.";
    return CCR_ERROR;
  }
  $self->{strOrderDescription} = $OrderDescription;
  return CCR_NO_ERROR;
}


#/**
# * Set the order's user id.  The order user id is an identifier
# * for a merchant's customer.  It is not required, but may provide
# * increased searching functionality in the merchant support center.
# */
sub SetOrderUserId
{
  my $self = shift;
  my $OrderUserId = shift;  # take a string arguement
  if (!defined($OrderUserId)) {
    $self->{strError} = "Order user ID is undefined.";
    return CCR_ERROR;
  }
  $self->{strOrderUserId} = $OrderUserId;
  return CCR_NO_ERROR;
}

#**
# * Set the bank approval code (used in force sale and force auth).
# * This field is required if chargeType is FORCE_AUTH or FORCE_SALE.
# */
sub SetBankApprovalCode
{
  my $self = shift;
  my $BankApprovalCode = shift; #take a string arguement
  if (!defined($BankApprovalCode)){
    $self->{strError} = "Bank Approval Code is undefined.";
    return CCR_ERROR;
  }
  $self->{strBankApprovalCode} = $BankApprovalCode;
  return CCR_NO_ERROR;
}

#**
# * Set the duplicate check.
# * Possible values are CHECK, OVERRIDE, NO_CHECK
# */
sub SetDuplicateCheck
{
  my $self = shift;
  my $DuplicateCheck = shift; #take a string arguement
  if (!defined($DuplicateCheck)){
    $self->{strError} = "Duplicate Check is undefined.";
    return CCR_ERROR;
  }
  $self->{strDuplicateCheck} = $DuplicateCheck;
  return CCR_NO_ERROR;
}


#**
# * Set the tax amount using a floating point value.
# * The tax amount is the amount of the chargeTotal that is tax.
# * <p>
# * @param taxAmount Must be a positive floating-point number.
# * E.g. Use <i>11.55</i> to represent $11.55.
# * @exception TransactionProtocolException thrown if taxAmount less than zero
# */
sub SetTaxAmount
{
  my $self = shift;
  my $TaxAmount = shift; # take a string or an integer arguement
  
  if (!defined($TaxAmount)) {
    $self->{strError} = "Tax amount is undefined.";
    return CCR_ERROR;
  }
  if ( $TaxAmount !~ /^(\d+\.?\d*|\.\d+)$/ ) {
    $self->{strError} = "Non-numeric tax amount.";
    return CCR_ERROR;
  }
  
  my $dTaxAmount = $TaxAmount * 1.0;
  if ($dTaxAmount < 0) {
    $self->{strError} = "Tax amount cannot be negative.";
    return CCR_ERROR;
  }
  
  $self->{dTaxAmount} = $dTaxAmount;
  $self->{strTaxAmount} = "".$TaxAmount;
  return CCR_NO_ERROR;
}


#**
# * Set the shipping charge using a floating point value.
# * The shipping charge is the amount of the chargeTotal that is shipping charges.
# * <p>
# * @param shippingCharge Must be a positive floating-point number.
# * E.g. Use <i>11.55</i> to represent $11.55.
# * @exception TransactionProtocolException thrown if shippingCharge less than zero
# */
sub SetShippingCharge
{
  my $self = shift;
  my $ShippingCharge = shift; # take a string or an integer arguement
  
  if (!defined($ShippingCharge)) {
    $self->{strError} = "Shipping charge is undefined.";
    return CCR_ERROR;
  }
  if ( $ShippingCharge !~ /^(\d+\.?\d*|\.\d+)$/ ) {
    $self->{strError} = "Non-numeric shipping charge.";
    return CCR_ERROR;
  }
  
  my $dShippingCharge = $ShippingCharge * 1.0;
  if ($dShippingCharge < 0.00) {
    $self->{strError} = "Shipping charge cannot be negative.";
    return CCR_ERROR;
  }
  
  $self->{dShippingCharge} = $dShippingCharge;
  $self->{strShippingCharge} = "".$ShippingCharge;
  return CCR_NO_ERROR;
}


#**
# * Set the first name of the customer being billed.
# */
sub SetBillFirstName
{
  my $self = shift;
  my $BillFirstName = shift; # take a string arguement
  if (!defined($BillFirstName)) {
    $self->{strError} = "Bill first name is undefined.";
    return CCR_ERROR;
  }
  $self->{strBillFirstName} = $BillFirstName;
  return CCR_NO_ERROR;
}


#**
# * Set the last name of the customer being billed.
# */
sub SetBillLastName
{
  my $self = shift;
  my $BillLastName = shift; # take a string arguement
  if (!defined($BillLastName)) {
    $self->{strError} = "Bill last name is undefined.";
    return CCR_ERROR;
  }
  $self->{strBillLastName}  = $BillLastName;
  return CCR_NO_ERROR;
}


#**
# * Set the middle name of the customer being billed.
#
sub SetBillMiddleName
{
  my $self = shift;
  my $BillMiddleName = shift; # take a string arguement
  if (!defined($BillMiddleName)) {
    $self->{strError} = "Bill middle name is undefined.";
    return CCR_ERROR;
  }
  $self->{strBillMiddleName} = $BillMiddleName;
  return CCR_NO_ERROR;
}


#**
# * Set the title of the customer being billed, such as "Mr." or "Sales Manager".
#/
sub SetBillCustomerTitle
{
  my $self = shift;
  my $BillCustomerTitle = shift; # take a string arguement
  if (!defined($BillCustomerTitle)) {
    $self->{strError} = "Bill customer title is undefined.";
    return CCR_ERROR;
  }
  $self->{strBillCustomerTitle} = $BillCustomerTitle;
  return CCR_NO_ERROR;
}


#**
# * Set the name of the company of the customer being billed.
# */
sub SetBillCompany
{
  my $self = shift;
  my $BillCompany = shift; # take a string arguement
  if (!defined($BillCompany)) {
    $self->{strError} = "Bill company is undefined.";
    return CCR_ERROR;
  }
  $self->{strBillCompany} = $BillCompany;
  return CCR_NO_ERROR;
}


#**
# * Set the first part of the address of the customer being billed,
# * such as "1455 Cedar Springs Drive".
# */
sub SetBillAddressOne
{
  my $self = shift;
  my $BillAddressOne = shift; # take a string arguement
  if (!defined($BillAddressOne)) {
    $self->{strError} = "Bill address one  is undefined.";
    return CCR_ERROR;
  }
  $self->{strBillAddressOne} = $BillAddressOne;
  return CCR_NO_ERROR;
}


#*
# * Set the second part of the address of the customer being billed,
# * such as "Suite 100".
# */
sub SetBillAddressTwo
{
  my $self = shift;
  my $BillAddressTwo = shift; # take a string arguement
  if (!defined($BillAddressTwo)) {
    $self->{strError} = "Bill address two is undefined.";
    return CCR_ERROR;
  }
  $self->{strBillAddressTwo} = $BillAddressTwo;
  return CCR_NO_ERROR;
}


#**
# * Set the city of the customer being billed.
# */
sub SetBillCity
{
  my $self = shift;
  my $BillCity = shift; # take a string arguement
  if (!defined($BillCity)) {
    $self->{strError} = "Bill city is undefined.";
    return CCR_ERROR;
  }
  $self->{strBillCity} = $BillCity;
  return CCR_NO_ERROR;
}


#**
# * Set the state or province of the customer being billed.
# */
sub SetBillStateOrProvince
{
  my $self = shift;
  my $BillStateOrProvince = shift; # take a string arguement
  if (!defined($BillStateOrProvince)) {
    $self->{strError} = "Bill state or province is undefined.";
    return CCR_ERROR;
  }
  $self->{strBillStateOrProvince} = $BillStateOrProvince;
  return CCR_NO_ERROR;
}


#**
# * Set the postal code (or zip code) of the customer being billed.
# */
sub SetBillPostalCode
{
  my $self = shift;
  my $BillPostalCode = shift; # take a string arguement
  if (!defined($BillPostalCode)) {
    $self->{strError} = "Bill postal code is undefined.";
    return CCR_ERROR;
  }
  $self->{strBillPostalCode} = $BillPostalCode;
  return CCR_NO_ERROR;
}


#**
# * @param billCountryCode	The alphabetic country code of the billing address.
# * Must be a valid country code from ISO-3166. E.g. "CA" or "US".
# * <p>
# * @see com.paygateway.CountryCodes
# * @exception TransactionProtocolException thrown if an invalid country code is passed in
# */
sub SetBillCountryCode
{
  my $self = shift;
  my $BillCountryCode = shift; # take a string arguement (either country code or country name)
  
  if (!defined($BillCountryCode)) {
    $self->{strError} = "Country code is undefined.";
    return CCR_ERROR;
  }
  my $CountryCode = getCCodeFromCName($BillCountryCode);
  if (isValidCountryCode($BillCountryCode)) {
    $self->{strBillCountryCode}  = $BillCountryCode;
    return CCR_NO_ERROR;
  }
  elsif (defined($CountryCode))  {
    $self->{strBillCountryCode} = $CountryCode;
    return CCR_NO_ERROR;
  }
  else {
    $self->{strError} = "Invalid country code for billing address.";
    return CCR_ERROR;
  }
}


#**
# * Set the email address of the customer being billed.
# */
sub SetBillEmail
{
  my $self = shift;
  my $BillEmail = shift;
  if (!defined($BillEmail)) {
    $self->{strError} = "Bill email is undefined.";
    return CCR_ERROR;
  }
  if ($BillEmail !~ /.+@.+\..+/ ) {
    $self->{strError} = "Invalid bill email format.";
    return CCR_ERROR;
  }
  $self->{strBillEmail} = $BillEmail;
  return CCR_NO_ERROR;
}


#**
#* Set the phone number
#*/
sub SetBillPhone
{
  my $self = shift;
  my $BillPhone = shift; # take a string arguement
  if (!defined($BillPhone)) {
    $self->{strError} = "Bill phone is undefined.";
    return CCR_ERROR;
  }
  $self->{strBillPhone} = $BillPhone;
  return CCR_NO_ERROR;
}


#**
# * Set the facsimile number of the customer being billed.
# */
sub SetBillFax
{
  my $self = shift;
  my $BillFax = shift;
  if (!defined($BillFax)) {
    $self->{strError} = "Bill fax is undefined";
    return CCR_ERROR;
  }
  $self->{strBillFax} = $BillFax;
  return CCR_NO_ERROR;
}


#**
# * Set the billing note.  This a comment about the billing information.
# */
sub SetBillNote
{
  my $self = shift;
  my $BillNote = shift; #take a string arguement
  if (!defined($BillNote)) {
    $self->{strError} = "Bill note is undefined";
    return CCR_ERROR;
  }
  $self->{strBillNote} = $BillNote;
  return CCR_NO_ERROR;
}


#**
# * Set the first name for the shipping information.
# */
sub SetShipFirstName
{
  my $self = shift;
  my $ShipFirstName = shift; # take a string arguement
  if (!defined($ShipFirstName)) {
    $self->{strError} = "Ship first name is undefined";
    return CCR_ERROR;
  }
  $self->{strShipFirstName} = $ShipFirstName;
  return CCR_NO_ERROR;
}


#**
# * Set the last name for the shipping information.
# */
sub SetShipLastName
{
  my $self = shift;
  my $ShipLastName = shift;  # take a string arguement
  if (!defined($ShipLastName)) {
    $self->{strError} = "Ship last is undefined.";
    return CCR_ERROR;
  }
  $self->{strShipLastName} = $ShipLastName;
  return CCR_NO_ERROR;
}


#**
# * Set the middle name for the shipping information.
# */
sub SetShipMiddleName
{
  my $self = shift;
  my $ShipMiddleName = shift; # take a string arguement
  
  if (!defined($ShipMiddleName)) {
    $self->{strError} = "Ship middle name is undefined.";
    return CCR_ERROR;
  }
  $self->{strShipMiddleName} = $ShipMiddleName;
  return CCR_NO_ERROR;
}


#**
# * Set the customer title of the customer being jstrShipped to.
# */
sub SetShipCustomerTitle
{
  my $self = shift;
  my $ShipCustomerTitle = shift; # take a string arguement
  if (!defined($ShipCustomerTitle)) {
    $self->{strError} = "Ship customer title is undefined.";
    return CCR_ERROR;
  }
  $self->{strShipCustomerTitle} = $ShipCustomerTitle;
  return CCR_NO_ERROR;
}


#**
# * Set the company for the shipping information.
# */
sub SetShipCompany
{
  my $self = shift;
  my $ShipCompany = shift; # take a string arguement
  if (!defined($ShipCompany)) {
    $self->{strError} = "Ship company is undefined.";
    return CCR_ERROR;
  }
  $self->{strShipCompany} = $ShipCompany;
  return CCR_NO_ERROR;
}


#**
# * Set the first part of the shipping address, such as
# * "485 Bridestone Way".
# */
sub SetShipAddressOne
{
  my $self = shift;
  my $ShipAddressOne = shift; # take a string arguement
  if (!defined($ShipAddressOne)) {
    $self->{strError} = "Ship address is undefined.";
    return CCR_ERROR;
  }
  $self->{strShipAddressOne} = $ShipAddressOne;
  return CCR_NO_ERROR;
}


#**
# * Set the second part of the shipping address, such as
# * "Suite 234".

sub SetShipAddressTwo
{
  my $self = shift;
  my $ShipAddressTwo = shift; # take a string arguement
  if (!defined($ShipAddressTwo)) {
    $self->{strError} = "Ship address two is undefined.";
    return CCR_ERROR;
  }
  $self->{strShipAddressTwo} = $ShipAddressTwo;
  return CCR_NO_ERROR;
}


#**
# * Set the city for the shipping address.
# */
sub SetShipCity
{
  my $self = shift;
  my $ShipCity = shift; # take a string arguement
  if (!defined($ShipCity)) {
    $self->{strError} = "Ship city is undefined.";
    return CCR_ERROR;
  }
  $self->{strShipCity} = $ShipCity;
  return CCR_NO_ERROR;
}


#**
# * Set the state or provicnce for the shipping address.
# */
sub SetShipStateOrProvince
{
  my $self = shift;
  my $ShipStateOrProvince = shift; # take a string arguement
  if (!defined($ShipStateOrProvince)) {
    $self->{strError} = "Ship state or province is undefined.";
    return CCR_ERROR;
  }
  $self->{strShipStateOrProvince} = $ShipStateOrProvince;
  return CCR_NO_ERROR;
}


#**
# * Set the postal code (or zip code) for the shipping address.
# */
sub SetShipPostalCode
{
  my $self = shift;
  my $ShipPostalCode = shift; # take a string arguement
  if (!defined($ShipPostalCode)) {
    $self->{strError} = "Ship postal code is undefined.";
    return CCR_ERROR;
  }
  $self->{strShipPostalCode} = $ShipPostalCode;
  return CCR_NO_ERROR;
}

#**
# * Set the shipping country code.
# * @param shipCountryCode	The alphabetic country code of the billing address.
# * Must be a valid country code from ISO-3166. E.g. "CA" or "US".
# * <p>
# * @see com.paygateway.CountryCodes
# * @exception TransactionProtocolException thrown if an invalid country code is passed in
# */
sub SetShipCountryCode
{
  my $self = shift;
  my $ShipCountryCode = shift; # take a string arguement (either country code or country name)
  
  if (!defined($ShipCountryCode)) {
    $self->{strError} = "Ship country code is undefined.";
    return CCR_ERROR;
  }
  my $CountryCode = getCCodeFromCName($ShipCountryCode) ;
  if (isValidCountryCode($ShipCountryCode)) {
    $self->{strShipCountryCode}  = $ShipCountryCode;
    return CCR_NO_ERROR;
  }
  elsif (defined($CountryCode))  {
    $self->{strShipCountryCode} = $CountryCode;
    return CCR_NO_ERROR;
  }
  else {
    $self->{strError} = "Invalid country code for shipping address";
    return CCR_ERROR;
  }
}


#**
# * Set the email address of the customer being shipped to.
# */
sub SetShipEmail
{
  my $self = shift;
  my $ShipEmail = shift;  # take a string arguement
  if (!defined($ShipEmail)) {
    $self->{strError} = "Ship email is undefined.";
    return CCR_ERROR;
  }
  $self->{strShipEmail} = $ShipEmail;
  return CCR_NO_ERROR;
}


#**
# * Set the phone number of the customer being shipped to.
# */
sub SetShipPhone
{
  my $self = shift;
  my $ShipPhone = shift; # take a string arguement
  if (!defined($ShipPhone)) {
    $self->{strError} = "Ship phone is undefined";
    return CCR_ERROR;
  }
  $self->{strShipPhone} = $ShipPhone;
  return CCR_NO_ERROR;
}


#**
# * Set the facsimile number of the customer being shipped to.
# */
sub SetShipFax
{
  my $self = shift;
  my $ShipFax = shift; # take a string arguement
  if (!defined($ShipFax)) {
    $self->{strError} = "Ship fax is undefined";
    return CCR_ERROR;
  }
  $self->{strShipFax} = $ShipFax;
  return CCR_NO_ERROR;
}


#**
# * Set a note (comment) for the shipping information.
# */
sub SetShipNote
{
  my $self = shift;
  my $ShipNote = shift;
  if (!defined($ShipNote)) {
    $self->{strError} = "Ship note is undefined.";
    return CCR_ERROR;
  }
  $self->{strShipNote} = $ShipNote;
  return CCR_NO_ERROR;
}


#/**
# * Sets the currency
# */
sub SetCurrency
{
  my $self = shift;
  my $Currency = shift;  # take a string arguement
  if (!defined($Currency)) {
    $self->{strError} = "Currency is undefined.";
    return CCR_ERROR;
  }
  $self->{strCurrency} = $Currency;
  return CCR_NO_ERROR;
}

#/**
# * Sets the buyer code
# */
sub SetBuyerCode
{
  my $self = shift;
  my $buyerCode = shift;  # take a string arguement
  if (!defined($buyerCode)) {
    $self->{strError} = "Buyer code is undefined.";
    return CCR_ERROR;
  }
  $self->{strBuyerCode} = $buyerCode;
  return CCR_NO_ERROR;
}

#/**
# * Sets the CAVV (for VBV transactions)
# */
sub SetCAVV
{
  my $self = shift;
  my $cavv = shift;  # take a string arguement
  if (!defined($cavv)) {
    $self->{strError} = "CAVV is undefined.";
    return CCR_ERROR;
  }
  $self->{strCAVV} = $cavv;
  return CCR_NO_ERROR;
}

#/**
# * Sets the Customer IP Address
# */
sub SetCustomerIPAddress
{
  my $self = shift;
  my $ip = shift;  # take a string arguement
  if (!defined($ip)) {
    $self->{strError} = "Customer IP address is undefined.";
    return CCR_ERROR;
  }
  $self->{strCustomerIPAddress} = $ip;
  return CCR_NO_ERROR;
}

#/**
# * Sets the Order Customer ID
# */
sub SetOrderCustomerId
{
  my $self = shift;
  my $orderCustomerID = shift;  # take a string arguement
  if (!defined($orderCustomerID)) {
    $self->{strError} = "Order customer ID is undefined.";
    return CCR_ERROR;
  }
  $self->{strOrderCustomerID} = $orderCustomerID;
  return CCR_NO_ERROR;
}

#/**
# * Sets the purchase order number
# */
sub SetPurchaseOrderNumber
{
  my $self = shift;
  my $purchaseOrderNumber = shift;  # take a string arguement
  if (!defined($purchaseOrderNumber)) {
    $self->{strError} = "Purchase order number is undefined.";
    return CCR_ERROR;
  }
  $self->{strPurchaseOrderNumber} = $purchaseOrderNumber;
  return CCR_NO_ERROR;
}

#/**
# * Sets the state tax
# */
sub SetStateTax
{
  my $self = shift;
  my $stateTax = shift;  # take a string arguement
  if (!defined($stateTax)) {
    $self->{strError} = "State tax is undefined.";
    return CCR_ERROR;
  }

  if ( $stateTax !~ /^(\d+\.?\d*|\.\d+)$/ ) {
    $self->{strError} = "Non-numeric state tax amount.";
    return CCR_ERROR;
  }
  
  $stateTax = $stateTax * 1.0;
  if ($stateTax < 0) {
    $self->{strError} = "State tax cannot be negative.";
    return CCR_ERROR;
  }

  $self->{dStateTax} = $stateTax;
  return CCR_NO_ERROR;
}

#/**
# * Sets the track 1 data
# */
sub SetTrack1
{
  my $self = shift;
  my $track1 = shift;  # take a string arguement
  if (!defined($track1)) {
    $self->{strError} = "Track 1 is undefined.";
    return CCR_ERROR;
  }
  $self->{strTrack1} = $track1;
  return CCR_NO_ERROR;
}

#/**
# * Sets the track 2 data
# */
sub SetTrack2
{
  my $self = shift;
  my $track2 = shift;  # take a string arguement
  if (!defined($track2)) {
    $self->{strError} = "Track 2 is undefined.";
    return CCR_ERROR;
  }
  $self->{strTrack2} = $track2;
  return CCR_NO_ERROR;
}

#/**
# * Sets the transaction condition code
# */
sub SetTransactionConditionCode
{
  my $self = shift;
  my $tcc = shift;  # take a string arguement
  if (!defined($tcc)) {
    $self->{strError} = "Transaction condition code is undefined.";
    return CCR_ERROR;
  }
  $self->{strTransactionConditionCode} = $tcc;
  return CCR_NO_ERROR;
}

#/**
# * Sets the xid
# */
sub SetXID
{
  my $self = shift;
  my $xid = shift;  # take a string arguement
  if (!defined($xid)) {
    $self->{strError} = "XID is undefined.";
    return CCR_ERROR;
  }
  $self->{strXID} = $xid;
  return CCR_NO_ERROR;
}

#/**
# * Sets tax exempt flag
# */
sub SetTaxExempt
{
  my $self = shift;
  my $taxExempt = shift;  # take a string arguement
  if (!defined($taxExempt)) {
    $self->{strError} = "Tax exempt flag is undefined.";
    return CCR_ERROR;
  }
  $self->{boolTaxExempt} = $taxExempt;
  return CCR_NO_ERROR;
}

#/**
# * Sets invoice number
# */
sub SetInvoiceNumber
{
  my $self = shift;
  my $invoiceNumber = shift;  # take a string arguement
  if (!defined($invoiceNumber)) {
    $self->{strError} = "Invoice number is undefined.";
    return CCR_ERROR;
  }
  $self->{strInvoiceNumber} = $invoiceNumber;
  return CCR_NO_ERROR;
}

#/**
# * Sets the Authentication Transaction ID
# * 
# * Used in Payer Authentication transaction type
# */
sub SetAuthenticationTransactionId
{
  my $self = shift;
  my $authenticationTransactionId = shift;  # take a string arguement
  if (!defined($authenticationTransactionId)) {
    $self->{strError} = "Authentication Transaction ID is undefined.";
    return CCR_ERROR;
  }
  $self->{strAuthenticationTransactionId} = $authenticationTransactionId;
  return CCR_NO_ERROR;
}

#/**
# * Sets the Authentication Payload
# * 
# * Used in Payer Authentication transaction type
# */
sub SetAuthenticationPayload
{
  my $self = shift;
  my $authenticationPayload = shift;  # take a string arguement
  if (!defined($authenticationPayload)) {
    $self->{strError} = "Authentication Payload is undefined.";
    return CCR_ERROR;
  }
  $self->{strAuthenticationPayload} = $authenticationPayload;
  return CCR_NO_ERROR;
}

#/**
# * Sets the Success On Authentication Inconclusive
# * 
# * Used in Payer Authentication transaction type
# */
sub SetDoTransactionOnAuthenticationInconclusive
{
  my $self = shift;
  my $successOnAuthenticationInconclusive = shift;  # take a string arguement
  if (!defined($successOnAuthenticationInconclusive)) {
    $self->{strError} = "Success on authentication inconclusive is undefined.";
    return CCR_ERROR;
  }
  $self->{boolSuccessOnAuthenticationInconclusive} = $successOnAuthenticationInconclusive;
  return CCR_NO_ERROR;
}


#**
# * Set the Industry type.
# * <p>
# * @param industry Must be one of the following constants: DIRECT_MARKETING, RETAIL, LODGING, RESTAURANT.
# * @exception TransactionProtocolException thrown if industry is not a valid charge type
# * defined by this class.
# */
sub SetIndustry
{
  my $self = shift;
  my $industry = shift;  # take one string arguement
  
  if (!defined($industry)) {
    $self->{strError} = "Industry is undefined.";
    return CCR_ERROR;
  }
  if ($industry eq "") {
    $self->{strError} = "Invalid industry";
    return CCR_ERROR;
  }
  
  if (!($industry eq DIRECT_MARKETING ||
  	$industry eq RETAIL || 
        $industry eq LODGING ||
        $industry eq RESTAURANT )) {
    $self->{strError} = "Invalid industry.";
    return CCR_ERROR;
  }
  $self->{strIndustry} = $industry;
  return CCR_NO_ERROR;
}


#/**
# * Sets folio number
# */
sub SetFolioNumber
{
  my $self = shift;
  my $folioNumber = shift;  # take a string arguement
  if (!defined($folioNumber)) {
    $self->{strError} = "Folio number is undefined.";
    return CCR_ERROR;
  }
  $self->{strFolioNumber} = $folioNumber;
  return CCR_NO_ERROR;
}



#**
# * Set the service rate using a floating point value.
# * <p>
# * @param ServiceRate Must be a positive floating-point number.
# * E.g. Use <i>11.55</i> to represent $11.55.
# * @exception TransactionProtocolException thrown if ServiceRate less than zero
# */
sub SetServiceRate
{
  my $self = shift;
  my $ServiceRate = shift; # take a string or an integer arguement
  
  if (!defined($ServiceRate)) {
    $self->{strError} = "Service rate is undefined.";
    return CCR_ERROR;
  }
  if ( $ServiceRate !~ /^(\d+\.?\d*|\.\d+)$/ ) {
    $self->{strError} = "Non-numeric Service Rate.";
    return CCR_ERROR;
  }
  
  my $dServiceRate = $ServiceRate * 1.0;
  if ($dServiceRate < 0) {
    $self->{strError} = "Service rate cannot be negative.";
    return CCR_ERROR;
  }
  
  $self->{dServiceRate} = $dServiceRate;
  $self->{strServiceRate} = "".$ServiceRate;
  return CCR_NO_ERROR;
}


#**
# * Set the service end day
# */  
sub SetServiceEndDay
{
  my $self = shift;
  my $serviceEndDay = shift; #take one string arguement
  if (!defined($serviceEndDay)) {
    $self->{strError} = "Service end day is undefined.";
    return CCR_ERROR;
  }
  if ($serviceEndDay eq ""){
    $self->{strError} = "Invalid service end day.";
    return CCR_ERROR;
  }
  
  if ($serviceEndDay =~ /\D/) {
    $self->{strError} = "Invalid service end day (non-digit).";
    return CCR_ERROR;
  }
  
  $serviceEndDay = 1 * $serviceEndDay;
  if ($serviceEndDay < 1 || $serviceEndDay > 31) {
    $self->{strError} .= "Invalid service end day (not 1 through 31).";
    return CCR_ERROR;
  }
  $self->{intServiceEndDay} = $serviceEndDay;
  
  return 1;
}  

  
#**
# * Set the service end month
# */  
sub SetServiceEndMonth
{
  my $self = shift;
  my $serviceEndMonth = shift; #take one string arguement
  if (!defined($serviceEndMonth)) {
    $self->{strError} = "Service end month is undefined.";
    return CCR_ERROR;
  }
  if ($serviceEndMonth eq ""){
    $self->{strError} = "Invalid service end month.";
    return CCR_ERROR;
  }
  
  if ($serviceEndMonth =~ /\D/) {
    $self->{strError} = "Invalid service end month (non-digit).";
    return CCR_ERROR;
  }
  
  $serviceEndMonth = 1 * $serviceEndMonth;
  if ($serviceEndMonth < 1 || $serviceEndMonth > 12) {
    $self->{strError} .= "Invalid service end month (not 1 through 12).";
    return CCR_ERROR;
  }
  $self->{intServiceEndMonth} = $serviceEndMonth;
  
  return 1;
}   
  
#**
# * Set the service end year
# */  
sub SetServiceEndYear
{
  my $self = shift;
  my $serviceEndYear = shift; #take one string arguement
  if (!defined($serviceEndYear)) {
    $self->{strError} = "Service end year is undefined.";
    return CCR_ERROR;
  }
  if ($serviceEndYear eq ""){
    $self->{strError} = "Invalid service end year.";
    return CCR_ERROR;
  }
  
  if ($serviceEndYear =~ /\D/) {
    $self->{strError} = "Invalid service end year (non-digit).";
    return CCR_ERROR;
  }
  
  $serviceEndYear = 1 * $serviceEndYear;
  if ($serviceEndYear < 2005 || $serviceEndYear > 9999) {
    $self->{strError} .= "Invalid service end year.";
    return CCR_ERROR;
  }
  $self->{intServiceEndYear} = $serviceEndYear;
  
  return 1;
}  


#**
# * Set the service start day
# */  
sub SetServiceStartDay
{
  my $self = shift;
  my $serviceStartDay = shift; #take one string arguement
  if (!defined($serviceStartDay)) {
    $self->{strError} = "Service start day is undefined.";
    return CCR_ERROR;
  }
  if ($serviceStartDay eq ""){
    $self->{strError} = "Invalid service start day.";
    return CCR_ERROR;
  }
  
  if ($serviceStartDay =~ /\D/) {
    $self->{strError} = "Invalid service start day (non-digit).";
    return CCR_ERROR;
  }
  
  $serviceStartDay = 1 * $serviceStartDay;
  if ($serviceStartDay < 1 || $serviceStartDay > 31) {
    $self->{strError} .= "Invalid service start day (not 1 through 31).";
    return CCR_ERROR;
  }
  $self->{intServiceStartDay} = $serviceStartDay;
  
  return 1;
}  

  
#**
# * Set the service start month
# */  
sub SetServiceStartMonth
{
  my $self = shift;
  my $serviceStartMonth = shift; #take one string arguement
  if (!defined($serviceStartMonth)) {
    $self->{strError} = "Service start month is undefined.";
    return CCR_ERROR;
  }
  if ($serviceStartMonth eq ""){
    $self->{strError} = "Invalid service start month.";
    return CCR_ERROR;
  }
  
  if ($serviceStartMonth =~ /\D/) {
    $self->{strError} = "Invalid service start month (non-digit).";
    return CCR_ERROR;
  }
  
  $serviceStartMonth = 1 * $serviceStartMonth;
  if ($serviceStartMonth < 1 || $serviceStartMonth > 12) {
    $self->{strError} .= "Invalid service start month (not 1 through 12).";
    return CCR_ERROR;
  }
  $self->{intServiceStartMonth} = $serviceStartMonth;
  
  return 1;
}   
  
#**
# * Set the service start year
# */  
sub SetServiceStartYear
{
  my $self = shift;
  my $serviceStartYear = shift; #take one string arguement
  if (!defined($serviceStartYear)) {
    $self->{strError} = "Service start year is undefined.";
    return CCR_ERROR;
  }
  if ($serviceStartYear eq ""){
    $self->{strError} = "Invalid service start year.";
    return CCR_ERROR;
  }
  
  if ($serviceStartYear =~ /\D/) {
    $self->{strError} = "Invalid service start year (non-digit).";
    return CCR_ERROR;
  }
  
  $serviceStartYear = 1 * $serviceStartYear;
  if ($serviceStartYear < 2005 || $serviceStartYear > 9999) {
    $self->{strError} .= "Invalid service start year.";
    return CCR_ERROR;
  }
  $self->{intServiceStartYear} = $serviceStartYear;
  
  return 1;
}  



#/**
# * Sets the Charge Total Includes Restaurant flag
# * 
# */
sub SetChargeTotalIncludesRestaurant
{
  my $self = shift;
  my $isChargeTotalIncludesRestaurant = shift;  # take a string arguement
  if (!defined($isChargeTotalIncludesRestaurant)) {
    $self->{strError} = "Charge Total Includes Restaurant is undefined.";
    return CCR_ERROR;
  }
  $self->{boolChargeTotalIncludesRestaurant} = $isChargeTotalIncludesRestaurant;
  return CCR_NO_ERROR;
}

#/**
# * Sets the Charge Total Includes Giftshop flag
# * 
# */
sub SetChargeTotalIncludesGiftshop
{
  my $self = shift;
  my $isChargeTotalIncludesGiftshop = shift;  # take a string arguement
  if (!defined($isChargeTotalIncludesGiftshop)) {
    $self->{strError} = "Charge Total Includes Giftshop is undefined.";
    return CCR_ERROR;
  }
  $self->{boolChargeTotalIncludesGiftshop} = $isChargeTotalIncludesGiftshop;
  return CCR_NO_ERROR;
}

#/**
# * Sets the Charge Total Includes Minibar flag
# * 
# */
sub SetChargeTotalIncludesMinibar
{
  my $self = shift;
  my $isChargeTotalIncludesMinibar = shift;  # take a string arguement
  if (!defined($isChargeTotalIncludesMinibar)) {
    $self->{strError} = "Charge Total Includes Minibar is undefined.";
    return CCR_ERROR;
  }
  $self->{boolChargeTotalIncludesMinibar} = $isChargeTotalIncludesMinibar;
  return CCR_NO_ERROR;
}

#/**
# * Sets the Charge Total Includes Phone flag
# * 
# */
sub SetChargeTotalIncludesPhone
{
  my $self = shift;
  my $isChargeTotalIncludesPhone = shift;  # take a string arguement
  if (!defined($isChargeTotalIncludesPhone)) {
    $self->{strError} = "Charge Total Includes Phone is undefined.";
    return CCR_ERROR;
  }
  $self->{boolChargeTotalIncludesPhone} = $isChargeTotalIncludesPhone;
  return CCR_NO_ERROR;
}

#/**
# * Sets the Charge Total Includes Laundry flag
# * 
# */
sub SetChargeTotalIncludesLaundry
{
  my $self = shift;
  my $isChargeTotalIncludesLaundry = shift;  # take a string arguement
  if (!defined($isChargeTotalIncludesLaundry)) {
    $self->{strError} = "Charge Total Includes Laundry is undefined.";
    return CCR_ERROR;
  }
  $self->{boolChargeTotalIncludesLaundry} = $isChargeTotalIncludesLaundry;
  return CCR_NO_ERROR;
}

#/**
# * Sets the Charge Total Includes Other flag
# * 
# */
sub SetChargeTotalIncludesOther
{
  my $self = shift;
  my $isChargeTotalIncludesOther = shift;  # take a string arguement
  if (!defined($isChargeTotalIncludesOther)) {
    $self->{strError} = "Charge Total Includes Other is undefined.";
    return CCR_ERROR;
  }
  $self->{boolChargeTotalIncludesOther} = $isChargeTotalIncludesOther;
  return CCR_NO_ERROR;
}

#/**
# * Sets the Service No Show flag
# * 
# */
sub SetServiceNoShow
{
  my $self = shift;
  my $isServiceNoShow = shift;  # take a string arguement
  if (!defined($isServiceNoShow)) {
    $self->{strError} = "Service No Show is undefined.";
    return CCR_ERROR;
  }
  $self->{boolServiceNoShow} = $isServiceNoShow;
  return CCR_NO_ERROR;
}



#/////////////////////////////////////////////////////////////////////////////////////////////////////
#// Get Methods.
#

#/**
# * Get the cartridge type.
# * @returns the type of cartridge being used
# */
sub GetCartridgeType
{
  my $self = shift;
  $self->{strCartridgeType};
}

#/**
# * Get the Ecommerce Indicator
# * @returns the Ecommerce Indicator
# */
sub GetEcommerceIndicator
{
  my $self = shift;
  $self->{strEcommerceIndicator};
}

#/**
# * Get the value of the credit card number.
# * @see #setCreditCardNumber(JString)
# * @return the value of the credit card number or an empty String if the credit card number was not set
# */
sub GetCreditCardNumber
{
  my $self = shift;
  $self->{strCreditCardNumber};
}

#/**
# * Get the value of the credit card number.
# * @return the value of the credit card verification number or an empty String if the credit card number was not set
# */
sub GetCreditCardVerificationNumber
{
  my $self = shift;
  $self->{strCreditCardVerificationNumber};
}

#**
# * Get the value of the credit card's expire year.
# * @see #setExpireYear(JString)
# * @return the String passed to setExpireYear or an empty String if the expire year was not set
# */
sub GetExpireYear
{
  my $self = shift;
  $self->{strExpireYear};
}


#**
# * Get the value of the credit card's expire month.
# * @see #setExpireMonth(String)
# * @return the String passed to setExpireMonth or an empty String if the expire month was not set
# */
sub GetExpireMonth
{
  my $self = shift;
  $self->{strExpireMonth};
}


#**
# * Get the value of the charge type.  The possible values are defined
# * by the constants of this class documented in setChargeType(String)
# * The chage type indicates what action to take with this credit card
# * transaction.
# * @see #setChargeType(String)
# * @return the String passed to setChargeType or an empty String if the charge type was not set
#
sub GetChargeType()
{
  my $self = shift;
  $self->{strChargeType};
}


#**
# * Get the value of the charge total.  The charge total is the amount that
# * will be used for this credit card transaction.
# * @see #setChargeTotal(double)
# * @see #setChargeTotal(String)
# * @return the value of the charge total or -1 if the charge total was not set
#
sub GetChargeTotal
{
  my $self = shift;
  $self->{dChargeTotal};
}

sub GetChargeTotalStr
{
  my $self = shift;
  $self->{strChargeTotal};
}

#**
# * Get the value of the card brand.  The card brand identifies the type
# * of card being used.  The card brand must be one of the constants defined
# * by this class and documented in setCardBrand(JString)
# * @see #setCardBrand(JString)
# * @return the value of the card brand or an empty String if the card brand was not set
#/
sub GetCardBrand
{
  my $self = shift;
  $self->{strCardBrand};
}

#**
# * Get the value of the order id.  The order id must be a unique identifier
# * for a paticular order.
# * @see #setOrderId(JString)
# * @return the value of the order id or an empty String if the order id was not set
# */
sub GetOrderId
{
  my $self = shift;
  $self->{strOrderId};
}



#**
# * Get the value of the capture reference id.  The capture reference id is the
# * value returned from an "AUTH" credit card transaction that must be presented
# * when to the "CAPTURE" for that order.
# * @see #setCaptureReferenceId(JString)
# * @return the value of the capture reference id or an empty String if the capture reference id was not set
#
sub GetCaptureReferenceId
{
  my $self = shift;
  $self->{strReferenceId};
}

#
# Get Reference Id
# This should be used instead of GetCaptureReferenceId
# Added in v1.6
#
sub GetReferenceId
{
  my $self = shift;
  $self->{strReferenceId};
}

#/**
# * Get the value of the order description.  The order description is a comment
# * that describes the order.
# * @see #setOrderDescription(JString)
# * @return the value of the order description or an empty String if the order description was not set
#/
sub GetOrderDescription
{
  my $self = shift;
  $self->{strOrderDescription};
}

#**
# * Get the value of the order user id.  The order user id is a unique identifier
# * for a merchant's customer.
# * @see #setOrderUserId(String)
# * @return the value of the order user id of an empty String if order user id was not set
#
sub GetOrderUserId
{
  my $self = shift;
  $self->{strOrderUserId};
}

#**
# * Get the value of the duplicate check.  
# * Possible values are: CHECK; OVERRIDE; NO_CHECK.
# * @see #setDuplicateCheck(String)
# * @return the value of the duplicate check or an empty String if the dc was not set
#
sub GetDuplicateCheck
{
  my $self = shift;
  $self->{strDuplicateCheck};
}


#**
# * Get the value of the bank approval code.  The bank approval code is the
# * value required for a "FORCE_AUTH" or "FORCE_SALE" credit card transaction.
# * It is obtained offline via a phone call to the merchant's bank 'voice auth' 
# * phone number.  The card holder is not present in this type of transaction.
# * @see #setBankApprovalCode(String)
# * @return the value of the bank approval code or an empty String if the bac was not set
#
sub GetBankApprovalCode
{
  my $self = shift;
  $self->{strBankApprovalCode};
}


#**
# * The tax amount is the amount of the the charge total that is tax.
# * @see #setTaxAmount
# * @see #setChargeTotal
# * @return value of the tax amount of -1 if the tax amount has not been set.
#
sub GetTaxAmount
{
  my $self = shift;
  $self->{dTaxAmount};
}

sub GetTaxAmountStr
{
  my $self = shift;
  $self->{strTaxAmount};
}


#**
# * The shipping charge is the amount of the charge total that is shipping charges.
# * @see #setShippingCharge
# * @see #setChargeTotal
# * @return value of the shipping charge or -1 if the shipping charge has not been set
# */
sub GetShippingCharge
{
  my $self = shift;
  $self->{dShippingCharge};
}

sub GetShippingChargeStr
{
  my $self = shift;
  $self->{strShippingCharge};
}


#/**
# * Get the value of the first name of the customer being billed.
# * @see #setBillFirstName(JString)
# * @return the billing first name or an empty String if the billing first name was not set
# */
sub GetBillFirstName
{
  my $self = shift;
  $self->{strBillFirstName};
}


#**
# * Get the value of the last name of the customer being billed.
# * @see #setBillLastName(String)
# * return the billing last name or an empty String if the billing last name was not set
# */
sub GetBillLastName
{
  my $self = shift;
  $self->{strBillLastName};
}


#**
# * Get the value of the middle name of the customer being billed.
# * @see #setBillMiddleName(JString)
# * @return the billing middle name or an empty String if the billing middle name was not set
# */
sub GetBillMiddleName
{
  my $self = shift;
  $self->{strBillMiddleName};
}


#**
# * Get the value of the title of the customer being billed.
# * @see #setBillCustomerTitle(JString)
# * @return the billing customer title or an empty String if billing customer title was not set
# */
sub GetBillCustomerTitle
{
  my $self = shift;
  $self->{strBillCustomerTitle};
}

#**
# * Get the value of the company name of the customer being billed.
# * @see #setBillCompany(JString)
# * @return the billing company name or an empty String if the billing company name was not set
#
sub GetBillCompany
{
  my $self = shift;
  $self->{strBillCompany};
}


#**
# * Get the value of the first part of the billing address.
# * @see #setBillAddressOne(JString)
# * @return the first part of the billing address or an empty String if the billing address part one was not set
# */
sub GetBillAddressOne
{
  my $self = shift;
  $self->{strBillAddressOne};
}


#**
# * Get the value of the second part of the billing address.
# * @see #setBillAddressTwo(JString)
# * @return the second part of the billing address or an empty String if the billing address part two was not set
# */
sub GetBillAddressTwo
{
  my $self = shift;
  $self->{strBillAddressTwo};
}


#**
# * Get the value of the city for the billing address.
# * @see #setBillCity(JString)
# * @return the billing address city or an empty String if the billing city was not set
# */
sub GetBillCity
{
  my $self = shift;
  $self->{strBillCity};
}


#**
# * Get the value of the state or province for the billing address.
# * @see #setBillStateOrProvince(String)
# * @return the billing address state or province or an empty String if billing state or province was not set
# */
sub GetBillStateOrProvince
{
  my $self = shift;
  $self->{strBillStateOrProvince};
}


#**
# * Get the value of the postal code for the billing address.
# * @see #setBillPostalCode(String)
# * @return the billing address postal code or an empty String if billing postal code was not set
#*/
sub GetBillPostalCode
{
  my $self = shift;
  $self->{strBillPostalCode};
}


#**
# * Get the value of the country for the billing address.
# * @see #setBillCountryCode(JString)
# * @return the billing country or an empty String if the billing country was not set
#
sub GetBillCountryCode
{
  my $self = shift;
  $self->{strBillCountryCode};
}


#**
# * Get the value of the email address of the customer being billed.
# * @see #setBillEmail(JString)
# * @return the billing email address or an empty String if the billing email was not set
#
sub GetBillEmail
{
  my $self = shift;
  $self->{strBillEmail};
}


#**
# * Get the value of the phone number of the customer being billed.
# * @see #setBillPhone(JString)
# * @return the billing phone number or an empty String if the billing phone number was not set
# */
sub GetBillPhone
{
  my $self = shift;
  $self->{strBillPhone};
}


#**
# * Get the value of the fax number of the customer being billed.
# * @see #setBillFax(JString)
# * @return the billing fax number or an empty String if the billing fax number was not set
# */
sub GetBillFax
{
  my $self = shift;
  $self->{strBillFax};
}


#**
# * Get the value of the billing note.  The billing note is an extra
# * comment to the billing information.
# * @see #setBillNote(JString)
# * @return the billing note or an empty String if the billing not was not set
#
sub GetBillNote
{
  my $self = shift;
  $self->{strBillNote};
}

#**
# * Get the value of the first name of the customer being shipped to.
# * @see #setShipFirstName(JString)
# * @return the shipping first name or an empty String if the shipping first name was not set
#
sub GetShipFirstName
{
  my $self = shift;
  $self->{strShipFirstName};
}


#**
# * Get the value of the last name of the customer being shipped to.
# * @see #setShipLastName(JString)
# * @return the shipping last name or an empty String if the shipping last name was not set
# */
sub GetShipLastName
{
  my $self = shift;
  $self->{strShipLastName};
}


#**
# * Get the value of the middle name of the customer being shipped to.
# * @see #setShipMiddleName(JString)
# * @return the shipping middle name or an empty String if the shipping middle name was not set
# */
sub GetShipMiddleName
{
  my $self = shift;
  $self->{strShipMiddleName};
}


#**
# * Get the value of the title of the customer being shipped to.
# * @see #setShipCustomerTitle(String)
# * @return the shipping customer title or an empty String if the shipping customer title was not set
#
sub GetShipCustomerTitle
{
  my $self = shift;
  $self->{strShipCustomerTitle};
}


#**
# * Get the value of the company name of the customer being shipped to.
# * @see #setShipCompany(JString)
# * @return the shipping company name or an empty String if the shipping company name was not set
# */
sub GetShipCompany
{
  my $self = shift;
  $self->{strShipCompany};
}


#**
# * Get the value of the first part of the shipping address.
# * @see #setShipAddressOne(JString)
# * @return the first part of the shipping address or an empty String if the shipping address part one was not set
# */
sub GetShipAddressOne
{
  my $self = shift;
  $self->{strShipAddressOne};
}


#**
# * Get the value of the second part of the shipping address.
# * @see #setShipAddressTwo(JString)
# * @return the second part of the shipping address or an empty String if the shipping address part two was not set
#
sub GetShipAddressTwo
{
  my $self = shift;
  $self->{strShipAddressTwo};
}


#**
# * Get the value of the city for the shipping address.
# * @see #setShipCity(JString)
# * @return the shipping address city or an empty String if the shipping city was not set
#
sub GetShipCity
{
  my $self = shift;
  $self->{strShipCity};
}

#**
# * Get the value of the state or province for the shipping address.
# * @see #setShipStateOrProvince(JString)
# * @return the shipping address state or province or an empty String if the shipping state or provice was not set
# */
sub GetShipStateOrProvince
{
  my $self = shift;
  $self->{strShipStateOrProvince};
}


#*
# * Get the value of the postal code for the shipping address.
# * @see #setShipPostalCode(JString)
# * @return the shipping address postal code or an empty String if the shipping postal code was not set
# */
sub GetShipPostalCode
{
  my $self = shift;
  $self->{strShipPostalCode};
}


#**
# * Get the value of the country for the shipping address.
# * @see #setShipCountryCode(JString)
# * @return the shipping country or an empty String if the shipping country was not set
# */
sub GetShipCountryCode
{
  my $self = shift;
  $self->{strShipCountryCode};
}


#**
# * Get the value of the email address of the customer being shipped to.
# * @see #setShipEmail(JString)
# * @return the shipping email address or an empty String if the shipping customer email address was not set
# */
sub GetShipEmail
{
  my $self = shift;
  $self->{strShipEmail};
}


#**
# * Get the value of the phone number of the customer being shipped to.
# * @see #setShipPhone(JString)
# * @return the shipping phone number or an empty String if the shipping customer phone number was not set
# */
sub GetShipPhone
{
  my $self = shift;
  $self->{strShipPhone};
}


#**
# * Get the value of the fax number of the customer being shipped to.
# * @see #setShipFax(JString)
# * @return the shipping fax number or an empty JString if the shipping customer fax number was not set
# */
sub GetShipFax
{
  my $self = shift;
  $self->{strShipFax};
}


#**
# * Get the value of the shipping note.  The shipping note is an extra
# * comment to the shipping information.
# * @see #setShipNote(JString)
# * @return the shipping note or an empty String if the shipping note was not set
# */
sub GetShipNote
{
  my $self = shift;
  $self->{strShipNote};
}


#**
# * Method to get a CreditCardResponse object.
# */
sub GetTransResponseObject
{
  my $self = shift;
  my $InString = shift;
  return new Business::OnlinePayment::PPIPayMover::CreditCardResponse($InString);
}


#/**
# * Get the value of the currency.  The currency that
# * will be used for this transaction. If the merchant
# * does not have an account configured to process this currency, the
# * Transaction Server will return an error.
# * @see #setCurrency(String) 
# * @return the currency or "" if the currency was not set
# */
sub GetCurrency
{
  my $self = shift;
  $self->{strCurrency};
}


#/**
# * Gets the buyer code
# */
sub GetBuyerCode
{
  my $self = shift;
  $self->{strBuyerCode};
}

#/**
# * Gets the CAVV (for VBV transactions)
# */
sub GetCAVV
{
  my $self = shift;
  $self->{strCAVV};
}

#/**
# * Gets the Customer IP Address
# */
sub GetCustomerIPAddress
{
  my $self = shift;
  $self->{strCustomerIPAddress};
}

#/**
# * Gets the Order Customer ID
# */
sub GetOrderCustomerId
{
  my $self = shift;
  $self->{strOrderCustomerID};
}

#/**
# * Gets the purchase order number
# */
sub GetPurchaseOrderNumber
{
  my $self = shift;
  $self->{strPurchaseOrderNumber};
}

#/**
# * Gets the state tax
# */
sub GetStateTax
{
  my $self = shift;
  $self->{dStateTax};
}

#/**
# * Gets the track 1 data
# */
sub GetTrack1
{
  my $self = shift;
  $self->{strTrack1};
}

#/**
# * Gets the track 2 data
# */
sub GetTrack2
{
  my $self = shift;
  $self->{strTrack2};
}

#/**
# * Gets the transaction condition code
# */
sub GetTransactionConditionCode
{
  my $self = shift;
  $self->{strTransactionConditionCode};
}

#/**
# * Gets the xid
# */
sub GetXID
{
  my $self = shift;
  $self->{strXID};
}

#/**
# * Gets tax exempt flag
# */
sub GetTaxExempt
{
  my $self = shift;
  $self->{boolTaxExempt};
}

#/**
# * Gets invoice number
# */
sub GetInvoiceNumber
{
  my $self = shift;
  $self->{strInvoiceNumber};
}

#/**
# * Gets the Authentication Transaction ID
# * 
# * Used in Payer Authentication transaction type
# */
sub GetAuthenticationTransactionId
{
  my $self = shift;
  $self->{strAuthenticationTransactionId};
}

#/**
# * Gets the Authentication Payload
# * 
# * Used in Payer Authentication transaction type
# */
sub GetAuthenticationPayload
{
  my $self = shift;
  $self->{strAuthenticationPayload};
}

#/**
# * Gets the Success On Authentication Inconclusive
# * 
# * Used in Payer Authentication transaction type
# */
sub GetDoTransactionOnAuthenticationInconclusive
{
  my $self = shift;
  $self->{boolSuccessOnAuthenticationInconclusive};
}


#/**
# * Gets the industry
# */
sub GetIndustry
{
  my $self = shift;
  $self->{strIndustry};
}

#/**
# * Gets the folio number
# */
sub GetFolioNumber
{
  my $self = shift;
  $self->{strFolioNumber};
}

#/**
# * Gets the service rate
# */
sub GetServiceRate
{
  my $self = shift;
  $self->{dServiceRate};
}

#/**
# * Gets the service rate as a String
# */
sub GetServiceRateStr
{
  my $self = shift;
  $self->{strServiceRate};
}

#/**
# * Gets the service start year
# */
sub GetServiceStartYear
{
  my $self = shift;
  $self->{intServiceStartYear};
}

#/**
# * Gets the service start month
# */
sub GetServiceStartMonth
{
  my $self = shift;
  $self->{intServiceStartMonth};
}

#/**
# * Gets the service start day
# */
sub GetServiceStartDay
{
  my $self = shift;
  $self->{intServiceStartDay};
}

#/**
# * Gets the service end year
# */
sub GetServiceEndYear
{
  my $self = shift;
  $self->{intServiceEndYear};
}

#/**
# * Gets the service end month
# */
sub GetServiceEndMonth
{
  my $self = shift;
  $self->{intServiceEndMonth};
}

#/**
# * Gets the service end day
# */
sub GetServiceEndDay
{
  my $self = shift;
  $self->{intServiceEndDay};
}

#/**
# * Gets the Charge Total Includes Restaurant flag
# */
sub GetChargeTotalIncludesRestaurant
{
  my $self = shift;
  $self->{boolChargeTotalIncludesRestaurant};
}

#/**
# * Gets the Charge Total Includes Giftshop flag
# */
sub GetChargeTotalIncludesGiftshop
{
  my $self = shift;
  $self->{boolChargeTotalIncludesGiftshop};
}

#/**
# * Gets the Charge Total Includes Minibar flag
# */
sub GetChargeTotalIncludesMinibar
{
  my $self = shift;
  $self->{boolChargeTotalIncludesMinibar};
}

#/**
# * Gets the Charge Total Includes Laundry flag
# */
sub GetChargeTotalIncludesLaundry
{
  my $self = shift;
  $self->{boolChargeTotalIncludesLaundry};
}

#/**
# * Gets the Charge Total Includes Phone flag
# */
sub GetChargeTotalIncludesPhone
{
  my $self = shift;
  $self->{boolChargeTotalIncludesPhone};
}

#/**
# * Gets the Charge Total Includes Other flag
# */
sub GetChargeTotalIncludesOther
{
  my $self = shift;
  $self->{boolChargeTotalIncludesOther};
}

#/**
# * Gets the Service No Show flag
# */
sub GetServiceNoShow
{
  my $self = shift;
  $self->{boolServiceNoShow};
}



#**
# * Method to create the post string.
# */
sub WriteRequest
{
  my $self = shift;
  my $class =ref($self);
  my $PostString = shift; # a pointer to string as arguement
  my $temp = "";
  $self->SUPER::WriteRequest($PostString);
  
#        Cartridge Type
  $temp = Encode( $self->{strCartridgeType} );
  $$PostString .= "cartridge_type=$temp";
  $$PostString .= $self->{strParamSeparator};

#        Ecommerce Indicator
  $temp = Encode( $self->{strEcommerceIndicator} );
  $$PostString .= "ecommerce_indicator=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#	 fixed value for transaction_type
  $$PostString .= "transaction_type=CREDIT_CARD";
  $$PostString .= $self->{strParamSeparator};
  
#	 creditCardNumber
  $temp = Encode( $self->{strCreditCardNumber} );
  $$PostString .= "credit_card_number=$temp";
  $$PostString .= $self->{strParamSeparator};

#	 creditCardVerificationNumber
  $temp = Encode( $self->{strCreditCardVerificationNumber} );
  $$PostString .= "credit_card_verification_number=$temp";
  $$PostString .= $self->{strParamSeparator};
  
# expireMonth
  $temp = Encode( $self->{strExpireMonth} );
  $$PostString .= "expire_month=$temp";
  $$PostString .= $self->{strParamSeparator};
  
# expireYear
  $temp = Encode( $self->{strExpireYear} );
  $$PostString .= "expire_year=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#  chargeType
  $temp = Encode( $self->{strChargeType} );
  $$PostString .= "charge_type=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   chargeTotal
  $$PostString .= "charge_total=";
  $$PostString .= Encode( $self->{dChargeTotal} );
  $$PostString .= $self->{strParamSeparator};
  
#   cardBrand
#  $$PostString .= "card_brand=";
#  $$PostString .= Encode( $self->{strCardBrand} );
#  $$PostString .= $self->{strParamSeparator};
  
#   orderId
  $temp = Encode( $self->{strOrderId} );
  $$PostString .= "order_id=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#    captureReferenceId
  $temp = Encode( $self->{strReferenceId} );
  $$PostString .= "reference_id=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   orderDescription
  $temp = Encode( $self->{strOrderDescription} );
  $$PostString .= "order_description=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#    orderUserId
  $temp = Encode( $self->{strOrderUserId} );
  $$PostString .= "order_user_id=$temp";
  $$PostString .= $self->{strParamSeparator};

#    BankApprovalCode
  $temp = Encode( $self->{strBankApprovalCode} );
  $$PostString .= "bank_approval_code=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#    DuplicateCheck
  $temp = Encode( $self->{strDuplicateCheck} );
  $$PostString .= "duplicate_check=$temp";
  $$PostString .= $self->{strParamSeparator};

#   taxAmount
  $$PostString .= "tax_amount=";
  $$PostString .= Encode( $self->{dTaxAmount} );
  $$PostString .= $self->{strParamSeparator};
  
#   shippingCharge
  $$PostString .= "shipping_charge=";
  $$PostString .= Encode( $self->{dShippingCharge} );
  $$PostString .= $self->{strParamSeparator};
  
#   billFirstName
  $temp = Encode( $self->{strBillFirstName} );
  $$PostString .= "bill_first_name=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   billMiddleName
  $temp = Encode( $self->{strBillMiddleName} );
  $$PostString .= "bill_middle_name=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   billLastName
  $temp = Encode( $self->{strBillLastName} );
  $$PostString .= "bill_last_name=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   billCustomerTitle
  $temp = Encode( $self->{strBillCustomerTitle} );
  $$PostString .= "bill_customer_title=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   billCompany
  $temp = Encode( $self->{strBillCompany} );
  $$PostString .= "bill_company=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   billAddressOne
  $temp = Encode( $self->{strBillAddressOne} );
  $$PostString .= "bill_address_one=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   billAddressTwo
  $temp = Encode( $self->{strBillAddressTwo} );
  $$PostString .= "bill_address_two=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   billCity
  $temp = Encode( $self->{strBillCity} );
  $$PostString .= "bill_city=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   billStateOrProvince
  $temp = Encode( $self->{strBillStateOrProvince} );
  $$PostString .= "bill_state_or_province=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#    billPostalCode
  $temp = Encode( $self->{strBillPostalCode} );
  $$PostString .= "bill_postal_code=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   billCountryCode
  $temp = Encode( $self->{strBillCountryCode} );
  $$PostString .= "bill_country_code=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   billEmail
  $temp = Encode( $self->{strBillEmail} );
  $$PostString .= "bill_email=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   billPhone
  $temp = Encode( $self->{strBillPhone} );
  $$PostString .= "bill_phone=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   billFax
  $temp = Encode( $self->{strBillFax} );
  $$PostString .= "bill_fax=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   billNote
  $temp = Encode( $self->{strBillNote} );
  $$PostString .= "bill_note=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   shipFirstName
  $temp = Encode( $self->{strShipFirstName} );
  $$PostString .= "ship_first_name=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   shipMiddleName
  $temp = Encode( $self->{strShipMiddleName} );
  $$PostString .= "ship_middle_name=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   shipLastName
  $temp = Encode( $self->{strShipLastName} );
  $$PostString .= "ship_last_name=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   shipCustomerTitle
  $temp = Encode( $self->{strShipCustomerTitle} );
  $$PostString .= "ship_customer_title=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#  shipCompany
  $temp = Encode( $self->{strShipCompany} );
  $$PostString .= "ship_company=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   shipAddressOne
  $temp = Encode( $self->{strShipAddressOne} );
  $$PostString .= "ship_address_one=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   shipAddressTwo
  $temp = Encode( $self->{strShipAddressTwo} );
  $$PostString .= "ship_address_two=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   shipCity
  $temp = Encode( $self->{strShipCity} );
  $$PostString .= "ship_city=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   shipStateOrProvince
  $temp = Encode( $self->{strShipStateOrProvince} );
  $$PostString .= "ship_state_or_province=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#  shipPostalCode
  $temp = Encode( $self->{strShipPostalCode} );
  $$PostString .= "ship_postal_code=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   shipCountryCode
  $temp = Encode( $self->{strShipCountryCode} );
  $$PostString .= "ship_country_code=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   shipEmail
  $temp = Encode( $self->{strShipEmail} );
  $$PostString .= "ship_email=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   shipPhone
  $temp = Encode( $self->{strShipPhone} );
  $$PostString .= "ship_phone=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   shipFax
  $temp = Encode( $self->{strShipFax} );
  $$PostString .= "ship_fax=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   shipNote
  $temp = Encode( $self->{strShipNote} );
  $$PostString .= "ship_note=$temp";
  $$PostString .= $self->{strParamSeparator};
 
#   Currency 
#  $temp = Encode( $self->{strCurrency} );
#  $$PostString .= "currency=$temp";
#  $$PostString .= $self->{strParamSeparator};

#   Buyer Code
  $temp = Encode( $self->{strBuyerCode} );
  $$PostString .= "buyer_code=$temp";
  $$PostString .= $self->{strParamSeparator};

#   CAVV
  $temp = Encode( $self->{strCAVV} );
  $$PostString .= "cavv=$temp";
  $$PostString .= $self->{strParamSeparator};

#   Customer IP Address
  $temp = Encode( $self->{strCustomerIPAddress} );
  $$PostString .= "customer_ip_address=$temp";
  $$PostString .= $self->{strParamSeparator};

#   Order Customer ID
  $temp = Encode( $self->{strOrderCustomerID} );
  $$PostString .= "order_customer_id=$temp";
  $$PostString .= $self->{strParamSeparator};

#   Purchase Order Number
  $temp = Encode( $self->{strPurchaseOrderNumber} );
  $$PostString .= "purchase_order_number=$temp";
  $$PostString .= $self->{strParamSeparator};

#   State Tax
  $temp = Encode( $self->{dStateTax} );
  if( $temp == -1 ) {
    $temp = "";
  }
  $$PostString .= "state_tax=$temp";
  $$PostString .= $self->{strParamSeparator};

#   Track 1
  $temp = Encode( $self->{strTrack1} );
  $$PostString .= "track1=$temp";
  $$PostString .= $self->{strParamSeparator};

#   Track 2
  $temp = Encode( $self->{strTrack2} );
  $$PostString .= "track2=$temp";
  $$PostString .= $self->{strParamSeparator};

#   Transaction condition code
  $temp = Encode( $self->{strTransactionConditionCode} );
  $$PostString .= "transaction_condition_code=$temp";
  $$PostString .= $self->{strParamSeparator};

#   XID
  $temp = Encode( $self->{strXID} );
  $$PostString .= "x_id=$temp";
  $$PostString .= $self->{strParamSeparator};
  
#   Invoice number
  $temp = Encode( $self->{strInvoiceNumber} );
  $$PostString .= "invoice_number=$temp";
  $$PostString .= $self->{strParamSeparator};  

#   Tax Exempt
  $temp = $self->{boolTaxExempt};
  if ( $temp eq "" ) {
    #not set.  leave it.
  } elsif ( $temp ) {
    $temp = "true";
  } elsif(! $temp) {
    $temp = "false";
  } else {
    $temp = "";
  }
  $$PostString .= "tax_exempt=$temp";
  $$PostString .= $self->{strParamSeparator}; 
  
#   Authentication Transaction ID
  $temp = Encode( $self->{strAuthenticationTransactionId} );
  $$PostString .= "authentication_transaction_id=$temp";
  $$PostString .= $self->{strParamSeparator};

#   Authentication Payload
  $temp = Encode( $self->{strAuthenticationPayload} );
  $$PostString .= "authentication_payload=$temp";
  $$PostString .= $self->{strParamSeparator};  

#   Success On Authentication Inconclusive
  $temp = $self->{boolSuccessOnAuthenticationInconclusive};
  if ( $temp eq "" ) {
    #not set.  leave it.
  } elsif ( $temp ) {
    $temp = "true";
  } elsif(!$temp) {
    $temp = "false";
  } else {
    $temp = "";
  }
  $$PostString .= "success_on_authentication_inconclusive=$temp";
  $$PostString .= $self->{strParamSeparator};  
  
#   Industry
  $temp = Encode( $self->{strIndustry} );
  $$PostString .= "industry=$temp";
  $$PostString .= $self->{strParamSeparator};  
  
#   Folio number
  $temp = Encode( $self->{strFolioNumber} );
  $$PostString .= "folio_number=$temp";
  $$PostString .= $self->{strParamSeparator};  
  
#   Service Rate
  $temp = Encode( $self->{dServiceRate} );
  if( $temp == -1 ) {
    $temp = "";
  }
  $$PostString .= "service_rate=$temp";
  $$PostString .= $self->{strParamSeparator};
  
# Service Start Day
  $temp = Encode( $self->{intServiceStartDay} );
  $$PostString .= "service_start_day=$temp";
  $$PostString .= $self->{strParamSeparator};  
  
# Service Start Month
  $temp = Encode( $self->{intServiceStartMonth} );
  $$PostString .= "service_start_month=$temp";
  $$PostString .= $self->{strParamSeparator};  
  
# Service Start Year
  $temp = Encode( $self->{intServiceStartYear} );
  $$PostString .= "service_start_year=$temp";
  $$PostString .= $self->{strParamSeparator};  
  
# Service End Day
  $temp = Encode( $self->{intServiceEndDay} );
  $$PostString .= "service_end_day=$temp";
  $$PostString .= $self->{strParamSeparator};  
  
# Service End Month
  $temp = Encode( $self->{intServiceEndMonth} );
  $$PostString .= "service_end_month=$temp";
  $$PostString .= $self->{strParamSeparator};  
  
# Service End Year
  $temp = Encode( $self->{intServiceEndYear} );
  $$PostString .= "service_end_year=$temp";
  $$PostString .= $self->{strParamSeparator};  
  
# Charge Total Includes Restaurant
  $temp = Encode( $self->{boolChargeTotalIncludesRestaurant} );
    if ( $temp eq "" ) {
      #not set.  leave it.
    } elsif ( $temp ) {
      $temp = "true";
    } elsif(!$temp) {
      $temp = "false";
    } else {
      $temp = "";
  }
  $$PostString .= "charge_total_incl_restaurant=$temp";
  $$PostString .= $self->{strParamSeparator};  
  
# Charge Total Includes Giftshop
  $temp = Encode( $self->{boolChargeTotalIncludesGiftshop} );
    if ( $temp eq "" ) {
      #not set.  leave it.
    } elsif ( $temp ) {
      $temp = "true";
    } elsif(!$temp) {
      $temp = "false";
    } else {
      $temp = "";
  }
  $$PostString .= "charge_total_incl_giftshop=$temp";
  $$PostString .= $self->{strParamSeparator}; 
  
# Charge Total Includes Minibar
  $temp = Encode( $self->{boolChargeTotalIncludesMinibar} );
    if ( $temp eq "" ) {
      #not set.  leave it.
    } elsif ( $temp ) {
      $temp = "true";
    } elsif(!$temp) {
      $temp = "false";
    } else {
      $temp = "";
  }
  $$PostString .= "charge_total_incl_minibar=$temp";
  $$PostString .= $self->{strParamSeparator}; 
  
# Charge Total Includes Phone
  $temp = Encode( $self->{boolChargeTotalIncludesPhone} );
    if ( $temp eq "" ) {
      #not set.  leave it.
    } elsif ( $temp ) {
      $temp = "true";
    } elsif(!$temp) {
      $temp = "false";
    } else {
      $temp = "";
  }
  $$PostString .= "charge_total_incl_phone=$temp";
  $$PostString .= $self->{strParamSeparator}; 

# Charge Total Includes Laundry
  $temp = Encode( $self->{boolChargeTotalIncludesLaundry} );
    if ( $temp eq "" ) {
      #not set.  leave it.
    } elsif ( $temp ) {
      $temp = "true";
    } elsif(!$temp) {
      $temp = "false";
    } else {
      $temp = "";
  }
  $$PostString .= "charge_total_incl_laundry=$temp";
  $$PostString .= $self->{strParamSeparator}; 
  
# Charge Total Includes Other
  $temp = Encode( $self->{boolChargeTotalIncludesOther} );
    if ( $temp eq "" ) {
      #not set.  leave it.
    } elsif ( $temp ) {
      $temp = "true";
    } elsif(!$temp) {
      $temp = "false";
    } else {
      $temp = "";
  }
  $$PostString .= "charge_total_incl_other=$temp";
  $$PostString .= $self->{strParamSeparator}; 
  
# Service No Show
  $temp = Encode( $self->{boolServiceNoShow} );
    if ( $temp eq "" ) {
      #not set.  leave it.
    } elsif ( $temp ) {
      $temp = "true";
    } elsif(!$temp) {
      $temp = "false";
    } else {
      $temp = "";
  }
  $$PostString .= "service_no_show=$temp";
  
# No parameter separator on last line.

}

sub GetErrorString
{
  my $self = shift;
  return $self->{strError};
}


