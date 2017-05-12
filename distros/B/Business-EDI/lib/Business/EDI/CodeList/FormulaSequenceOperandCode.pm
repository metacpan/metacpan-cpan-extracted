package Business::EDI::CodeList::FormulaSequenceOperandCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9509;}
my $usage       = 'B';

# 9509  Formula sequence operand code                           [B]
# Desc: Code specifying a specific type of operand within a
# formula sequence.
# Repr: an..17

my %code_hash = (
'1' => [ 'Plus',
    'The formula sequence operand is an addition.' ],
'2' => [ 'Minus',
    'The formula sequence operand is a subtraction.' ],
'3' => [ 'Multiply',
    'The formula sequence operand is a multiplication.' ],
'4' => [ 'Divide',
    'The formula sequence operand is a division.' ],
'5' => [ 'Exponent',
    'The formula sequence operand is an exponent.' ],
);
sub get_codes { return \%code_hash; }

1;
