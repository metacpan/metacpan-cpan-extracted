package Business::EDI::CodeList::InventoryMovementReasonCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4499;}
my $usage       = 'B';

# 4499  Inventory movement reason code                          [B]
# Desc: Code specifying the reason for an inventory movement.
# Repr: an..3

my %code_hash = (
'1' => [ 'Reception',
    'Goods received at warehouse from another party or warehouse.' ],
'2' => [ 'Delivery',
    'Goods which have been delivered from the inventory to another party or warehouse.' ],
'3' => [ 'Scrapped parts',
    'Adjustment due to scrapped parts.' ],
'4' => [ 'Difference',
    'The difference between the inventory, as physically counted, and the inventory recorded by the system.' ],
'5' => [ 'Property transfer within warehouse',
    'An inventory movement issued when goods are moved (physically or logically) from one owner to another, whenever inventories are held in account of several owners of the same product within the same warehouse.' ],
'6' => [ 'Inventory recycling',
    'This inventory movement is due to recycling of goods. For instance, defective goods have been repaired and are put back to the available inventory.' ],
'7' => [ 'Reversal of previous movement',
    'This inventory movement is issued to cancel a previously processed movement.' ],
'8' => [ 'Defects (technical)',
    'This inventory movement corresponds to parts with technical defect.' ],
'9' => [ 'Commercial',
    'The inventory movement has been issued for commercial reasons.' ],
'10' => [ 'Conversion',
    'The inventory movement is due to conversion of goods.' ],
'11' => [ 'Consumption',
    'The inventory movement corresponds to goods taken out of consigned inventory for consumption.' ],
);
sub get_codes { return \%code_hash; }

1;
