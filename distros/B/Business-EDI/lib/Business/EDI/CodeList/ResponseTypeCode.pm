package Business::EDI::CodeList::ResponseTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4343;}
my $usage       = 'C';

# 4343  Response type code                                      [C]
# Desc: Code specifying the type of acknowledgment required or
# transmitted.
# Repr: an..3

my %code_hash = (
'AA' => [ 'Debit advice',
    'Receiver of the payment message needs to return a debit advice in response to the payment message.' ],
'AB' => [ 'Message acknowledgement',
    'Indicates that an acknowledgement relating to receipt of message is required.' ],
'AC' => [ 'Acknowledge - with detail and change',
    'Acknowledge complete including changes.' ],
'AD' => [ 'Acknowledge - with detail, no change',
    'Acknowledge complete without changes.' ],
'AE' => [ 'Debit advice for each transaction',
    'A debit advice is requested for each transaction in the message.' ],
'AF' => [ 'Debit advice/message acknowledgement',
    'The sender wishes to receive both a Debit Advice and an acknowledgement of receipt for a payment message.' ],
'AG' => [ 'Authentication',
    'Authentication, by a party, of a document established for him by another party.' ],
'AH' => [ 'Debit advice/message acknowledgement for each transaction',
    'A debit advice and message acknowledgement are requested for each transaction in the message.' ],
'AI' => [ 'Acknowledge only changes',
    'Acknowledgement of changes only is required.' ],
'AJ' => [ 'Pending',
    'Indication that the referenced offer or transaction (e.g. cargo booking or quotation request) is being dealt with.' ],
'AP' => [ 'Accepted',
    'Indication that the referenced offer or transaction (e.g., cargo booking or quotation request) has been accepted.' ],
'AQ' => [ 'Response expected',
    'The sender of the message expects a response.' ],
'AR' => [ 'Direct documentary credit collection',
    'Documentary credit collection forwarded directly.' ],
'AS' => [ 'Credit advice and message acknowledgement',
    'The receiver of the message is to acknowledge receipt of the message and sent a credit advice for each credit.' ],
'CA' => [ 'Conditionally accepted',
    'Indication that the referenced offer or transaction (e.g., cargo booking or quotation request) has been accepted under conditions indicated in this message.' ],
'CO' => [ 'Confirmation of measurements',
    'Indication that the message contains the physical measurements on which the charges will be based.' ],
'NA' => [ 'No acknowledgement needed',
    'Specifies that no acknowledgement is needed in response to this message.' ],
'RE' => [ 'Rejected',
    'Indication that the referenced offer or transaction (e.g., cargo booking or quotation request) is not accepted.' ],
'UR' => [ 'Credit advice',
    'The message recipient is to send a credit advice in response to the message.' ],
'US' => [ 'Acknowledgement when error',
    'An acknowledgement is requested when an error occurred.' ],
'UT' => [ 'Acknowledgment due to error',
    'An acknowledgment is sent because an error was identified in the received message.' ],
'UU' => [ 'Alternate date',
    'The solution proposed in the response applies to another date than the one requested.' ],
'UV' => [ 'Alternate service',
    'The solution proposed in the response applies to another service than the one requested.' ],
);
sub get_codes { return \%code_hash; }

1;
