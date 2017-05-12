package Business::EDI::CodeList::PriorityTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4035;}
my $usage       = 'B';

# 4035  Priority type code qualifier                            [B]
# Desc: Code qualifying the type of priority.
# Repr: an..3

my %code_hash = (
'1' => [ 'Location priority',
    'The priority relates to the location.' ],
'2' => [ 'Salary priority',
    'The priority relates to the salary.' ],
'3' => [ 'Occupation priority',
    'The priority relates to the occupation.' ],
'4' => [ 'Performing priority',
    'Assigned priority in performing a task.' ],
'5' => [ 'Reporting priority',
    'Assigned priority in reporting an event.' ],
'6' => [ 'Delivery priority',
    'The delivery priority of an object.' ],
'7' => [ 'Requested priority',
    'The priority that is requested.' ],
'8' => [ 'Allocated priority',
    'The priority that is allocated.' ],
'9' => [ 'Prescription dispensing priority',
    'Assigned priority in dispensing a prescription.' ],
'10' => [ 'Disconnectability',
    'Priority for when an installation can be disconnected.' ],
);
sub get_codes { return \%code_hash; }

1;
