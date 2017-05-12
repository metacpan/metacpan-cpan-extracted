package Business::OnlinePayment::PPIPayMover::constants;

use strict;
use vars qw(@ISA @EXPORT);
use Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(VERSION
  PAY_HOST
  PAY_HOST_PATH
  PAY_HOST_PORT
  SUCCESSFUL_TRANSACTION
  MISSING_REQUIRED_REQUEST_FIELD
  INVALID_REQUEST_FIELD
  ILLEGAL_TRANSACTION_REQUEST
  TRANSACTION_SERVER_ERROR
  TRANSACTION_NOT_POSSIBLE
  INVALID_VERSION
  CREDIT_CARD_DECLINED
  ACQUIRER_GATEWAY_ERROR
  PAYMENT_ENGINE_ERROR
  SALE
  AUTH
  FORCE_SALE
  FORCE_AUTH
  ADJUSTMENT
  QUERY_PAYMENT
  QUERY_CREDIT
  CAPTURE
  VOID
  CREDIT
  CREATE_ORDER
  CLOSE_ORDER
  CANCEL_ORDER
  VOID_AUTH
  VOID_CAPTURE
  VOID_CREDIT
  SETTLE_ACTION
  PURGE_ACTION
  TOTALS_ACTION
  VISA
  MASTERCARD
  AMERICAN_EXPRESS
  DISCOVER
  NOVA
  AMEX
  DINERS
  EUROCARD
  CARD_BRAND_1
  CARD_BRAND_2
  CARD_BRAND_3
  CARD_BRAND_4
  CARD_BRAND_5
  CARD_BRAND_6
  TR_ERROR
  TR_NO_ERROR
  CCR_ERROR
  CCR_NO_ERROR
  BR_ERROR
  BR_NO_ERROR
  ISR_ERROR
  ISR_NO_ERROR
  ECLIENT_ERROR
  ECLIENT_NO_ERROR
  HTTP_POST_RESULT_NOTIFICATION_STRING
  EMAIL_RESULT_NOTIFICATION_STRING
  NO_RESULT_NOTIFICATION_STRING
  EMAIL_RESULT_NOTIFICATION
  HTTP_POST_RESULT_NOTIFICATION
  NO_RESULT_NOTIFICATION
  TCC_DEFAULT
  TCC_CARDHOLDER_NOT_PRESENT_MAIL_FAX_ORDER
  TCC_CARDHOLDER_NOT_PRESENT_TELEPHONE_ORDER
  TCC_CARDHOLDER_NOT_PRESENT_INSTALLMENT
  TCC_CARDHOLDER_NOT_PRESENT_PAYER_AUTHENTICATION
  TCC_CARDHOLDER_NOT_PRESENT_SECURE_ECOMMERCE
  TCC_CARDHOLDER_NOT_PRESENT_RECURRING_BILLING
  TCC_CARDHOLDER_PRESENT_RETAIL_ORDER 
  TCC_CARDHOLDER_PRESENT_RETAIL_ORDER_WITHOUT_SIGNATURE
  TCC_CARDHOLDER_PRESENT_RETAIL_ORDER_KEYED
  TCC_CARDHOLDER_NOT_PRESENT_PAYER_AUTHENTICATION_ATTEMPTED
  PERIOD_WEEKLY
  PERIOD_BIWEEKLY
  PERIOD_SEMIMONTHLY
  PERIOD_MONTHLY
  PERIOD_QUARTERLY
  PERIOD_ANNUAL
  COMMAND_ADD_CUSTOMER_ACCOUNT_ONLY
  COMMAND_ADD_RECURRENCE_ONLY
  COMMAND_ADD_CUSTOMER_ACCOUNT_AND_RECURRENCE
  ACCOUNT_TYPE_CREDIT_CARD
  STATUS_ENROLLED
  STATUS_NOT_ENROLLED
  STATUS_ENROLLED_BUT_AUTHENTICATION_UNAVAILABLE
  AUTHENTICATION_PREFIX
  CHECKING
  SAVINGS
  PERSONAL
  CORPORATE
  DIRECT_MARKETING
  RETAIL
  LODGING
  RESTAURANT  
  CHECK
  OVERRIDE
  NO_CHECK
);

sub VERSION { "Perl Plug v1.8.0" }

#**
# * Payment Host Information
#

