package Business::EDI::CodeList::SampleStateCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7045;}
my $usage       = 'B';

# 7045  Sample state code                                       [B]
# Desc: Code specifying the state of a sample.
# Repr: an..3

my %code_hash = (
'1' => [ 'Round',
    'Sample has a round shape.' ],
'2' => [ 'Rectangular',
    'Sample has a rectangular shape.' ],
'3' => [ 'Turned',
    'Sample was turned when tested.' ],
'4' => [ 'Forged',
    'Sample was forged when tested.' ],
'5' => [ 'Tinned',
    'Sample was tinned when tested.' ],
'6' => [ 'Prismatic',
    'Sample has a prism shape.' ],
'7' => [ 'Cylindric',
    'Sample has a cylinder shape.' ],
);
sub get_codes { return \%code_hash; }

1;
