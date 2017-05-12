package Business::EDI::CodeList::FormulaSequenceCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9507;}
my $usage       = 'B';

# 9507  Formula sequence code qualifier                         [B]
# Desc: Code giving specific meaning to a formula sequence.
# Repr: an..3

my %code_hash = (
'1' => [ 'Arithmetic operation',
    'An individual arithmetic operation within a formula.' ],
'2' => [ 'Open bracket',
    'An open bracket indicates the beginning of a specific series of arithmetic operations.' ],
'3' => [ 'Close bracket',
    'A close bracket indicates the end of a specific series of arithmetic operations.' ],
'4' => [ 'Disjoint value',
    'A value which is disjoint.' ],
);
sub get_codes { return \%code_hash; }

1;
