package Business::EDI::CodeList::SampleDirectionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7047;}
my $usage       = 'B';

# 7047  Sample direction code                                   [B]
# Desc: Code specifying the direction in which a sample was
# taken.
# Repr: an..3

my %code_hash = (
'1' => [ 'Longitudinal',
    'Sample was taken in a lengthways direction.' ],
'2' => [ 'Transverse',
    'Sample was taken in a crosswise direction.' ],
'3' => [ 'Radial',
    'Sample was taken originating from the centre outward.' ],
'4' => [ 'Axial',
    'A sample was taken along a line which divides a regular figure symmetrically.' ],
'5' => [ 'Thickness',
    'In the direction of the thickness of the specimen.' ],
'6' => [ 'Diagonal',
    'Sample taken in the diagonal direction.' ],
);
sub get_codes { return \%code_hash; }

1;
