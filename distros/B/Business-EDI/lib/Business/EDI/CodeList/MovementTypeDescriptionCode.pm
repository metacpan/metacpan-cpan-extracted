package Business::EDI::CodeList::MovementTypeDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {8335;}
my $usage       = 'B';

# 8335  Movement type description code                          [B]
# Desc: Code specifying a type of movement.
# Repr: an..3

my %code_hash = (
'1' => [ 'Breakbulk',
    'Defines the movement of general cargo not carried in ISO standard containers.' ],
'2' => [ 'LCL/LCL',
    "Defines the movement of cargo packed in and unpacked from containers by the carrier on behalf of the shipper/consignee. 'LCL' means Less than Container Load." ],
'3' => [ 'FCL/FCL',
    "Defines the movement of cargo packed by the shipper or shipper's agent and unpacked by the consignee or consignee's agent. 'FCL' means Full Container Load." ],
'4' => [ 'FCL/LCL',
    "Defines the movement of cargo packed by the shipper or shipper's agent and unpacked by the carrier. 'FCL' means Full Container Load. 'LCL' means Less than Container Load." ],
'5' => [ 'LCL/FCL',
    "Defines the movement of cargo packed by the carrier and unpacked by the consignee or consignee's agent. 'LCL' means Less than Container Load. 'FCL' means Full Load." ],
'6' => [ 'Consolidation',
    'A movement of multiple shipments to a single destination.' ],
'7' => [ 'Parcel post',
    'A movement of material by parcel post.' ],
'8' => [ 'Expedited truck',
    'A movement of material by expedited truck.' ],
'9' => [ 'Consignor determined means',
    'A movement of material by the means determined by the consignor.' ],
'10' => [ 'Private parcel service',
    'A movement of material by a private parcel service.' ],
'11' => [ 'House to house',
    'Cargo packed in a unit by the shipper at point of origin and unpacked by consignee at final destination.' ],
'12' => [ 'House to terminal',
    "Cargo packed in a unit by the shipper at point of origin and unpacked at the carrier's inland facility between the ship's point of discharge and the final destination." ],
'13' => [ 'House to pier',
    "Cargo packed in a unit by the shipper at point of origin and unpacked by carrier at ship's point of discharge (pier)." ],
'14' => [ 'Air charter',
    'A movement of material by chartered aircraft.' ],
'15' => [ 'Air express',
    'A movement of material by air express service.' ],
'16' => [ 'Geographic grouped transport',
    'A movement of material from multiple origins to a single destination utilizing a single carrier and a single freight bill.' ],
'17' => [ 'Less than truck load',
    'A movement of material on a truck that is not full.' ],
'18' => [ 'Pooled piggyback',
    'A movement of material by a trailer on a railcar.' ],
'19' => [ 'Consignee transportation provided',
    'A movement of material transported by the consignee.' ],
'20' => [ 'Rail',
    'A movement of material to the consignee via rail.' ],
'21' => [ 'Terminal to house',
    "Cargo packed in a unit at a carrier's inland facility between point of origin and the ship's point of loading and unpacked by consignee at the final destination." ],
'22' => [ 'Terminal to terminal',
    "Cargo packed in a unit at a carrier's inland facility between point of origin and the ship's point of loading and unpacked at a carrier's inland facility between ship's point of discharge and final destination." ],
'23' => [ 'Terminal to pier',
    "Cargo packed in a unit at a carrier's inland facility between point of origin and ship's point of loading and unpacked by carrier at ship's point of discharge (pier)." ],
'31' => [ 'Pier to house',
    "Cargo packed in a unit at ship's point of loading and unpacked by consignee at final destination." ],
'32' => [ 'Pier to terminal',
    "Cargo packed in a unit at ship's point of loading and unpacked at a carrier's inland facility between ship's point of discharge and final destination." ],
'33' => [ 'Pier to pier',
    "Cargo packed in a unit at ship's point of loading and unpacked by carrier at ship's point of discharge (pier)." ],
'41' => [ 'Station to station',
    'The consignment is moving from one container freight station to another container freight station.' ],
'42' => [ 'House to warehouse',
    'The consignment is moving from the premises of the shipper to a warehouse.' ],
'43' => [ 'Warehouse to house',
    'The consignment is moving from a warehouse to the premises of the consignee.' ],
'44' => [ 'Station to house',
    'The cargo is moving from a container freight station to the premises of the consignee.' ],
'45' => [ 'Geographic grouped transport, multiple origins, multiple',
    'destinations A movement of material from multiple origins to multiple destinations using a single carrier and a single freight bill.' ],
'46' => [ 'Geographic grouped transport, multiple origins, single',
    'destination A movement of material from multiple origins to a single destination utilizing a single carrier and a single freight bill.' ],
'47' => [ 'Geographic receiving',
    'A collection of shipments that involve a single origin, multiple destinations, and a single trailer, and are paid under a single freight bill.' ],
);
sub get_codes { return \%code_hash; }

1;
