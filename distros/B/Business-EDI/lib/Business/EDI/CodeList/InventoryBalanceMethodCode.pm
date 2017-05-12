package Business::EDI::CodeList::InventoryBalanceMethodCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4503;}
my $usage       = 'B';

# 4503  Inventory balance method code                           [B]
# Desc: Code specifying the method used to establish an
# inventory balance.
# Repr: an..3

my %code_hash = (
'1' => [ 'Book-keeping inventory balance',
    'An inventory balance resulting from the book-keeping.' ],
'2' => [ 'Formal inventory balance',
    'An inventory balance in accordance with the formal inventory procedure.' ],
'3' => [ 'Interim inventory balance',
    'An inventory balance resulting from an interim counting.' ],
);
sub get_codes { return \%code_hash; }

1;
