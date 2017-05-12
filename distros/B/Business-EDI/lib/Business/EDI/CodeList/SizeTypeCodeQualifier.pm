package Business::EDI::CodeList::SizeTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {6173;}
my $usage       = 'B';

# 6173  Size type code qualifier                                [B]
# Desc: Code qualifying a type of size.
# Repr: an..3

my %code_hash = (
'1' => [ 'Population size',
    'The size of a population.' ],
'2' => [ 'Sample size',
    'The size of the sample within the population size.' ],
'3' => [ 'Subgroup size',
    'The size of the subgroup within the specific sample size.' ],
);
sub get_codes { return \%code_hash; }

1;
