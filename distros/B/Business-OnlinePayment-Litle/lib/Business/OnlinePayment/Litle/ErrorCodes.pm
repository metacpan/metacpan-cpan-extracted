package Business::OnlinePayment::Litle::ErrorCodes;
use strict;
use warnings;

our $VERSION = '0.955'; # VERSION
use Exporter 'import';
use vars qw(@EXPORT_OK);

@EXPORT_OK = qw(lookup %ERRORS);

our %ERRORS;

# ABSTRACT: Business::OnlinePayment::Litle::ErrorCodes - Error code hash


sub lookup {
    my $code = shift;
    return if not $code or not defined $ERRORS{$code};
    return $ERRORS{$code};
}


%ERRORS = (
          '000' => {
                     notes => 'Approved'
                   },
          '010' => {
                     notes => 'Partially Approved'
                   },
          '100' => {
                     notes => 'Processing Network Unavailable',
                     reason  => 'Visa/MC network is down',
                     status => 'Soft',
                   },
          '101' => {
                     notes => 'Issuer Unavailable',
                     reason => 'Issuing bank network is down',
                     status => 'Soft',
                   },
          '102' => {
                     notes => 'Re-submit Transaction',
                     reason =>  'Transaction was not accepted - please resubmit',
                     status =>  'Soft',
                   },
          '110' => {
                     notes => 'Insufficient Funds',
                     reason =>  'Cardholder does not have funds available',
                     status =>  'Soft',
                     failure    =>  'nsf',
                   },
          '111' => {
                     notes => 'Authorization amount has already been depleted',
                   },
          '120' => {
                     notes => 'Call Issuer',
                     reason =>  'Call Issuing Bank for details related to the decline',
                     status =>  'Soft',
                   },
          '121' => {
                     notes => 'Call AMEX',
                     reason =>  'Call Amex for details related to the decline',
                     status =>  'Soft',
                   },
          '122' => {
                     notes => 'Call Diners Club',
                     reason =>  'Call Diners Club for details related to the decline',
                     status =>  'Soft',
                   },
          '123' => {
                     notes => 'Call Discover',
                     reason =>  'Call Discover for details related to the decline',
                     status =>  'Soft',
                   },
          '124' => {
                     notes => 'Call JBS',
                     reason =>  'Call JBS for details related to the decline',
                     status =>  'Soft',
                   },
          '125' => {
                     notes => 'Call Visa/MasterCard',
                     reason =>  'Call Visa/MC for details related to the decline',
                     status =>  'Soft',
                   },
          '126' => {
                     notes => 'Call Issuer - Update Cardholder Data',
                     reason =>  'Call Issuing Bank for details related to the decline',
                     status =>  'Soft',
                   },
          '127' => {
                     notes => 'Exceeds Approval Amount Limit',
                     reason =>  'Cardholder has a maximum transaction amount that was exceeded',
                     status =>  'Soft',
                   },
          '130' => {
                     notes => 'Call Indicated Number',
                     reason =>  'Call the indicated phone number for details related to the decline',
                     status =>  'Soft',
                   },
          '140' => {
                     notes => 'Update Cardholder Data',
                     reason =>  'Submitted Cardholder Data is not correct',
                     status =>  'Hard',
                   },
          '191' => {
                     notes => 'The merchant is not registered in the update program.'
                   },
          '301' => {
                     notes => 'Invalid Account Number',
                     reason =>  'Credit Card number is not correct',
                     status =>  'Hard',
                   },
          '302' => {
                     notes => 'Account Number Does Not Match Payment Type',
                     reason =>  'Credit Card number does not match credit card type',
                     status =>  'Hard',
                   },
          '303' => {
                     notes => 'Pick Up Card',
                     reason =>  'In card-present situation, this is a request to retain the card from the customer',
                     status =>  'Hard',
                     failure    =>  'pickup',
                   },
          '304' => {
                     notes => 'Lost/Stolen Card',
                     reason =>  'The credit card was reported as lost or stolen',
                     status =>  'Hard',
                     failure    =>  'stolen',
                   },
          '305' => {
                     notes => 'Expired Card',
                     reason =>  'The card is no longer valid',
                     status =>  'Hard',
                     failure    =>  'expired',
                   },
          '306' => {
                     notes => 'Authorization has expired; no need to reverse',
                   },
          '307' => {
                     notes => 'Restricted Card',
                     reason =>  'There are either cardholder or merchant restrictions on the card',
                     status =>  'Hard',
                   },
          '308' => {
                     notes => 'Restricted Card - Chargeback'
                   },
          '310' => {
                     notes => 'Invalid track data'
                   },
          '311' => {
                     notes => 'Deposit is already referenced by a chargeback'
                   },
          '320' => {
                     notes => 'Invalid Expiration Date',
                     reason =>  'The expiration date submitted is not correct',
                     status =>  'Hard',
                   },
          '321' => {
                     notes => 'Invalid Merchant',
                     reason =>  'The cardholder is not allowed to submit transactions to you the merchant',
                     status =>  'Hard',
                   },
          '322' => {
                     notes => 'Invalid Transaction',
                     reason =>  'The merchant is not allowed to process transactions from this card',
                     status =>  'Hard',
                   },
          '323' => {
                     notes => 'No such issuer',
                     reason =>  'Credit Card is not valid as it is not a bank issued card',
                     status =>  'Hard',
                   },
          '324' => {
                     notes => 'Invalid Pin',
                     reason =>  'PIN is not correct',
                     status =>  'Hard',
                   },
          '325' => {
                     notes => 'Transaction not allowed at terminal',
                     reason =>  'The merchant is not allowed to process POS transactions from this card',
                     status =>  'Hard',
                   },
          '326' => {
                     notes => 'Exceeds number of PIN entries',
                     reason =>  'Too many invalid PIN entries occurred',
                     status =>  'Hard',
                   },
          '327' => {
                     notes => 'Cardholder transaction not permitted',
                     reason =>  'The merchant is not allowed to process transactions from this card',
                     status =>  'Hard',
                   },
          '328' => {
                     notes => 'Cardholder requested that recurring or installment payment be stopped',
                     reason =>  'The merchant should cancel recurring or installment relationship with credit card holder',
                     status =>  'Hard',
                   },
          '330' => {
                     notes => 'Invalid Payment Type',
                     reason =>  'The merchant does not accept payment type',
                     status =>  'Hard',
                   },
          '335' => {
                     notes => 'This method of payment does not support authorization reversals'
                   },
          '340' => {
                     notes => 'Invalid Amount'
                   },
          '346' => {
                     notes => 'Invalid billing descriptor prefix'
                   },
          '347' => {
                     notes => 'Invalid billing descriptor'
                   },
          '349' => {
                     notes => 'Do Not Honor',
                     reason =>  'Cardholder transactions are temporarily held pending issuing bank query with cardholder',
                     status =>  'Soft',
                   },
          '350' => {
                     notes => 'Generic Decline',
                     reason =>  'Nondescript decline. Call issuing bank for details related to the decline',
                     status =>  'Soft',
                   },
          '351' => {
                     notes => 'Decline - Request Positive ID',
                     reason =>  'Cardholder transactions not permitted without identification confirmation',
                     status =>  'Soft',
                   },
          '352' => {
                     notes => 'Decline CVV2/CID Fail',
                     reason =>  'CVV2/CID code is not correct and transaction is not approved due to this',
                     status =>  'Hard',
                   },
          '353' => {
                     notes => 'Merchant requested decline due to AVS result'
                   },
          '354' => {
                     notes => '3-D Secure transaction not supported by merchant'
                   },
          '355' => {
                     notes => 'Failed velocity check'
                   },
          '356' => {
                     notes => 'Invalid purchase level III, the transaction contained bad or missing data'
                   },
          '360' => {
                     notes => 'No transaction found with specified litleTxnId'
                   },
          '361' => {
                     notes => 'Authorization no longer available'
                   },
          '362' => {
                     notes => 'Transaction Not Voided - Already Settled'
                   },
          '363' => {
                     notes => 'Auto-void on refund'
                   },
          '365' => {
                     notes => 'Total credit amount exceeds capture amount'
                   },
          '370' => {
                     notes => 'Internal System Error - Call Litle',
                     reason =>  'Call Litle & Co. for details related to the decline',
                     status =>  'Hard',
                   },
          '400' => {
                     notes => 'No Email Notification was sent for the transaction'
                   },
          '401' => {
                     notes => 'Invalid Email Address'
                   },
          '500' => {
                     notes => 'The account number was changed'
                   },
          '501' => {
                     notes => 'The account was closed'
                   },
          '502' => {
                     notes => 'The expiration date was changed'
                   },
          '503' => {
                     notes => 'The issuing bank does not participate in the update program'
                   },
          '504' => {
                     notes => 'Contact the cardholder for updated information'
                   },
          '505' => {
                     notes => 'No match found'
                   },
          '506' => {
                     notes => 'No changes found'
                   },
          '601' => {
                     notes => 'Soft Decline - Primary Funding Source Failed'
                   },
          '602' => {
                     notes => 'Soft Decline - Buyer has alternate funding source'
                   },
          '610' => {
                     notes => 'Hard Decline - Invalid Billing Agreement Id'
                   },
          '611' => {
                     notes => 'Hard Decline - Primary Funding Source Failed'
                   },
          '612' => {
                     notes => 'Hard Decline - Issue with Paypal Account'
                   },
          '701' => {
                     notes => 'Under 18 years old'
                   },
          '702' => {
                     notes => 'Bill to outside USA'
                   },
          '703' => {
                     notes => 'Bill to address is not equal to ship to address'
                   },
          '704' => {
                     notes => 'Declined, foreign currency, must be USD'
                   },
          '705' => {
                     notes => 'On negative file'
                   },
          '706' => {
                     notes => 'Blocked agreement'
                   },
          '707' => {
                     notes => 'Insufficient buying power'
                   },
          '708' => {
                     notes => 'Invalid Data'
                   },
          '709' => {
                     notes => 'Invalid Data - data elements missing'
                   },
          '710' => {
                     notes => 'Invalid Data - data format error'
                   },
          '711' => {
                     notes => 'Invalid Data - Invalid T&C version'
                   },
          '712' => {
                     notes => 'Duplicate transaction'
                   },
          '713' => {
                     notes => 'Verify billing address'
                   },
          '714' => {
                     notes => 'Inactive Account'
                   },
          '716' => {
                     notes => 'Invalid Auth'
                   },
          '717' => {
                     notes => 'Authorization already exists for the order'
                   },
          '900' => {
                     notes => 'Invalid Bank Routing Number'
                   }
        );
1;

__END__

=pod

=head1 NAME

Business::OnlinePayment::Litle::ErrorCodes - Business::OnlinePayment::Litle::ErrorCodes - Error code hash

=head1 VERSION

version 0.955

=head1 METHODS

=head2 lookup

Return the information associated with an error code

=head1 AUTHOR

Jason Hall <jayce@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jason Hall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