sub PAY_HOST { "etrans.paygateway.com" }
sub PAY_HOST_PATH { "/TransactionManager" }
sub PAY_HOST_PORT { 443 }


#**
# * Response code indicating the transaction was successfully processed.
#
sub SUCCESSFUL_TRANSACTION { 1 }

#**
# * Response code indicating that a required request field was not provided
# * with the request.  The required field will be identifed in the response
# * code text returned from getResponseCodeText().  The field identified will
# * be defined by a subclass of TransactionRequest.
#
sub MISSING_REQUIRED_REQUEST_FIELD { 2 }

#*
# * Response code indicating that the value provided to a subclass of
# * TrasactionRequest for a transaction field was not valid.  The resonse
# * code text returned from getResponseCodeText() will identify the
# * problem and the field.
# *
sub INVALID_REQUEST_FIELD { 3 }

#*
# * Response code indicating the transaction request was illegal.  This
# * can happen if a transaction is sent for an account that does not
# * exist or if the account has not been configured to perform the
# * requested transaction type.
#
sub ILLEGAL_TRANSACTION_REQUEST { 4 }

#*
# * Response code indicating that an error occured within the transaction
# * server.  The transaction server is where this Java Transaction Client API
# * connects and sends transaction data for further processing.  This type
# * of error is temporary.  If one occurs maintenance staff are immediately
# * signaled to correct the problem.
#
sub TRANSACTION_SERVER_ERROR { 5 }

#**
# * Response code indicating that the requested transaction is not possible.
# * This can happen if the transaction request refers to a previous transaction
# * that does not exist.  For example, when using the CreditCardRequest and
# * CreditCardResponse classes one possible request is to perform a capture of
# * funds previously authorized from a customers credit card.  If a capture
# * request is sent that refers to an authorization that does not exist then
# * this response code will be returned.
#
sub TRANSACTION_NOT_POSSIBLE  { 6 }

#**
# * Response code indicating that the version of the Java Transaction Client API
#* being used is no longer valid.
#
sub INVALID_VERSION { 7 }

#**
# * Response code indicating that the credit card transaction was declined.
# *
sub CREDIT_CARD_DECLINED { 100 }

#**
# * Response code indicating that the Acquirer Gateway encountered an
# * error.  This is a software program that handles credit card transactions.
# * It accepts connections over the internet and communicates with the
# * private banking network.
# *
sub ACQUIRER_GATEWAY_ERROR { 101 }

#**
# * Response code indicating that the Payment Engine encountered an
# * error.  This is a software program that makes connections to an
# * Aquirer Gateway.
#
sub PAYMENT_ENGINE_ERROR { 102 }

#/////////////////////////////////////////////////////////////////////////////////////////////////////
#// Constants that are permissible values for chargeBrand.
#

#**
# * One of ten permissible values of the parameter of the setChargeType() method.
# * May also be used as the chargeType parameter in the CreditCardRequest constructor.
# * Indicates that the type of operation being done is a sale
# * (both an authorization and a capture).
# * <p>
# * Other permissible values for setChargeType() are ADJUSTMENT, AUTH, CAPTURE, CREDIT, FORCE_AUTH, FORCE_SALE, QUERY_CREDIT, QUERY_PAYMENT or VOID.
# * <p>
# * @see com.paygateway.CreditCardRequest#getChargeType
# * @see com.paygateway.CreditCardRequest#setChargeType
# */
sub SALE { "SALE" }

#**
# * Additional Charge Type
# * <p>
# * See above for other permissible values for setChargeType().
# * <p>
# * @see com.paygateway.CreditCardRequest#getChargeType
# * @see com.paygateway.CreditCardRequest#setChargeType
# *
sub AUTH { "AUTH" }

#**
# * Additional Charge Type
# * <p>
# * See above for other permissible values for setChargeType().
# * <p>
# * @see com.paygateway.CreditCardRequest#getChargeType
# * @see com.paygateway.CreditCardRequest#setChargeType
# *
sub CAPTURE { "CAPTURE" }

#**
# * Additional Charge Type
# * <p>
# * See above for other permissible values for setChargeType().
# * <p>
# * @see com.paygateway.CreditCardRequest#getChargeType
# * @see com.paygateway.CreditCardRequest#setChargeType
# *
sub VOID { "VOID" }

