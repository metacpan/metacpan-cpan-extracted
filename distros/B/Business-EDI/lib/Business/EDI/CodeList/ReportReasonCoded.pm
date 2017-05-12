package Business::EDI::CodeList::ReportReasonCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0333";}
my $usage       = 'B';

# 0333  Report reason, coded
# Desc: Code identifying the reason for the status or error report.
# Repr: an..3

my %code_hash = (
'1' => [ 'OK response',
    'No further information.' ],
'2' => [ 'Syntax error',
    'Error detected in syntax.' ],
'3' => [ 'Invalid header',
    'Invalid header segment received.' ],
'4' => [ 'Invalid trailer segment',
    'Invalid trailer segment received.' ],
'5' => [ 'Unsupported syntax',
    'Syntax version/release not supported.' ],
'6' => [ 'Unsupported scenario type',
    'Scenario type not supported.' ],
'7' => [ 'Unsupported scenario version',
    'Scenario version/release not supported.' ],
'8' => [ 'Unsupported dialogue type',
    'Dialogue type not supported for this scenario.' ],
'9' => [ 'Unsupported dialogue version',
    'Dialogue type version/release not supported.' ],
'10' => [ 'Unauthorised sender',
    'Sender not authorised.' ],
'11' => [ 'Sender rejected',
    'Sender rejected for administrative reasons.' ],
'12' => [ 'Multiple transactions unsupported',
    'Multiple parallel transactions not supported.' ],
'13' => [ 'Multiple dialogues unsupported',
    'Multiple parallel dialogues not supported.' ],
'14' => [ 'Resources unavailable',
    'Resources unavailable for requested function.' ],
'15' => [ 'Unknown transaction',
    'Referenced transaction does not exist.' ],
'16' => [ 'Unknown dialogue',
    'Referenced dialogue does not exist.' ],
'17' => [ 'Invalid function',
    'Function invalid for current dialogue state.' ],
'18' => [ 'Service unavailable',
    'Requested service is unavailable.' ],
'19' => [ 'Application unavailable',
    'Requested application not available.' ],
'20' => [ 'Time-out',
    'Response not received within expected time.' ],
'21' => [ 'Unable to process interactively',
    'To notify the initiator that a specific request cannot be processed interactively.' ],
'22' => [ 'Correctable application error',
    'To notify the initiator that an application error, that is correctable by the initiator, was made in the request message.' ],
'23' => [ 'Nothing to return',
    'To notify the initiator that there is no information to return in response to an inquiry.' ],
'24' => [ 'Data not accessible',
    'To notify the initiator that the requested information cannot be returned.' ],
'25' => [ 'Non-correctable application error',
    'To notify the initiator that some type of system or processing error was encountered, not related to the data received.' ],
);
sub get_codes { return \%code_hash; }

1;
