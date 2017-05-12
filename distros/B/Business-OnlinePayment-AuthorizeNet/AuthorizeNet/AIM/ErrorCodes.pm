package Business::OnlinePayment::AuthorizeNet::AIM::ErrorCodes;

use strict;
use warnings;

use Exporter 'import';
use vars qw(@EXPORT_OK $VERSION);

@EXPORT_OK = qw(lookup %ERRORS);
$VERSION = '0.01';

=head1 NAME

Business::OnlinePayment::AuthorizeNet::AIM::ErrorCodes - Easy lookup of Authorize.Net's AIM result reason codes

=head1 SYNOPSIS

    use Business::OnlinePayment::AuthorizeNet::AIM::ErrorCodes 'lookup';
    my $result = lookup( $result_code );
    # $result = { reason => ..., notes => ... };

or

    use Business::OnlinePayment::AuthorizeNet::AIM::ErrorCodes '%ERRORS';
    my $result = $ERRORS{ $result_code };

=head1 DESCRIPTION

This module exists to lookup the textual descriptions of errors returned by
Authorize.Net's AIM submission method.  The error messages returned in the
gateway's response are often not as useful as those in Authorize.Net's AIM
guide (L<http://www.authorize.net/support/AIM_guide.pdf>).

=head2 lookup CODE

Takes the result code returned by Authorize.Net's AIM gateway.  Returns a
hashref containing two keys, C<reason> and C<notes> (which may be empty) if
the lookup is successful, undef otherwise.

=head1 AUTHOR

Thomas Sibley <trs@bestpractical.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

our %ERRORS;

sub lookup {
    my $code = shift;
    return if not $code or not defined $ERRORS{$code};
    return $ERRORS{$code};
}

%ERRORS = (
      '127' => {
                 'notes' => 'The system-generated void for the original AVS-rejected transaction failed.',
                 'reason' => 'The transaction resulted in an AVS mismatch. The address provided does not match billing address of cardholder.'
               },
      '32' => {
                'notes' => '',
                'reason' => 'This reason code is reserved or not applicable to this API.'
              },
      '90' => {
                'notes' => '',
                'reason' => 'This reason code is reserved or not applicable to this API.'
              },
      '206' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. The merchant is not on file.',
                 'reason' => 'This transaction has been declined.'
               },
      '118' => {
                 'notes' => 'This code is applicable only to merchants that include the x_authentication_indicator and x_authentication_value in the transaction request. The combination of authentication indicator and cardholder authentication value for a Visa or MasterCard transaction is invalid.',
                 'reason' => 'The combination of authentication indicator and cardholder authentication value is invalid.'
               },
      '71' => {
                'notes' => 'The value submitted in x_bank_acct_type was invalid.',
                'reason' => 'The bank account type is invalid.'
              },
      '102' => {
                 'notes' => 'A password or transaction key was submitted with this WebLink request. This is a high security risk.',
                 'reason' => 'This request cannot be accepted.'
               },
      '200' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. The credit card number is invalid.',
                 'reason' => 'This transaction has been declined.'
               },
      '18' => {
                'notes' => 'The merchant does not accept electronic checks.',
                'reason' => 'ACH transactions are not accepted by this merchant.'
              },
      '16' => {
                'notes' => 'The transaction ID sent in was properly formatted but the gateway had no record of the transaction.',
                'reason' => 'The transaction was not found.'
              },
      '44' => {
                'notes' => 'The merchant would receive this error if the Card Code filter has been set in the Merchant Interface and the transaction received an error code from the processor that matched the rejection criteria set by the merchant.',
                'reason' => 'This transaction has been declined.'
              },
      '55' => {
                'notes' => 'The transaction is rejected if the sum of this credit and prior credits exceeds the original debit amount.',
                'reason' => 'The sum of credits against the referenced transaction would exceed the original debit amount.'
              },
      '84' => {
                'notes' => '',
                'reason' => 'This reason code is reserved or not applicable to this API.'
              },
      '27' => {
                'notes' => '',
                'reason' => 'The transaction resulted in an AVS mismatch. The address provided does not match billing address of cardholder.'
              },
      '95' => {
                'notes' => 'This code is applicable to Wells Fargo SecureSource merchants only.',
                'reason' => 'A valid state is required.'
              },
      '57' => {
                'notes' => '',
                'reason' => 'An error occurred in processing. Please try again in 5 minutes.'
              },
      '220' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. The primary CPU is not available.',
                 'reason' => 'This transaction has been declined.'
               },
      '20' => {
                'notes' => '',
                'reason' => 'An error occurred during processing. Please try again in 5 minutes.'
              },
      '243' => {
                 'notes' => 'The combination of values submitted for x_recurring_billing and x_echeck_type is not allowed.',
                 'reason' => 'Recurring billing is not allowed for this eCheck.Net type.'
               },
      '109' => {
                 'notes' => 'Applicable only to eCheck. The values submitted for first name and last name failed validation.',
                 'reason' => 'This transaction is currently under review.'
               },
      '89' => {
                'notes' => '',
                'reason' => 'This reason code is reserved or not applicable to this API.'
              },
      '175' => {
                 'notes' => 'Concord EFS Ð This transaction is not allowed. The Concord EFS processing platform does not support voiding credit transactions. Please debit the credit card instead of voiding the credit.',
                 'reason' => 'The processor does not allow voiding of credits.'
               },
      '31' => {
                'notes' => 'The merchant was incorrectly set up at the processor.',
                'reason' => 'The FDC Merchant ID or Terminal ID is incorrect. Call Merchant Service Provider.'
              },
      '35' => {
                'notes' => 'The merchant was incorrectly set up at the processor.',
                'reason' => 'An error occurred during processing. Call Merchant Service Provider.'
              },
      '11' => {
                'notes' => 'A transaction with identical amount and credit card information was submitted two minutes prior.',
                'reason' => 'A duplicate transaction has been submitted.'
              },
      '208' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. The merchant is not on file.',
                 'reason' => 'This transaction has been declined.'
               },
      '78' => {
                'notes' => 'The value submitted in x_card_code failed format validation.',
                'reason' => 'The Card Code (CVV2/CVC2/CID) is invalid.'
              },
      '93' => {
                'notes' => 'This code is applicable to Wells Fargo SecureSource merchants only. Country is a required field and must contain the value of a supported country.',
                'reason' => 'A valid country is required.'
              },
      '106' => {
                 'notes' => 'Applicable only to eCheck. The value submitted for company failed validation.',
                 'reason' => 'This transaction is currently under review.'
               },
      '65' => {
                'notes' => 'The transaction was declined because the merchant configured their account through the Merchant Interface to reject transactions with certain values for a Card Code mismatch.',
                'reason' => 'This transaction has been declined.'
              },
      '29' => {
                'notes' => '',
                'reason' => 'The PaymentTech identification numbers are incorrect. Call Merchant Service Provider.'
              },
      '203' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. The value submitted in the amount field is invalid.',
                 'reason' => 'This transaction has been declined.'
               },
      '261' => {
                 'notes' => 'The transaction experienced an error during sensitive data encryption and was not processed. Please try again.',
                 'reason' => 'An error occurred during processing. Please try again.'
               },
      '58' => {
                'notes' => '',
                'reason' => 'An error occurred in processing. Please try again in 5 minutes.'
              },
      '211' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. The cardholder is not on file.',
                 'reason' => 'This transaction has been declined.'
               },
      '15' => {
                'notes' => 'The transaction ID value is non-numeric or was not present for a transaction that requires it (i.e., VOID, PRIOR_AUTH_CAPTURE, and CREDIT).',
                'reason' => 'The transaction ID is invalid.'
              },
      '81' => {
                'notes' => 'The merchant requested an integration method not compatible with the AIM API.',
                'reason' => 'The requested form type is invalid.'
              },
      '60' => {
                'notes' => '',
                'reason' => 'An error occurred in processing. Please try again in 5 minutes.'
              },
      '101' => {
                 'notes' => 'Applicable only to eCheck. The specified name on the account and/or the account type do not match the NOC record for this account.',
                 'reason' => 'The given name on the account and/or the account type does not match the actual account.'
               },
      '73' => {
                'notes' => 'The format of the value submitted in x_drivers_license_num was invalid.',
                'reason' => 'The driverÕs license date of birth is invalid.'
              },
      '86' => {
                'notes' => '',
                'reason' => 'This reason code is reserved or not applicable to this API.'
              },
      '76' => {
                'notes' => 'The value submitted in x_tax failed format validation.',
                'reason' => 'The tax amount is invalid.'
              },
      '62' => {
                'notes' => '',
                'reason' => 'An error occurred in processing. Please try again in 5 minutes.'
              },
      '247' => {
                 'notes' => 'The combination of values submitted for x_type and x_echeck_type is not allowed.',
                 'reason' => 'This eCheck.Net type is not allowed.'
               },
      '67' => {
                'notes' => 'This error code is applicable to merchants using the Wells Fargo SecureSource product only. This product does not allow transactions of type CAPTURE_ONLY.',
                'reason' => 'The given transaction type is not supported for this merchant.'
              },
      '204' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. The department code is invalid.',
                 'reason' => 'This transaction has been declined.'
               },
      '165' => {
                 'notes' => 'The system-generated void for the original card code-rejected transaction failed.',
                 'reason' => 'This transaction has been declined.'
               },
      '2' => {
               'notes' => '',
               'reason' => 'This transaction has been declined.'
             },
      '17' => {
                'notes' => 'The merchant was not configured to accept the credit card submitted in the transaction.',
                'reason' => 'The merchant does not accept this type of credit card.'
              },
      '110' => {
                 'notes' => 'Applicable only to eCheck. The value submitted for bank account name does not contain valid characters.',
                 'reason' => 'This transaction is currently under review.'
               },
      '82' => {
                'notes' => 'The system no longer supports version 2.5; requests cannot be posted to scripts.',
                'reason' => 'Scripts are only supported in version 2.5.'
              },
      '218' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. The PIN block format or PIN availability value is invalid.',
                 'reason' => 'This transaction has been declined.'
               },
      '202' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. The transaction type is invalid.',
                 'reason' => 'This transaction has been declined.'
               },
      '14' => {
                'notes' => 'The Relay Response or Referrer URL does not match the merchantÕs configured value(s) or is absent. Applicable only to SIM and WebLink APIs.',
                'reason' => 'The Referrer or Relay Response URL is invalid.'
              },
      '112' => {
                 'notes' => 'This code is applicable to Wells Fargo SecureSource merchants only.',
                 'reason' => 'A valid billing state/province is required.'
               },
      '69' => {
                'notes' => 'The value submitted in x_type was invalid.',
                'reason' => 'The transaction type is invalid.'
              },
      '172' => {
                 'notes' => 'Concord EFS Ð The store ID is invalid.',
                 'reason' => 'An error occurred during processing. Please contact the merchant.'
               },
      '145' => {
                 'notes' => 'The system-generated void for the original card code-rejected and AVS-rejected transaction failed.',
                 'reason' => 'This transaction has been declined.'
               },
      '49' => {
                'notes' => 'The transaction amount submitted was greater than the maximum amount allowed.',
                'reason' => 'A transaction amount greater than $[amount] will not be accepted.'
              },
      '24' => {
                'notes' => '',
                'reason' => 'The Nova Bank Number or Terminal ID is incorrect. Call Merchant Service Provider.'
              },
      '224' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. Please re-enter the transaction.',
                 'reason' => 'This transaction has been declined.'
               },
      '223' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. This transaction experienced an unspecified error.',
                 'reason' => 'This transaction has been declined.'
               },
      '104' => {
                 'notes' => 'Applicable only to eCheck. The value submitted for country failed validation.',
                 'reason' => 'This transaction is currently under review.'
               },
      '131' => {
                 'notes' => 'IFT: The payment gateway account status is Suspended-STA.',
                 'reason' => 'This transaction cannot be accepted at this time.'
               },
      '181' => {
                 'notes' => 'The system-generated void for the original invalid transaction failed. (The original transaction included an invalid processor response format.)',
                 'reason' => 'An error occurred during processing. Please try again.'
               },
      '121' => {
                 'notes' => 'The system-generated void for the original errored transaction failed. (The original transaction experienced a database error.)',
                 'reason' => 'An error occurred during processing. Please try again.'
               },
      '79' => {
                'notes' => 'The value submitted in x_drivers_license_num failed format validation.',
                'reason' => 'The driverÕs license number is invalid.'
              },
      '212' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. The bank configuration is not on file',
                 'reason' => 'This transaction has been declined.'
               },
      '23' => {
                'notes' => '',
                'reason' => 'An error occurred during processing. Please try again in 5 minutes.'
              },
      '96' => {
                'notes' => 'This code is applicable to Wells Fargo SecureSource merchants only. Country is a required field and must contain the value of a supported country.',
                'reason' => 'This country is not authorized for buyers.'
              },
      '251' => {
                 'notes' => 'The transaction was declined as a result of triggering a Fraud Detection Suite filter.',
                 'reason' => 'This transaction has been declined.'
               },
      '253' => {
                 'notes' => 'The transaction was accepted and was authorized, but is being held for merchant review. The merchant may customize the customer response in the Merchant Interface.',
                 'reason' => 'Your order has been received. Thank you for your business!'
               },
      '47' => {
                'notes' => 'This occurs if the merchant tries to capture funds greater than the amount of the original authorization-only transaction.',
                'reason' => 'The amount requested for settlement may not be greater than the original amount authorized.'
              },
      '8' => {
               'notes' => '',
               'reason' => 'The credit card has expired.'
             },
      '209' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. Communication with the processor could not be established.',
                 'reason' => 'This transaction has been declined.'
               },
      '98' => {
                'notes' => 'Applicable only to SIM API. The transaction fingerprint has already been used.',
                'reason' => 'This transaction cannot be accepted.'
              },
      '216' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. The ATM term ID is invalid.',
                 'reason' => 'This transaction has been declined.'
               },
      '37' => {
                'notes' => '',
                'reason' => 'The credit card number is invalid.'
              },
      '117' => {
                 'notes' => 'This code is applicable only to merchants that include the x_cardholder_authentication_value in the transaction request. The CAVV for a Visa transaction; or the AVV/UCAF for a MasterCard transaction is invalid.',
                 'reason' => 'The cardholder authentication value is invalid.'
               },
      '43' => {
                'notes' => 'The merchant was incorrectly set up at the processor.',
                'reason' => 'The merchant was incorrectly set up at the processor. Call your Merchant Service Provider.'
              },
      '270' => {
                 'notes' => 'A value submitted in x_line_item for the item referenced is invalid.',
                 'reason' => 'The line item [item number] is invalid.'
               },
      '5' => {
               'notes' => 'The value submitted in the amount field did not pass validation for a number.',
               'reason' => 'A valid amount is required.'
             },
      '170' => {
                 'notes' => 'Concord EFS Ð Provisioning at the processor has not been completed.',
                 'reason' => 'An error occurred during processing. Please contact the merchant.'
               },
      '33' => {
                'notes' => 'The word FIELD will be replaced by an actual field name. This error indicates that a field the merchant specified as required was not filled in.',
                'reason' => 'FIELD cannot be left blank.'
              },
      '21' => {
                'notes' => '',
                'reason' => 'An error occurred during processing. Please try again in 5 minutes.'
              },
      '63' => {
                'notes' => '',
                'reason' => 'An error occurred in processing. Please try again in 5 minutes.'
              },
      '7' => {
               'notes' => 'The format of the date submitted was incorrect.',
               'reason' => 'The credit card expiration date is invalid.'
             },
      '26' => {
                'notes' => '',
                'reason' => 'An error occurred during processing. Please try again in 5 minutes.'
              },
      '80' => {
                'notes' => 'The value submitted in x_drivers_license_state failed format validation.',
                'reason' => 'The driverÕs license state is invalid.'
              },
      '193' => {
                 'notes' => 'The transaction was placed under review by the risk management system.',
                 'reason' => 'The transaction is currently under review.'
               },
      '119' => {
                 'notes' => 'This code is applicable only to merchants that include the x_authentication_indicator and x_recurring_billing in the transaction request. Transactions submitted with a value in x_authentication_indicator AND x_recurring_billing =YES will be rejected.',
                 'reason' => 'Transactions having cardholder authentication values cannot be marked as recurring.'
               },
      '180' => {
                 'notes' => 'The processor response format is invalid.',
                 'reason' => 'An error occurred during processing. Please try again.'
               },
      '99' => {
                'notes' => 'Applicable only to SIM API. The server-generated fingerprint does not match the merchant-specified fingerprint in the x_fp_hash field.',
                'reason' => 'This transaction cannot be accepted.'
              },
      '244' => {
                 'notes' => 'The combination of values submitted for x_bank_acct_type and x_echeck_type is not allowed.',
                 'reason' => 'This eCheck.Net type is not allowed for this Bank Account Type.'
               },
      '72' => {
                'notes' => 'The value submitted in x_auth_code was more than six characters in length.',
                'reason' => 'The authorization code is invalid.'
              },
      '246' => {
                 'notes' => 'The merchantÕs payment gateway account is not enabled to submit the eCheck.Net type.',
                 'reason' => 'This eCheck.Net type is not allowed.'
               },
      '74' => {
                'notes' => 'The value submitted in x_duty failed format validation.',
                'reason' => 'The duty amount is invalid.'
              },
      '61' => {
                'notes' => '',
                'reason' => 'An error occurred in processing. Please try again in 5 minutes.'
              },
      '108' => {
                 'notes' => 'Applicable only to eCheck. The values submitted for first name and last name failed validation.',
                 'reason' => 'This transaction is currently under review.'
               },
      '92' => {
                'notes' => '',
                'reason' => 'The gateway no longer supports the requested method of integration.'
              },
      '103' => {
                 'notes' => 'A valid fingerprint, transaction key, or password is required for this transaction.',
                 'reason' => 'This transaction cannot be accepted.'
               },
      '201' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. The expiration date is invalid.',
                 'reason' => 'This transaction has been declined.'
               },
      '10' => {
                'notes' => 'The value submitted in the x_bank_acct_num field did not pass validation.',
                'reason' => 'The account number is invalid.'
              },
      '152' => {
                 'notes' => 'The system-generated void for the original transaction failed. The response for the original transaction could not be communicated to the client.',
                 'reason' => 'The transaction was authorized, but the client could not be notified; the transaction will not be settled.'
               },
      '207' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. The merchant account is closed.',
                 'reason' => 'This transaction has been declined.'
               },
      '91' => {
                'notes' => '',
                'reason' => 'Version 2.5 is no longer supported.'
              },
      '48' => {
                'notes' => 'The merchant attempted to settle for less than the originally authorized amount.',
                'reason' => 'This processor does not accept partial reversals.'
              },
      '107' => {
                 'notes' => 'Applicable only to eCheck. The value submitted for bank account name failed validation.',
                 'reason' => 'This transaction is currently under review.'
               },
      '87' => {
                'notes' => '',
                'reason' => 'This reason code is reserved or not applicable to this API.'
              },
      '174' => {
                 'notes' => 'Concord EFS Ð This transaction type is not accepted by the processor.',
                 'reason' => 'The transaction type is invalid. Please contact the merchant.'
               },
      '77' => {
                'notes' => 'The value submitted in x_customer_tax_id  failed validation.',
                'reason' => 'The SSN or tax ID is invalid.'
              },
      '214' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. This function is currently unavailable.',
                 'reason' => 'This transaction has been declined.'
               },
      '123' => {
                 'notes' => 'The transaction request must include the API login ID associated with the payment gateway account.',
                 'reason' => 'This account has not been given the permission(s) required for this request.'
               },
      '221' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. The SE number is invalid.',
                 'reason' => 'This transaction has been declined.'
               },
      '50' => {
                'notes' => 'Credits or refunds may only be performed against settled transactions. The transaction against which the credit/refund was submitted has not been settled, so a credit cannot be issued.',
                'reason' => 'This transaction is awaiting settlement and cannot be refunded.'
              },
      '39' => {
                'notes' => '',
                'reason' => 'The supplied currency code is either invalid, not supported, not allowed for this merchant or doesnÕt have an exchange rate.'
              },
      '210' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. The merchant type is incorrect.',
                 'reason' => 'This transaction has been declined.'
               },
      '64' => {
                'notes' => 'This error is applicable to Wells Fargo SecureSource merchants only. Credits or refunds cannot be issued against transactions that were not authorized.',
                'reason' => 'The referenced transaction was not approved.'
              },
      '97' => {
                'notes' => 'Applicable only to SIM API. Fingerprints are only valid for a short period of time. This code indicates that the transaction fingerprint has expired.',
                'reason' => 'This transaction cannot be accepted.'
              },
      '12' => {
                'notes' => 'A transaction that required x_auth_code to be present was submitted without a value.',
                'reason' => 'An authorization code is required but not present.'
              },
      '41' => {
                'notes' => 'Only merchants set up for the FraudScreen.Net service would receive this decline. This code will be returned if a given transactionÕs fraud score is higher than the threshold set by the merchant.',
                'reason' => 'This transaction has been declined.'
              },
      '52' => {
                'notes' => '',
                'reason' => 'The transaction was authorized, but the client could not be notified; the transaction will not be settled.'
              },
      '173' => {
                 'notes' => 'Concord EFS Ð The store key is invalid.',
                 'reason' => 'An error occurred during processing. Please contact the merchant.'
               },
      '56' => {
                'notes' => 'The merchant processes eCheck transactions only and does not accept credit cards.',
                'reason' => 'This merchant accepts ACH transactions only; no credit card transactions are accepted.'
              },
      '45' => {
                'notes' => 'This error would be returned if the transaction received a code from the processor that matched the rejection criteria set by the merchant for both the AVS and Card Code filters.',
                'reason' => 'This transaction has been declined.'
              },
      '66' => {
                'notes' => 'The transaction did not meet gateway security guidelines.',
                'reason' => 'This transaction cannot be accepted for processing.'
              },
      '19' => {
                'notes' => '',
                'reason' => 'An error occurred during processing. Please try again in 5 minutes.'
              },
      '54' => {
                'notes' => '',
                'reason' => 'The referenced transaction does not meet the criteria for issuing a credit.'
              },
      '70' => {
                'notes' => 'The value submitted in x_method was invalid.',
                'reason' => 'The transaction method is invalid.'
              },
      '68' => {
                'notes' => 'The value submitted in x_version was invalid.',
                'reason' => 'The version parameter is invalid.'
              },
      '1' => {
               'notes' => '',
               'reason' => 'This transaction has been approved.'
             },
      '88' => {
                'notes' => '',
                'reason' => 'This reason code is reserved or not applicable to this API.'
              },
      '116' => {
                 'notes' => 'This code is applicable only to merchants that include the x_authentication_indicator in the transaction request. The ECI value for a Visa transaction; or the UCAF indicator for a MasterCard transaction submitted in the x_authentication_indicator field is invalid.',
                 'reason' => 'The authentication indicator is invalid.'
               },
      '30' => {
                'notes' => '',
                'reason' => 'The configuration with the processor is invalid. Call Merchant Service Provider.'
              },
      '141' => {
                 'notes' => 'The system-generated void for the original FraudScreen-rejected transaction failed.',
                 'reason' => 'This transaction has been declined.'
               },
      '100' => {
                 'notes' => 'Applicable only to eCheck. The value specified in the x_echeck_type field is invalid.',
                 'reason' => 'The eCheck type is invalid.'
               },
      '222' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. Duplicate auth request (from INAS).',
                 'reason' => 'This transaction has been declined.'
               },
      '25' => {
                'notes' => '',
                'reason' => 'An error occurred during processing. Please try again in 5 minutes.'
              },
      '128' => {
                 'notes' => 'The customer\'s financial institution does not currently allow transactions for this account.',
                 'reason' => 'This transaction cannot be processed.'
               },
      '252' => {
                 'notes' => 'The transaction was accepted, but is being held for merchant review. The merchant may customize the customer response in the Merchant Interface.',
                 'reason' => 'Your order has been received. Thank you for your business!'
               },
      '28' => {
                'notes' => 'The Merchant ID at the processor was not configured to accept this card type.',
                'reason' => 'The merchant does not accept this type of credit card.'
              },
      '120' => {
                 'notes' => 'The system-generated void for the original timed-out transaction failed. (The original transaction timed out while waiting for a response from the authorizer.)',
                 'reason' => 'An error occurred during processing. Please try again.'
               },
      '40' => {
                'notes' => '',
                'reason' => 'This transaction must be encrypted.'
              },
      '75' => {
                'notes' => 'The value submitted in x_freight failed format validation.',
                'reason' => 'The freight amount is invalid.'
              },
      '83' => {
                'notes' => 'The system no longer supports version 2.5; requests cannot be posted to scripts.',
                'reason' => 'The requested script is either invalid or no longer supported.'
              },
      '250' => {
                 'notes' => 'This transaction was submitted from a blocked IP address.',
                 'reason' => 'This transaction has been declined.'
               },
      '59' => {
                'notes' => '',
                'reason' => 'An error occurred in processing. Please try again in 5 minutes.'
              },
      '254' => {
                 'notes' => 'The transaction was declined after manual review.',
                 'reason' => 'Your transaction has been declined.'
               },
      '215' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. The encrypted PIN field format is invalid.',
                 'reason' => 'This transaction has been declined.'
               },
      '271' => {
                 'notes' => 'The number of line items submitted in x_line_item exceeds the allowed maximum of 30.',
                 'reason' => 'The number of line items submitted is not allowed. A maximum of 30 line items can be submitted.'
               },
      '130' => {
                 'notes' => 'IFT: The payment gateway account status is Blacklisted.',
                 'reason' => 'This payment gateway account has been closed.'
               },
      '217' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. This transaction experienced a general message format problem.',
                 'reason' => 'This transaction has been declined.'
               },
      '53' => {
                'notes' => 'If x_method = ECHECK, x_type cannot be set to CAPTURE_ONLY.',
                'reason' => 'The transaction type was invalid for ACH transactions.'
              },
      '245' => {
                 'notes' => 'The value submitted for x_echeck_type is not allowed when using the payment gateway hosted payment form.',
                 'reason' => 'This eCheck.Net type is not allowed when using the payment gateway hosted payment form.'
               },
      '122' => {
                 'notes' => 'The system-generated void for the original errored transaction failed. (The original transaction experienced a processing error.)',
                 'reason' => 'An error occurred during processing. Please try again.'
               },
      '205' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. The value submitted in the merchant number field is invalid.',
                 'reason' => 'This transaction has been declined.'
               },
      '42' => {
                'notes' => 'This is applicable only to merchants processing through the Wells Fargo SecureSource product who have requirements for transaction submission that are different from merchants not processing through Wells Fargo.',
                'reason' => 'There is missing or invalid information in a required field.'
              },
      '22' => {
                'notes' => '',
                'reason' => 'An error occurred during processing. Please try again in 5 minutes.'
              },
      '219' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. The ETC void is unmatched.',
                 'reason' => 'This transaction has been declined.'
               },
      '46' => {
                'notes' => '',
                'reason' => 'Your session has expired or does not exist. You must log in to continue working.'
              },
      '13' => {
                'notes' => '',
                'reason' => 'The merchant API login ID is invalid or the account is inactive.'
              },
      '105' => {
                 'notes' => 'Applicable only to eCheck. The values submitted for city and country failed validation.',
                 'reason' => 'This transaction is currently under review.'
               },
      '6' => {
               'notes' => '',
               'reason' => 'The credit card number is invalid.'
             },
      '85' => {
                'notes' => '',
                'reason' => 'This reason code is reserved or not applicable to this API.'
              },
      '185' => {
                 'notes' => '',
                 'reason' => 'This reason code is reserved or not applicable to this API.'
               },
      '36' => {
                'notes' => '',
                'reason' => 'The authorization was approved, but settlement failed.'
              },
      '3' => {
               'notes' => '',
               'reason' => 'This transaction has been declined.'
             },
      '248' => {
                 'notes' => 'Invalid check number. Check number can only consist of letters and numbers and not more than 15 characters.',
                 'reason' => 'The check number is invalid.'
               },
      '213' => {
                 'notes' => 'This error code applies only to merchants on FDC Omaha. The merchant assessment code is incorrect.',
                 'reason' => 'This transaction has been declined.'
               },
      '94' => {
                'notes' => 'This code is applicable to Wells Fargo SecureSource merchants only.',
                'reason' => 'The shipping state or country is invalid.'
              },
      '51' => {
                'notes' => '',
                'reason' => 'The sum of all credits against this transaction is greater than the original transaction amount.'
              },
      '9' => {
               'notes' => 'The value submitted in the x_bank_aba_code field did not pass validation or was not for a valid financial institution.',
               'reason' => 'The ABA code is invalid.'
             },
      '111' => {
                 'notes' => 'This code is applicable to Wells Fargo SecureSource merchants only.',
                 'reason' => 'A valid billing country is required.'
               },
      '38' => {
                'notes' => 'The merchant was incorrectly set up at the processor.',
                'reason' => 'The Global Payment System identification numbers are incorrect. Call Merchant Service Provider.'
              },
      '4' => {
               'notes' => 'The code returned from the processor indicating that the card used needs to be picked up.',
               'reason' => 'This transaction has been declined.'
             },
      '34' => {
                'notes' => 'The merchant was incorrectly set up at the processor.',
                'reason' => 'The VITAL identification numbers are incorrect. Call Merchant Service Provider.'
              },
      '132' => {
                 'notes' => 'IFT: The payment gateway account status is Suspended-Blacklist.',
                 'reason' => 'This transaction cannot be accepted at this time.'
               },
      '171' => {
                 'notes' => 'Concord EFS Ð This request is invalid.',
                 'reason' => 'An error occurred during processing. Please contact the merchant.'
               }
);

1;