#**
# * Additional Charge Type
# * <p>
# * See above for other permissible values for setChargeType().
# * <p>
# * @see com.paygateway.CreditCardRequest#getChargeType
# * @see com.paygateway.CreditCardRequest#setChargeType
# *
sub CREDIT { "CREDIT" }

#**
# * Additional Charge Type
# * <p>
# * See above for other permissible values for setChargeType().
# * <p>
# * @see com.paygateway.CreditCardRequest#getChargeType
# * @see com.paygateway.CreditCardRequest#setChargeType
# *
sub FORCE_AUTH { "FORCE_AUTH" }

#**
# * Additional Charge Type
# * <p>
# * See above for other permissible values for setChargeType().
# * <p>
# * @see com.paygateway.CreditCardRequest#getChargeType
# * @see com.paygateway.CreditCardRequest#setChargeType
# *
sub FORCE_SALE { "FORCE_SALE" }

#**
# * Additional Charge Type
# * <p>
# * See above for other permissible values for setChargeType().
# * <p>
# * @see com.paygateway.CreditCardRequest#getChargeType
# * @see com.paygateway.CreditCardRequest#setChargeType
# *
sub QUERY_PAYMENT { "QUERY_PAYMENT" }

#**
# * Additional Charge Type
# * <p>
# * See above for other permissible values for setChargeType().
# * <p>
# * @see com.paygateway.CreditCardRequest#getChargeType
# * @see com.paygateway.CreditCardRequest#setChargeType
# *
sub QUERY_CREDIT { "QUERY_CREDIT" }

#**
# * Additional Charge Type
# * <p>
# * See above for other permissible values for setChargeType().
# * <p>
# * @see com.paygateway.CreditCardRequest#getChargeType
# * @see com.paygateway.CreditCardRequest#setChargeType
# *
sub ADJUSTMENT { "ADJUSTMENT" }





# new charge types for BatchRequest
# added in v1.6
sub SETTLE_ACTION { "SETTLE" }
sub PURGE_ACTION { "PURGE" }
sub TOTALS_ACTION { "TOTALS" }

# new charge types for ibm pm
# added in v1.6
sub CLOSE_ORDER { "CLOSE_ORDER" }
sub CANCEL_ORDER { "CANCEL_ORDER" }
sub CREATE_ORDER { "CREATE_ORDER" }
sub VOID_AUTH { "VOID_AUTH" }
sub VOID_CAPTURE { "VOID_CAPTURE" }
sub VOID_CREDIT { "VOID_CREDIT" }

#/////////////////////////////////////////////////////////////////////////////////////////////////////
#// Permissible values for cardBrand.

#
# * One permissible value for the parameter of the setCardBrand() method.
# * May also be used as the cardBrand parameter in the CreditCardRequest constructor.
# <p>
# Other permissible values are
# MASTERCARD, AMERICAN_EXPRESS, DISCOVER, NOVA, AMEX, DINERS, or EUROCARD,
# as well as generic values (to support future card types)
# CARD_BRAND_1, CARD_BRAND_2, CARD_BRAND_3, CARD_BRAND_4, CARD_BRAND_5, or CARD_BRAND_6.
# <p>
# @see com.paygateway.CreditCardRequest#getCardBrand
# @see com.paygateway.CreditCardRequest#setCardBrand
#*/
sub VISA {  "VISA" }

#**
# * One permissible value for the parameter of the setCardBrand() method.
# * May also be used as the cardBrand parameter in the CreditCardRequest constructor.
# <p>
# Other permissible values are
# VISA, AMERICAN_EXPRESS, DISCOVER, NOVA, AMEX, DINERS, or EUROCARD,
# as well as generic values (to support future card types)
# CARD_BRAND_1, CARD_BRAND_2, CARD_BRAND_3, CARD_BRAND_4, CARD_BRAND_5, or CARD_BRAND_6.
# <p>
# @see com.paygateway.CreditCardRequest#getCardBrand
# @see com.paygateway.CreditCardRequest#setCardBrand
#
sub MASTERCARD  { "MASTERCARD" }

#**
# * One permissible value for the parameter of the setCardBrand() method.
# * May also be used as the cardBrand parameter in the CreditCardRequest constructor.
# * <p>
# * Other permissible values are
# * VISA, MASTERCARD, DISCOVER, NOVA, AMEX, DINERS, or EUROCARD,
# * as well as generic values (to support future card types)
# * CARD_BRAND_1, CARD_BRAND_2, CARD_BRAND_3, CARD_BRAND_4, CARD_BRAND_5, or CARD_BRAND_6.
# * <p>
# * @see com.paygateway.CreditCardRequest#getCardBrand
# * @see com.paygateway.CreditCardRequest#setCardBrand
# */
sub AMERICAN_EXPRESS { "AMERICAN_EXPRESS" }

