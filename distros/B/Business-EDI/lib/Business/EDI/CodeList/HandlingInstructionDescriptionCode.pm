package Business::EDI::CodeList::HandlingInstructionDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4079;}
my $usage       = 'B';

# 4079  Handling instruction description code                   [B]
# Desc: Code specifying a handling instruction.
# Repr: an..3

my %code_hash = (
'1' => [ 'Heat sensitive',
    'The object is heat sensitive.' ],
'2' => [ 'Store in dry environment',
    'The object must be stored in dry environment.' ],
'3' => [ 'Stacked',
    'The identified item is, or can be stacked.' ],
'4' => [ 'Mooring to be arranged',
    'Request to arrange boatmen to (de)moor the vessel at the berth.' ],
'5' => [ 'Mooring arranged',
    'Information that the boatmen to (de)moor the vessel at the berth are already arranged.' ],
'6' => [ 'Pilotage to be arranged',
    'Request to arrange the pilotage for the vessel.' ],
'7' => [ 'Pilotage arranged',
    'Information that pilotage for the vessel is already arranged.' ],
'8' => [ 'Berth towage to be arranged',
    'Request to arrange the towage for the vessel to/from the berth in the port.' ],
'9' => [ 'Disposal of waste to be arranged',
    'Request to arrange the disposal of waste.' ],
'10' => [ 'Transshipment to be arranged',
    'The consignment has to be transshipped.' ],
);
sub get_codes { return \%code_hash; }

1;
