package Business::EDI::CodeList::PriceMultiplierTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {5393;}
my $usage       = 'B';

# 5393  Price multiplier type code qualifier                    [B]
# Desc: Code qualifying the type of price multiplier.
# Repr: an..3

my %code_hash = (
'A' => [ 'Price adjustment coefficient',
    'Coefficient to be used in the price adjustment formula to calculate the revaluated price.' ],
'B' => [ 'Escalation coefficient',
    'Coefficient to be used in the escalation formula to calculate the actual price.' ],
'C' => [ 'Timesing factor',
    'Factor to be used in calculating the number of times a particular piece of work is repeated.' ],
'CSD' => [ 'Cost markup multiplier - original cost',
    'Code specifying the cost mark-up multiplier at original cost.' ],
'CSR' => [ 'Cost markup multiplier - retail cost',
    'Code specifying the cost mark-up multiplier at retail cost.' ],
'DIS' => [ 'Discount multiplier',
    'Code specifying the discount multiplier.' ],
'SEL' => [ 'Selling multiplier',
    'Code specifying the selling multiplier.' ],
);
sub get_codes { return \%code_hash; }

1;
