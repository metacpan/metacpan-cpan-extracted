package Business::EDI::CodeList::AttendanceTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9443;}
my $usage       = 'B';

# 9443  Attendance type code qualifier                          [B]
# Desc: Code qualifying a type of attendance.
# Repr: an..3

my %code_hash = (
'1' => [ 'Hospital stay',
    'Hospital stay from admission into hospital to discharge from hospital.' ],
'2' => [ 'Designated rehabilitation unit attendance',
    'Attendance at a designated rehabilitation care unit.' ],
'3' => [ 'Other',
    'Attendance other than those specifically defined.' ],
'4' => [ 'Non-acute care attendance',
    'Attendance for non-acute care.' ],
'5' => [ 'Designated palliative program attendance',
    'Attendance in a designated palliative program.' ],
'6' => [ 'Designated rehabilitation program attendance',
    'Attendance in a designated rehabilitation program.' ],
'7' => [ 'Acute care attendance',
    'Attendance for acute care.' ],
'8' => [ 'Designated palliative unit attendance',
    'Attendance at a designated palliative unit.' ],
);
sub get_codes { return \%code_hash; }

1;
