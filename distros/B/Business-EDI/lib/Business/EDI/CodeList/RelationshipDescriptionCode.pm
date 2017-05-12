package Business::EDI::CodeList::RelationshipDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9143;}
my $usage       = 'C';

# 9143  Relationship description code                           [C]
# Desc: Code specifying a relationship.
# Repr: an..3

my %code_hash = (
'1' => [ 'Parent',
    'A code to indicate a parent relationship.' ],
'2' => [ 'Child',
    'A code to indicate a child relationship.' ],
'3' => [ 'Peer, internal',
    'A code to indicate an internal peer relationship.' ],
'4' => [ 'Peer, external',
    'A code to indicate an external peer relationship.' ],
'5' => [ 'Finish to start constraint',
    'A code to indicate a finish to start constraint relationship.' ],
'6' => [ 'Start to start constraint',
    'A code to indicate a start to start constraint relationship.' ],
'7' => [ 'Finish to finish constraint',
    'A code to indicate a finish to finish constraint relationship.' ],
'8' => [ 'Start to finish constraint',
    'A code to indicate a start to finish constraint relationship.' ],
'9' => [ 'Owner',
    'A code to indicate an owner relationship.' ],
'10' => [ 'Contact',
    'A code to indicate a contact relationship.' ],
'11' => [ 'Spouse',
    'A code to indicate a spouse relationship.' ],
'12' => [ 'Sibling',
    'A code to indicate the relationship between brothers and/or sisters.' ],
'13' => [ 'Father',
    'A code to indicate a father relationship.' ],
'14' => [ 'Mother',
    'A code to indicate a mother relationship.' ],
'15' => [ 'Neighbour',
    'A code to indicate a neighbour relationship.' ],
'16' => [ 'Friend',
    'A code to indicate a friend relationship.' ],
'17' => [ 'Guardian',
    'A code to indicate a guardian relationship.' ],
'18' => [ 'Connecting to',
    'The specified object connects to the related object.' ],
);
sub get_codes { return \%code_hash; }

1;
