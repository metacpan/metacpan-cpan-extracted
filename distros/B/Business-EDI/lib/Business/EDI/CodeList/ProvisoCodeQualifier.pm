package Business::EDI::CodeList::ProvisoCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4071;}
my $usage       = 'B';

# 4071  Proviso code qualifier                                  [B]
# Desc: Code qualifying the proviso.
# Repr: an..3

my %code_hash = (
'1' => [ 'Coverage',
    'Proviso related to a coverage.' ],
'2' => [ 'Deductible',
    'Proviso related to a deductible.' ],
'3' => [ 'Premium',
    'Proviso related to a premium.' ],
);
sub get_codes { return \%code_hash; }

1;
