package Business::EDI::CodeList::RateTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {5419;}
my $usage       = 'B';

# 5419  Rate type code qualifier                                [B]
# Desc: Code qualifying the type of rate.
# Repr: an..3

my %code_hash = (
'1' => [ 'Allowance rate',
    'Code specifying the allowance rate.' ],
'2' => [ 'Charge rate',
    'Code specifying the charge rate.' ],
'3' => [ 'Actual versus calculated price difference rate',
    'Difference rate of actual price and calculated price.' ],
'4' => [ 'Standard labour rate',
    'Labour rate for a normal working day. Synonym: Straight time.' ],
'5' => [ 'Overtime labour rate',
    'Labour rate for overtime.' ],
'6' => [ 'Premium labour rate',
    'Labour rate for premium time.' ],
'7' => [ 'Calculation rate',
    'To identify a rate which is to be applied in a calculation.' ],
'8' => [ 'Coefficient',
    'The coefficient which is to be used as a multiplier.' ],
'9' => [ 'Indemnity rate',
    'To specify the rate of an indemnity.' ],
'10' => [ 'Guarantee reserved calculation rate',
    'To specify the rate that has been used to calculate the monetary amount reserved as a guarantee.' ],
'11' => [ 'Waiting time indemnity rate',
    'To specify the rate of an indemnity for waiting.' ],
'ZZZ' => [ 'Mutually defined',
    'The rate type is mutually agreed by the interchanging parties.' ],
);
sub get_codes { return \%code_hash; }

1;
