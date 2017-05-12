package Business::EDI::CodeList::EquipmentStatusCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {8249;}
my $usage       = 'B';

# 8249  Equipment status code                                   [B]
# Desc: Code specifying the status of equipment.
# Repr: an..3

my %code_hash = (
'1' => [ 'Continental',
    'The equipment is or will be moving across a continent on an intermodal or multimodal basis.' ],
'2' => [ 'Export',
    'Transport equipment to be exported on a marine vessel.' ],
'3' => [ 'Import',
    'Transport equipment to be imported on a marine vessel.' ],
'4' => [ 'Remain on board',
    'Transport equipment arriving on a marine vessel is to remain on board.' ],
'5' => [ 'Shifter',
    'Transport equipment is to be shifted from one stowage location on a marine vessel to another on the same vessel.' ],
'6' => [ 'Transhipment',
    'Transport equipment is to be transferred from one marine vessel to another.' ],
'7' => [ 'Shortlanded',
    'Transport equipment notified to arrive which did not arrive on the means of transport.' ],
'8' => [ 'Overlanded',
    'Transport equipment not notified to arrive but which did arrive on the means of transport.' ],
'9' => [ 'Domestic',
    'Transport equipment is used in domestic service.' ],
'10' => [ 'Positioning',
    'Equipment is being transported for positioning purposes.' ],
'11' => [ 'Delivery',
    'Equipment is being delivered.' ],
'12' => [ 'Redelivery',
    'Equipment is being redelivered.' ],
'13' => [ 'Repair',
    'The equipment is for repair.' ],
'14' => [ 'Reloader',
    'Transport equipment to be discharged and subsequently reloaded on the same means of transport but in a different stowage location.' ],
'15' => [ 'Returned',
    'The equipment is returned.' ],
'16' => [ 'Dropped off',
    'The equipment is dropped off.' ],
'17' => [ 'Cross terminal transshipment',
    'The transport equipment that is unloaded will be loaded in another vessel at another terminal in the same port.' ],
'18' => [ 'Booking confirmed',
    'Notification of the confirmation of booking of a transport equipment.' ],
'19' => [ 'Inspected at terminal gate',
    'Notification that a transport equipment has undergone a terminal gate inspection.' ],
'20' => [ 'Arrived at offloading location',
    'Notification that a transport equipment arrived at the offloading location.' ],
'21' => [ 'Departed from loading location.',
    'Notification that a transport equipment departed from the loading location.' ],
'22' => [ 'Loaded',
    'Notification that a transport equipment has been loaded.' ],
'23' => [ 'Unloaded',
    'Notification that a transport equipment has been unloaded.' ],
'24' => [ 'Intra-terminal movement',
    'Notification that a transport equipment has been subject to an intra-terminal movement.' ],
'25' => [ 'Stuffing ordered',
    'Notification that a transport equipment has been ordered to be stuffed.' ],
'26' => [ 'Stripping ordered',
    'Notification that a transport equipment has been ordered to be stripped.' ],
'27' => [ 'Stuffing confirmed',
    'Notification that a transport equipment has been confirmed as stuffed.' ],
'28' => [ 'Stripping confirmed',
    'Notification that a transport equipment has been confirmed as stripped.' ],
'29' => [ 'Sent for heavy repair',
    'Notification that a transport equipment has been sent for heavy repair.' ],
);
sub get_codes { return \%code_hash; }

1;