#/**
# * One permissible value for the parameter of the setCardBrand() method.
# * May also be used as the cardBrand parameter in the CreditCardRequest constructor.
# * <p>
# * Other permissible values are
# * VISA, MASTERCARD, AMERICAN_EXPRESS, NOVA, AMEX, DINERS, or EUROCARD,
# * as well as generic values (to support future card types)
# * CARD_BRAND_1, CARD_BRAND_2, CARD_BRAND_3, CARD_BRAND_4, CARD_BRAND_5, or CARD_BRAND_6.
# * <p>
# * @see com.paygateway.CreditCardRequest#getCardBrand
# * @see com.paygateway.CreditCardRequest#setCardBrand
# */
sub DISCOVER  { "DISCOVER" }

#**
# * One permissible value for the parameter of the setCardBrand() method.
# * May also be used as the cardBrand parameter in the CreditCardRequest constructor.
# * <p>
# * Other permissible values are
# * VISA, MASTERCARD, AMERICAN_EXPRESS, DISCOVER, AMEX, DINERS, or EUROCARD,
# * as well as generic values (to support future card types)
# * CARD_BRAND_1, CARD_BRAND_2, CARD_BRAND_3, CARD_BRAND_4, CARD_BRAND_5, or CARD_BRAND_6.
# * <p>
# * @see com.paygateway.CreditCardRequest#getCardBrand
# * @see com.paygateway.CreditCardRequest#setCardBrand
# */
sub NOVA { "NOVA" }

#**
# * One permissible value for the parameter of the setCardBrand() method.
# * May also be used as the cardBrand parameter in the CreditCardRequest constructor.
# * <p>
# * Other permissible values are
# * VISA, MASTERCARD, AMERICAN_EXPRESS, DISCOVER, NOVA, DINERS, or EUROCARD,
# * as well as generic values (to support future card types)
# * CARD_BRAND_1, CARD_BRAND_2, CARD_BRAND_3, CARD_BRAND_4, CARD_BRAND_5, or CARD_BRAND_6.
# * <p>
# * @see com.paygateway.CreditCardRequest#getCardBrand
# * @see com.paygateway.CreditCardRequest#setCardBrand
# */
sub AMEX { "AMEX" }

#*
# * One permissible value for the parameter of the setCardBrand() method.
# * May also be used as the cardBrand parameter in the CreditCardRequest constructor.
# * <p>
# * Other permissible values are
# * VISA, MASTERCARD, AMERICAN_EXPRESS, DISCOVER, NOVA, AMEX, or EUROCARD,
# * as well as generic values (to support future card types)
# * CARD_BRAND_1, CARD_BRAND_2, CARD_BRAND_3, CARD_BRAND_4, CARD_BRAND_5, or CARD_BRAND_6.
# * <p>
# * @see com.paygateway.CreditCardRequest#getCardBrand
# * @see com.paygateway.CreditCardRequest#setCardBrand
# */
sub DINERS {  "DINERS" }

#*
# * One permissible value for the parameter of the setCardBrand() method.
# * May also be used as the cardBrand parameter in the CreditCardRequest constructor.
# * <p>
# * Other permissible values are
# * VISA, MASTERCARD, AMERICAN_EXPRESS, DISCOVER, NOVA, AMEX, or DINERS,
# * as well as generic values (to support future card types)
# * CARD_BRAND_1, CARD_BRAND_2, CARD_BRAND_3, CARD_BRAND_4, CARD_BRAND_5, or CARD_BRAND_6.
# * <p>
# * @see com.paygateway.CreditCardRequest#getCardBrand
# * @see com.paygateway.CreditCardRequest#setCardBrand
# */
sub EUROCARD  { "EUROCARD" }

