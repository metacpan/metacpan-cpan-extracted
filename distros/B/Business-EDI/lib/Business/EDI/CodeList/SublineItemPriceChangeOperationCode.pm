package Business::EDI::CodeList::SublineItemPriceChangeOperationCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {5213;}
my $usage       = 'C';

# 5213  Sub-line item price change operation code               [C]
# Desc: Code specifying the price change operation for a sub-
# line item.
# Repr: an..3

my %code_hash = (
'A' => [ 'Added to the baseline item unit price',
    'Price is to be added to the base line unit price.' ],
'I' => [ 'Included in the baseline item unit price',
    'Price is included in the base line unit price.' ],
'S' => [ 'Subtracted from the baseline item unit price',
    'Price is to be subtracted from the base line unit price.' ],
);
sub get_codes { return \%code_hash; }

1;
