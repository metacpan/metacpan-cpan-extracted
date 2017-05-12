package Business::EDI::CodeList::HierarchicalStructureRelationshipCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7171;}
my $usage       = 'B';

# 7171  Hierarchical structure relationship code                [B]
# Desc: Code specifying the relationship between the
# hierarchical object and an identified object.
# Repr: an..3

my %code_hash = (
'1' => [ 'Parent',
    'Identifies the immediate higher levelled hierarchy stage.' ],
'2' => [ 'Child',
    'Identifies the immediate lower levelled hierarchy stage.' ],
'3' => [ 'Message',
    'Message level.' ],
'4' => [ 'Segment',
    'Segment level.' ],
'5' => [ 'Composite data element',
    'Composite data element level.' ],
'6' => [ 'Simple data element',
    'Simple data element level.' ],
'7' => [ 'Code',
    'Code level.' ],
);
sub get_codes { return \%code_hash; }

1;
