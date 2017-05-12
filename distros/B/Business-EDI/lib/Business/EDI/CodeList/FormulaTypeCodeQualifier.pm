package Business::EDI::CodeList::FormulaTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9501;}
my $usage       = 'B';

# 9501  Formula type code qualifier                             [B]
# Desc: Code qualifying the type of formula.
# Repr: an..3

my %code_hash = (
'1' => [ 'Order price revision',
    'The formula which enables the revision of a price from the date of order through to the date of delivery.' ],
'2' => [ 'Penalty payment',
    'The formula for the calculation of a penalty payment.' ],
'3' => [ 'Coefficient',
    'The formula for a coefficient calculation.' ],
'4' => [ 'Catalogue adjustment',
    'The formula to adjust a catalogue.' ],
'5' => [ 'Ceiling amount',
    'The formula for the calculation of a ceiling amount.' ],
'6' => [ 'Provisional instalment payment',
    'The formula for the calculation of a provisional instalment.' ],
'7' => [ 'Final instalment payment',
    'The formula for the calculation of a final instalment payment.' ],
'8' => [ 'Bonus payment',
    'The formula for the calculation of a bonus payment.' ],
'9' => [ 'Offer price revision',
    'The formula which enables the revision of a price from the date of offer through to the date of acceptance or award.' ],
'10' => [ 'Adjustment',
    'The formula for the calculation of an adjustment.' ],
'11' => [ 'Non-revisable instalment payment',
    'The formula for the calculation of an instalment payment that cannot be revised.' ],
);
sub get_codes { return \%code_hash; }

1;
