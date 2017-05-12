package Business::EDI::CodeList::PhysicalOrLogicalStateDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7007;}
my $usage       = 'B';

# 7007  Physical or logical state description code              [B]
# Desc: Code specifying a physical or logical state.
# Repr: an..3

my %code_hash = (
'1' => [ 'Split',
    'Separated into multiple units.' ],
'2' => [ 'Missing',
    'Absent or lacking.' ],
'3' => [ 'Wrong identification',
    'The actual identification is different from the given identification.' ],
'4' => [ 'Damaged',
    'In a damaged state.' ],
'5' => [ 'Good condition',
    'In a state of good condition.' ],
'6' => [ 'Wrong product',
    'The product is wrong.' ],
'7' => [ 'On hold',
    'Held, awaiting further action.' ],
'8' => [ 'Proposed',
    'The object is in a proposed state.' ],
'9' => [ 'Accepted',
    'The object is in an accepted state.' ],
'10' => [ 'Scheduled',
    'The object is in a scheduled state.' ],
'11' => [ 'Completed',
    'The object is in a completed state.' ],
'12' => [ 'Rejected',
    'The object is in a rejected state.' ],
'13' => [ 'Postponed',
    'The object is in a postponed state.' ],
'14' => [ 'Cancelled',
    'The object is in a cancelled state.' ],
'15' => [ 'Obsolete',
    'The object is obsolete.' ],
'16' => [ 'Fresh',
    'Retaining the original properties, not impaired by spoilage or preservation.' ],
);
sub get_codes { return \%code_hash; }

1;
