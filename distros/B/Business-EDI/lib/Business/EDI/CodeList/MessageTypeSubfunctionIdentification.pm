package Business::EDI::CodeList::MessageTypeSubfunctionIdentification;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0113";}
my $usage       = 'B';

# 0113  Message type sub-function identification
# Desc: Code identifying a sub-function of a message type.
# Repr: an..6

my %code_hash = (
'AA' => [ 'Interactive, perform sell',
    'This sub-function is to notify the receiver that the purpose of the message is an instruction to perform a sell.' ],
'AB' => [ 'Interactive, modify current dialogue data',
    'This sub-function is to notify the receiver that the message data is a modification to data previously sent in the current interactive dialogue.' ],
'AC' => [ 'Interactive, modify previous dialogue data',
    'This sub-function is to notify the receiver that the message data is a modification to data sent in a previous interactive dialogue.' ],
'AD' => [ 'Interactive, cancel reserved product',
    'This sub-function is to notify the receiver that the purpose of the message is to cancel a product previously reserved in an interactive dialogue.' ],
'AE' => [ 'Interactive, ignore reserved product',
    'This sub-function is to notify the receiver that the purpose of the message is to ignore a product previously reserved in an interactive dialogue.' ],
'AF' => [ 'Interactive, conclude current reservation',
    'This sub-function is to notify the receiver that the purpose of the message is to conclude the current reservation transaction.' ],
'AG' => [ 'Interactive, display reserved product',
    'This sub-function is to notify the receiver that the purpose of the message is to display a product previously reserved in an interactive dialogue.' ],
'AH' => [ 'Interactive, perform reference sell',
    'This sub-function is to notify the receiver that the purpose of the message is an instruction to perform a sell, based on data returned in a previous interactive response.' ],
'AI' => [ 'Interactive, modify previous dialogue reservation',
    'This sub-function is to notify the receiver that the purpose of the message is to modify a reservation, made during a previous interactive dialogue.' ],
'AJ' => [ 'Interactive, display voucher template',
    'This sub-function is to notify the receiver that the purpose of the message is to display the template for a voucher.' ],
'AK' => [ 'Interactive, print voucher',
    'This sub-function is to notify the receiver that the purpose of the message is to print a voucher.' ],
'AL' => [ 'Interactive, cancel current dialogue reservation',
    'This sub-function is to notify the receiver that the purpose of the message is to cancel a reservation made during the current interactive dialogue.' ],
'AM' => [ 'Interactive, cancel previous dialogue reservation',
    'This sub-function is to notify the receiver that the purpose of the message is to cancel a reservation made during a previous interactive dialogue.' ],
'AN' => [ 'Interactive, duplicate sell message',
    'This sub-function is to notify the receiver that the message is a duplicate of a previously sent interactive sell message.' ],
'AO' => [ 'Interactive, duplicate modify current dialogue data',
    'This sub-function is to notify the receiver that the message is a duplicate of a previously sent message to modify data in the current interactive dialogue.' ],
'AP' => [ 'Interactive, duplicate modify previous dialogue reservation',
    'This sub-function is to notify the receiver that the message is a duplicate of a previously sent message to modify a reservation made during a previous interactive dialogue.' ],
'AQ' => [ 'Interactive, availability request, multiple suppliers',
    'This sub-function is to notify the receiver that the message is an interactive request for availability which is simultaneously being sent to multiple suppliers.' ],
'AR' => [ 'Interactive, availability request, one specific supplier',
    'This sub-function is to notify the receiver that the message is an interactive request for availability from only one specific supplier.' ],
'AS' => [ 'Interactive, product rules request',
    'This sub-function is to notify the receiver that the message is an interactive request for product rules.' ],
'SECACK' => [ 'Security acknowledgment',
    'This sub-function of the AUTACK message is for the secure acknowledgement of receipt, including the reporting of any associated security violation(s).' ],
'SECAUT' => [ 'Security authentication and/or non-repudiation of origin',
    'This sub-function of the AUTACK message is for secure integrity, authentication and/or non-repudiation of origin.' ],
);
sub get_codes { return \%code_hash; }

1;
