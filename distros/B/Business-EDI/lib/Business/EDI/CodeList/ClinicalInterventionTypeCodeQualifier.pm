package Business::EDI::CodeList::ClinicalInterventionTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9441;}
my $usage       = 'B';

# 9441  Clinical intervention type code qualifier               [B]
# Desc: Code qualifying a type of clinical intervention.
# Repr: an..3

my %code_hash = (
'1' => [ 'Drug treatment',
    'Drug treatment.' ],
'2' => [ 'Surgical procedure',
    'Surgical procedure.' ],
'3' => [ 'Investigation',
    'Intervention to procure information.' ],
'4' => [ 'Medical',
    'Intervention related to medical services.' ],
);
sub get_codes { return \%code_hash; }

1;
