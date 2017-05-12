package Business::EDI::CodeList::FacilityTypeDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9039;}
my $usage       = 'I';

# 9039  Facility type description code                          [I]
# Desc: Code specifying the facility type.
# Repr: an..3

my %code_hash = (
'1' => [ 'Movie',
    'Movie viewing is available.' ],
'2' => [ 'Telephone',
    'Telephone service is available.' ],
'3' => [ 'Telex',
    'Telex service is available.' ],
'4' => [ 'Audio programming',
    'Audio programming is available.' ],
'5' => [ 'Television',
    'Television sets are available.' ],
'6' => [ 'Reservation booking service',
    'Reservation booking service is available.' ],
'7' => [ 'Duty free sales',
    'Duty free sales are available.' ],
'8' => [ 'Smoking',
    'The facility permits smoking.' ],
'9' => [ 'Non-smoking',
    'The facility is non-smoking.' ],
);
sub get_codes { return \%code_hash; }

1;
