package Business::EDI::CodeList::FullOrEmptyIndicatorCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {8169;}
my $usage       = 'B';

# 8169  Full or empty indicator code                            [B]
# Desc: Code indicating whether an object is full or empty.
# Repr: an..3

my %code_hash = (
'1' => [ 'More than one quarter volume available',
    'Indicates that there is more than a quarter of the volume available.' ],
'2' => [ 'More than half volume available',
    'Indicates that there is more than a half of the volume available.' ],
'3' => [ 'More than three quarters volume available',
    'Indicates that there is more than three quarters of the volume available.' ],
'4' => [ 'Empty',
    'Indicates that the object is empty.' ],
'5' => [ 'Full',
    'Indicates that the object is full.' ],
'6' => [ 'No volume available',
    'Indicates that there is no space available in the object.' ],
'7' => [ 'Full, mixed consignment',
    'Indicates that the equipment is fully loaded, and includes a number LCL (Less Than Container Load) consignments.' ],
'8' => [ 'Full, single consignment',
    'Indicates that the container is fully loaded with a single FCL (Full Container Load) consignment.' ],
'9' => [ 'Part load',
    'Container represents part of a consignment declared on a single Customs declaration (i.e. the Customs declaration covers more than one container).' ],
'10' => [ 'Part load mixed consignments',
    'Container represents part of the consignment declared on a single Customs declaration with the remainder being in other containers. Other goods, related to other declarations, are also in the container.' ],
'11' => [ 'Single invoiced load',
    'Merchandise within a container/package covered by a single invoice.' ],
'12' => [ 'Multi invoiced load',
    'Merchandise within a container/package covered by more than one invoice.' ],
'13' => [ 'Full load, multiple bills',
    'A container representing a consignment of goods for one consignee with multiple bill of lading numbers.' ],
);
sub get_codes { return \%code_hash; }

1;
