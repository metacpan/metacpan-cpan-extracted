package Business::EDI::CodeList::InventoryTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7491;}
my $usage       = 'B';

# 7491  Inventory type code                                     [B]
# Desc: Code specifying a type of inventory.
# Repr: an..3

my %code_hash = (
'1' => [ 'Accepted product inventory',
    'Inventory of products accepted by control of incoming products.' ],
'2' => [ 'Damaged product inventory',
    'Inventory of damaged products.' ],
'3' => [ 'Bonded inventory',
    'Inventory of products bonded for customs reasons.' ],
'4' => [ 'Reserved inventory',
    'Inventory related to reserved products.' ],
'5' => [ 'Awaiting inspection inventory',
    'Inventory of products awaiting quality inspection.' ],
);
sub get_codes { return \%code_hash; }

1;
