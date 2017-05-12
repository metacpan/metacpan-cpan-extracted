package Business::EDI::CodeList::SurfaceOrLayerCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7383;}
my $usage       = 'C';

# 7383  Surface or layer code                                   [C]
# Desc: Code specifying the surface or layer of an object.
# Repr: an..3

my %code_hash = (
'1S' => [ 'Side one',
    'The location is side one.' ],
'2S' => [ 'Side two',
    'The location is side two.' ],
'AA' => [ 'On surface',
    'To indicate that the entity being specified is on the surface.' ],
'AB' => [ 'Off surface',
    'To indicate that the entity being specified is off the surface.' ],
'AC' => [ 'Soluble',
    'Specifies that the surface/layer/position being described is the soluble portion.' ],
'AD' => [ 'Opposite corners',
    'The surface or layer of the product being described is the opposite corners.' ],
'AE' => [ 'Corner Diagonals',
    'The surface or layer of the product being described are the corner diagonals.' ],
'AF' => [ 'Port',
    'The left-hand side (looking forward) of a ship, boat or aircraft.' ],
'AG' => [ 'Starboard',
    'The right-hand side (looking forward) of a ship, boat or aircraft.' ],
'AH' => [ 'Tooth facial surface',
    'Surface of a tooth directed toward the face and opposite the lingual surface.' ],
'AI' => [ 'Tooth incisal surface',
    'Surface of the tooth relating to the cutting edge of the anterior teeth, incisors or canines.' ],
'AJ' => [ 'Tooth distal surface',
    'Surface of the tooth toward the back of the dental arch, or away from the midline.' ],
'AK' => [ 'Tooth buccal surface',
    'Surface of the tooth pertaining to or around the cheek.' ],
'AL' => [ 'Tooth occlusal surface',
    'Surface of the tooth pertaining to the masticating surfaces of the posterior teeth.' ],
'AM' => [ 'Tooth lingual surface',
    'Surface of the tooth pertaining to or around the tongue.' ],
'AN' => [ 'Tooth mesial surface',
    'Surface of the tooth toward the midline of the dental arch.' ],
'BC' => [ 'Back of cab',
    'The location is at the back of the cab.' ],
'BS' => [ 'Both sides',
    'The location is both sides.' ],
'BT' => [ 'Bottom',
    'The location is on the bottom.' ],
'DF' => [ 'Dual fuel tank positions',
    'The location is in the dual fuel tank positions.' ],
'FR' => [ 'Front',
    'The location is in the front.' ],
'IN' => [ 'Inside',
    'The location is in the inside.' ],
'LE' => [ 'Left',
    'The location is on the left.' ],
'OA' => [ 'Overall',
    'The location is overall.' ],
'OS' => [ 'One side',
    'The location is on one side.' ],
'OT' => [ 'Outside',
    'The location is on the outside.' ],
'RI' => [ 'Right',
    'The location is on the right.' ],
'RR' => [ 'Rear',
    'The location is in the rear.' ],
'ST' => [ 'Spare tyre position',
    'The location is the spare tyre position.' ],
'TB' => [ 'Tank bottom',
    'The location is at the tank bottom.' ],
'TP' => [ 'Top',
    'The location is on the top.' ],
'TS' => [ 'Two sides',
    'The location is on two sides.' ],
'UC' => [ 'Under cab',
    'The location is under the cab.' ],
);
sub get_codes { return \%code_hash; }

1;
