package Business::EDI::CodeList::DiagnosisTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9623;}
my $usage       = 'I';

# 9623  Diagnosis type code                                     [I]
# Desc: Code specifying the type of diagnosis.
# Repr: an..3

my %code_hash = (
'1' => [ 'Admitting diagnosis',
    'The type of diagnosis upon admitting.' ],
'2' => [ 'Primary diagnosis',
    'The primary illness or condition.' ],
'3' => [ 'Secondary diagnosis',
    'The secondary illness or condition.' ],
);
sub get_codes { return \%code_hash; }

1;
