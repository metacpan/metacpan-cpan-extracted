package Business::EDI::CodeList::InventoryMovementDirectionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4501;}
my $usage       = 'B';

# 4501  Inventory movement direction code                       [B]
# Desc: Code specifying the direction of an inventory
# movement.
# Repr: an..3

my %code_hash = (
'1' => [ 'Movement out of inventory',
    'Outgoing goods.' ],
'2' => [ 'Movement into inventory',
    'Incoming goods.' ],
);
sub get_codes { return \%code_hash; }

1;
