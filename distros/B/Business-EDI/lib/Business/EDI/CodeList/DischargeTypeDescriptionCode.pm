package Business::EDI::CodeList::DischargeTypeDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9447;}
my $usage       = 'C';

# 9447  Discharge type description code                         [C]
# Desc: Code specifying the type of discharge.
# Repr: an..3

my %code_hash = (
'1' => [ 'To acute care facility',
    'Discharge and/or transfer to an acute care facility.' ],
'2' => [ 'To nursing home facility',
    'Discharge and/or transfer to a nursing home facility.' ],
'3' => [ 'To psychiatric facility',
    'Discharge and/or transfer to a psychiatric facility.' ],
'4' => [ 'Statistical discharge',
    'Discharge for statistical purposes.' ],
);
sub get_codes { return \%code_hash; }

1;
