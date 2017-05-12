package Business::EDI::CodeList::ClinicalInterventionDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9437;}
my $usage       = 'B';

# 9437  Clinical intervention description code                  [B]
# Desc: Code specifying a clinical intervention.
# Repr: an..17

my %code_hash = (
'1' => [ 'Full disability certificate issue',
    'A clinical intervention to certify that a person is completely unable to work for medical reasons.' ],
'2' => [ 'Partial disability certificate issue',
    'A clinical intervention to certify that a person is partially unable to work for medical reasons.' ],
);
sub get_codes { return \%code_hash; }

1;
