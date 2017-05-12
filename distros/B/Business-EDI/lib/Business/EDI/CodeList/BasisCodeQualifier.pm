package Business::EDI::CodeList::BasisCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9045;}
my $usage       = 'B';

# 9045  Basis code qualifier                                    [B]
# Desc: Code qualifying the basis.
# Repr: an..3

my %code_hash = (
'1' => [ 'Coverage',
    'Basis for a coverage.' ],
'2' => [ 'Deductible',
    'Basis for a deductible.' ],
'3' => [ 'Premium',
    'Basis for a premium.' ],
);
sub get_codes { return \%code_hash; }

1;
