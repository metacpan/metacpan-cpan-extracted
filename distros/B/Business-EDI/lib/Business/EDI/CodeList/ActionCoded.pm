package Business::EDI::CodeList::ActionCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0083";}
my $usage       = 'B';

# 0083  Action, coded
# Desc: A code indicating acknowledgement, or rejection (the action
# taken) of a subject interchange, or part of the subject
# interchange, or indication of interchange receipt.
# Repr: an..3

my %code_hash = (
'4' => [ 'This level and all lower levels rejected',
    'The corresponding referenced-level and all its lower referenced-levels are rejected. One or more errors are reported at this reporting-level or a lower reporting- level.' ],
'7' => [ 'This level acknowledged and all lower levels acknowledged if',
     ],
'not' => [ 'explicitly rejected',
    'The corresponding referenced-level is acknowledged. All messages, packages, or groups at the lower referenced- levels are acknowledged except those explicitly reported as rejected at their reporting-level in this CONTRL message.' ],
'8' => [ 'Interchange received',
    'Indication of interchange receipt.' ],
);
sub get_codes { return \%code_hash; }

1;
