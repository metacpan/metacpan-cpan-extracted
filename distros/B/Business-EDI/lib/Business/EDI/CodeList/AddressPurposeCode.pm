package Business::EDI::CodeList::AddressPurposeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {3299;}
my $usage       = 'C';

# 3299  Address purpose code                                    [C]
# Desc: Code specifying the purpose of an address.
# Repr: an..3

my %code_hash = (
'1' => [ 'At home',
    'The address is the home address.' ],
'2' => [ 'Contact address',
    'Address where contact may be made.' ],
'3' => [ 'Arrival address',
    'Address of arrival.' ],
'4' => [ 'Departure address',
    'Address of departure.' ],
'5' => [ 'Work address',
    'Address where a person works.' ],
'6' => [ 'Medical care address',
    'Address where medical care is provided.' ],
'7' => [ 'Sample collection address',
    'Address where samples are collected.' ],
'8' => [ 'Patient admitted from',
    'Address from where a patient is admitted.' ],
'9' => [ 'Visit address',
    'The address where a visit takes place.' ],
'10' => [ 'Patient discharged to',
    'Address to where a patient is discharged.' ],
);
sub get_codes { return \%code_hash; }

1;
