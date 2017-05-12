package Business::EDI::CodeList::ReportFunctionCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0331";}
my $usage       = 'B';

# 0331  Report function, coded
# Desc: Coded value identifying type of status or error report.
# Repr: an..3

my %code_hash = (
'1' => [ 'Information',
    'Non Error information, e.g. acknowledgement that party is still operational.' ],
'2' => [ 'Warning',
    'Warning, e.g. resources getting low.' ],
'3' => [ 'Non-fatal error',
    'Non-fatal error detected by party sending the UIR. Dialogue integrity may be compromised.' ],
'4' => [ 'Abort dialogue',
    'Established dialogue cannot continue.' ],
'5' => [ 'Query status',
    "Request for a status report from other party. Should be answered with a 'Status report' (see code value '6' below)." ],
'6' => [ 'Status report',
    'Reporting status of dialogue as perceived by sending party.' ],
'7' => [ 'Pause dialogue',
    "Advise other party to stop transferring data within this dialogue until a 'Continue dialogue' is received." ],
'8' => [ 'Continue dialogue',
    "Advise that data flow may continue after being 'Paused' (see code value '7' above)." ],
'9' => [ 'Start dialogue reject',
    'Dialogue cannot be initiated.' ],
);
sub get_codes { return \%code_hash; }

1;
