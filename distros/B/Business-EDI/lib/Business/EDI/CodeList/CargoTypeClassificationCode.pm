package Business::EDI::CodeList::CargoTypeClassificationCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7085;}
my $usage       = 'B';

# 7085  Cargo type classification code                          [B]
# Desc: Code specifying the classification of a type of cargo.
# Repr: an..3

my %code_hash = (
'1' => [ 'Documents',
    'Printed, typed or written matter including leaflets, pamphlets, certificates etc., which are not subject to import duties and taxes, restrictions and prohibitions.' ],
'2' => [ 'Low value non-dutiable consignments',
    'Imported consignments/items/goods in respect of which Customs duties and other taxes are waived as they are below a value determined by the Customs administration.' ],
'3' => [ 'Low value dutiable consignments',
    'Imported consignments/items/goods in respect of which Customs duties and other taxes are payable are below a certain amount as determined by the Customs administration.' ],
'4' => [ 'High value consignments',
    'Imported consignments/items/goods which are determined as having a value above a certain amount fixed by the Customs administration, which may or may not attract duties and taxes.' ],
'5' => [ 'Other non-containerized',
    'Non-containerized cargo which cannot be categorized by any of the other nature of cargo code.' ],
'6' => [ 'Vehicles',
    'Vehicles which are not stowed in containers.' ],
'7' => [ 'Roll-on roll-off',
    'Cargo transported or to be transported on roll-on roll- off vessels and which is transportable on its own wheels or stowed on special heavy duty trailers.' ],
'8' => [ 'Palletized',
    'Non-containerized cargo which is palletized.' ],
'9' => [ 'Containerized',
    'Cargo stowed or to be stowed in a container.' ],
'10' => [ 'Breakbulk',
    "Non-containerized cargo stowed in vessels' holds." ],
'11' => [ 'Hazardous cargo',
    'Cargo with dangerous properties, according to appropriate dangerous goods regulations.' ],
'12' => [ 'General cargo',
    'Cargo of a general nature, not otherwise specified.' ],
'13' => [ 'Liquid cargo',
    'Cargo in liquid form.' ],
'14' => [ 'Temperature controlled cargo',
    'Cargo transported under specified temperature conditions.' ],
'15' => [ 'Environmental pollutant cargo',
    'Cargo is an environmental pollutant.' ],
'16' => [ 'Not-hazardous cargo',
    'Cargo which is not hazardous.' ],
'17' => [ 'Diplomatic',
    'Cargo transported under diplomatic conditions.' ],
'18' => [ 'Military',
    'Cargo for military purposes.' ],
'19' => [ 'Obnoxious',
    'Cargo that is objectionable to human senses.' ],
'20' => [ 'Out of gauge',
    'Cargo that has at least one non-standard dimension.' ],
'21' => [ 'Household goods and personal effects',
    'Cargo consisting of household goods and personal effects.' ],
'22' => [ 'Frozen cargo',
    'Cargo of frozen products.' ],
'23' => [ 'Ballast only',
    'No cargo, means of transport is carrying only ballast.' ],
);
sub get_codes { return \%code_hash; }

1;
