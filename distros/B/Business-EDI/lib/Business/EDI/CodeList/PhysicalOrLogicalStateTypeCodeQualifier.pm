package Business::EDI::CodeList::PhysicalOrLogicalStateTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7001;}
my $usage       = 'B';

# 7001  Physical or logical state type code qualifier           [B]
# Desc: Code qualifying the type of physical or logical state.
# Repr: an..3

my %code_hash = (
'1' => [ 'Upon receipt',
    'At the time of receipt.' ],
'2' => [ 'Upon despatch',
    'At the time of despatch.' ],
'3' => [ 'Upon arrival condition',
    'The arrival condition of an object.' ],
'4' => [ 'Life cycle state',
    'The state of an object in its life cycle.' ],
);
sub get_codes { return \%code_hash; }

1;