#**
# * One permissible value for the parameter of the setCardBrand() method.
# * May also be used as the cardBrand parameter in the CreditCardRequest constructor.
# * <p>
# * Other permissible values are
# * VISA, MASTERCARD, AMERICAN_EXPRESS, DISCOVER, NOVA, AMEX, DINERS, or EUROCARD,
# * as well as generic values (to support future card types)
# * CARD_BRAND_2, CARD_BRAND_3, CARD_BRAND_4, CARD_BRAND_5, or CARD_BRAND_6.
# * <p>
# * @see com.paygateway.CreditCardRequest#getCardBrand
# * @see com.paygateway.CreditCardRequest#setCardBrand
# */
sub CARD_BRAND_1 { "CARD_BRAND_1" }


#**
# * One permissible value for the parameter of the setCardBrand() method.
# * May also be used as the cardBrand parameter in the CreditCardRequest constructor.
# * <p>
# * Other permissible values are
# * VISA, MASTERCARD, AMERICAN_EXPRESS, DISCOVER, NOVA, AMEX, DINERS, or EUROCARD,
# * as well as generic values (to support future card types)
# * CARD_BRAND_1, CARD_BRAND_3, CARD_BRAND_4, CARD_BRAND_5, or CARD_BRAND_6.
# * <p>
# * @see com.paygateway.CreditCardRequest#getCardBrand
# * @see com.paygateway.CreditCardRequest#setCardBrand
# */
sub CARD_BRAND_2  { "CARD_BRAND_2" }

#**
# * One permissible value for the parameter of the setCardBrand() method.
# * May also be used as the cardBrand parameter in the CreditCardRequest constructor.
# * <p>
# * Other permissible values are
# * VISA, MASTERCARD, AMERICAN_EXPRESS, DISCOVER, NOVA, AMEX, DINERS, or EUROCARD,
# * as well as generic values (to support future card types)
# * CARD_BRAND_1, CARD_BRAND_2, CARD_BRAND_4, CARD_BRAND_5, or CARD_BRAND_6.
# * <p>
# * @see com.paygateway.CreditCardRequest#getCardBrand
# * @see com.paygateway.CreditCardRequest#setCardBrand
# */
sub CARD_BRAND_3  { "CARD_BRAND_3" }

#**
# * One permissible value for the parameter of the setCardBrand() method.
# * May also be used as the cardBrand parameter in the CreditCardRequest constructor.
# * <p>
# * Other permissible values are
# * VISA, MASTERCARD, AMERICAN_EXPRESS, DISCOVER, NOVA, AMEX, DINERS, or EUROCARD,
# * as well as generic values (to support future card types)
# * CARD_BRAND_1, CARD_BRAND_2, CARD_BRAND_3, CARD_BRAND_5, or CARD_BRAND_6.
# * <p>
# * @see com.paygateway.CreditCardRequest#getCardBrand
# * @see com.paygateway.CreditCardRequest#setCardBrand
# */
sub CARD_BRAND_4 {  "CARD_BRAND_4" }

#**
# * One permissible value for the parameter of the setCardBrand() method.
# * May also be used as the cardBrand parameter in the CreditCardRequest constructor.
# * <p>
# * Other permissible values are
# * VISA, MASTERCARD, AMERICAN_EXPRESS, DISCOVER, NOVA, AMEX, DINERS, or EUROCARD,
# * as well as generic values (to support future card types)
# * CARD_BRAND_1, CARD_BRAND_2, CARD_BRAND_3, CARD_BRAND_4, or CARD_BRAND_6.
# * <p>
# * @see com.paygateway.CreditCardRequest#getCardBrand
# * @see com.paygateway.CreditCardRequest#setCardBrand
# */
sub CARD_BRAND_5 {  "CARD_BRAND_5" }

#**
# * One permissible value for the parameter of the setCardBrand() method.
# * May also be used as the cardBrand parameter in the CreditCardRequest constructor.
# * <p>
# * Other permissible values are
# * VISA, MASTERCARD, AMERICAN_EXPRESS, DISCOVER, NOVA, AMEX, DINERS, or EUROCARD,
# * as well as generic values (to support future card types)
# * CARD_BRAND_1, CARD_BRAND_2, CARD_BRAND_3, CARD_BRAND_4, or CARD_BRAND_5.
# * <p>
# * @see com.paygateway.CreditCardRequest#getCardBrand
# * @see com.paygateway.CreditCardRequest#setCardBrand
# */
sub CARD_BRAND_6 {  "CARD_BRAND_6" }

