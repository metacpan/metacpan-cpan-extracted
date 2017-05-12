package Business::EDI::CodeList::StructureComponentFunctionCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7497;}
my $usage       = 'B';

# 7497  Structure component function code qualifier             [B]
# Desc: Code qualifying the function of a structure component.
# Repr: an..3

my %code_hash = (
'1' => [ 'Array time dimension',
    'A time dimension of an array.' ],
'2' => [ 'Value list',
    'A coded or non coded list of values.' ],
'3' => [ 'Array cell',
    'Cell of an array.' ],
'4' => [ 'Array dimension',
    'Dimension of an array.' ],
'5' => [ 'Tree structure',
    'A tree structure containing hierarchical levels.' ],
'6' => [ 'Tree structure link',
    'A link between two related tree structures.' ],
'7' => [ 'Tree structure level',
    'A hierarchical level of a tree structure.' ],
'8' => [ 'Tree structure level link.',
    'A link between two related hierarchical levels of a tree structure.' ],
'9' => [ 'Structure item',
    'An item in a structure.' ],
'10' => [ 'Structure item link',
    'A link between two related items in a structure.' ],
'11' => [ 'Statistical time series indicator',
    'To specify a component function as a statistical time series indicator.' ],
'12' => [ 'Attribute',
    'To specify a component function as an attribute.' ],
);
sub get_codes { return \%code_hash; }

1;
