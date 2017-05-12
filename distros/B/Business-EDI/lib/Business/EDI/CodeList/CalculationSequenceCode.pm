package Business::EDI::CodeList::CalculationSequenceCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {1227;}
my $usage       = 'B';

# 1227  Calculation sequence code                               [B]
# Desc: Code specifying a calculation sequence.
# Repr: an..3

my %code_hash = (
'1' => [ 'First step of calculation',
    'Code specifying the first step of a calculation.' ],
'2' => [ 'Second step of calculation',
    'Code specifying the second step of a calculation.' ],
'3' => [ 'Third step of calculation',
    'Code specifying the third step of a calculation.' ],
'4' => [ 'Fourth step of calculation',
    'Code specifying the fourth step of a calculation.' ],
'5' => [ 'Fifth step of calculation',
    'Code specifying the fifth step of a calculation.' ],
'6' => [ 'Sixth step of calculation',
    'Code specifying the sixth step of a calculation.' ],
'7' => [ 'Seventh step of calculation',
    'Code specifying the seventh step of a calculation.' ],
'8' => [ 'Eighth step of calculation',
    'Code specifying the eighth step of a calculation.' ],
'9' => [ 'Ninth step of calculation',
    'Code specifying the ninth step of a calculation.' ],
);
sub get_codes { return \%code_hash; }

1;