# Transaction Condition code values (CreditCardRequest)
sub TCC_DEFAULT 						{ 0 }
sub TCC_CARDHOLDER_NOT_PRESENT_MAIL_FAX_ORDER 			{ 1 }
sub TCC_CARDHOLDER_NOT_PRESENT_TELEPHONE_ORDER 			{ 2 }
sub TCC_CARDHOLDER_NOT_PRESENT_INSTALLMENT 			{ 3 }
sub TCC_CARDHOLDER_NOT_PRESENT_PAYER_AUTHENTICATION 		{ 4 }
sub TCC_CARDHOLDER_NOT_PRESENT_SECURE_ECOMMERCE  		{ 5 }
sub TCC_CARDHOLDER_NOT_PRESENT_RECURRING_BILLING 		{ 6 }
sub TCC_CARDHOLDER_PRESENT_RETAIL_ORDER 			{ 7 }
sub TCC_CARDHOLDER_PRESENT_RETAIL_ORDER_WITHOUT_SIGNATURE 	{ 8 }
sub TCC_CARDHOLDER_PRESENT_RETAIL_ORDER_KEYED			{ 9 }
sub TCC_CARDHOLDER_NOT_PRESENT_PAYER_AUTHENTICATION_ATTEMPTED	{ 10 }

################################
# Special Credit Card constants
#
# Duplicate Check
#no, conflicts with perl# sub CHECK { "CHECK" }
sub OVERRIDE { "OVERRIDE" }
sub NO_CHECK { "NO_CHECK" }


################################
# Recurring billing constants
#
# Period
sub PERIOD_WEEKLY	{ 1 }
sub PERIOD_BIWEEKLY	{ 2 }
sub PERIOD_SEMIMONTHLY	{ 3 }
sub PERIOD_MONTHLY	{ 4 }
sub PERIOD_QUARTERLY	{ 5 }
sub PERIOD_ANNUAL	{ 6 }

# Command
sub COMMAND_ADD_CUSTOMER_ACCOUNT_ONLY { "ADD_RECURRENCE" }
sub COMMAND_ADD_RECURRENCE_ONLY { "ADD_RECURRENCE" }
sub COMMAND_ADD_CUSTOMER_ACCOUNT_AND_RECURRENCE { "ADD_CUSTOMER_AND_RECURRENCE" }

# Account Type
sub ACCOUNT_TYPE_CREDIT_CARD { "CREDIT_CARD" }

# TransactionResponse error definitions
sub TR_ERROR { 0 }
sub TR_NO_ERROR  { 1 }

# CreditCardResponse error definitions
sub CCR_ERROR {  0 }
sub CCR_NO_ERROR {  1 }

# BatchResponse error definitions
sub BR_ERROR { 0 }
sub BR_NO_ERROR { 1 }

#InitSETResponse error definitions
sub ISR_ERROR {  0 }
sub ISR_NO_ERROR  { 1 }

# EClient error definitions
sub ECLIENT_ERROR {  0 }
sub ECLIENT_NO_ERROR  { 1 }

# ESETClient error definitions
sub ESETCLIENT_ERROR {  0 }
sub ESETCLIENT_NO_ERROR {  1 }


# CESETClient SET result notification constants
sub HTTP_POST_RESULT_NOTIFICATION_STRING { "HTTP_POST_RESULT_NOTIFICATION" }
sub EMAIL_RESULT_NOTIFICATION_STRING {  "EMAIL_RESULT_NOTIFICATION" }
sub NO_RESULT_NOTIFICATION_STRING  { "NO_RESULT_NOTIFICATION" }

sub EMAIL_RESULT_NOTIFICATION {  1 }
sub HTTP_POST_RESULT_NOTIFICATION  { 2 }
sub NO_RESULT_NOTIFICATION {  3 }


################################
# Payer Authentication constants
#

# status
sub STATUS_ENROLLED { "Y" }
sub STATUS_NOT_ENROLLED { "N" }
sub STATUS_ENROLLED_BUT_AUTHENTICATION_UNAVAILABLE { "U" }
sub AUTHENTICATION_PREFIX {"authentication_"}


################################
# ACH constants
#

# Account Type
sub CHECKING { 1 }
sub SAVINGS  { 0 }

# Account Class
sub PERSONAL  { 0 }
sub CORPORATE { 1 }

################################
# Industry type constants
#

# Industry Type
sub DIRECT_MARKETING { "DIRECT_MARKETING" }
sub RETAIL { "RETAIL" }
sub LODGING { "LODGING" }
sub RESTAURANT { "RESTAURANT" }

1;
