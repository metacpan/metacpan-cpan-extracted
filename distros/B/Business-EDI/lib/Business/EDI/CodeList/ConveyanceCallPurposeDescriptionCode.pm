package Business::EDI::CodeList::ConveyanceCallPurposeDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {8025;}
my $usage       = 'B';

# 8025  Conveyance call purpose description code                [B]
# Desc: Code specifying the purpose of the conveyance call.
# Repr: an..3

my %code_hash = (
'1' => [ 'Cargo operations',
    'Discharging and/or loading of cargo.' ],
'2' => [ 'Passenger movement',
    'Embarking and/or disembarking of passengers.' ],
'3' => [ 'Taking bunkers',
    'Taking bunker (refuelling).' ],
'4' => [ 'Changing crew',
    'Changing crew member(s).' ],
'5' => [ 'Goodwill visit',
    'Friendly visit.' ],
'6' => [ 'Taking supplies',
    'Taking supplies.' ],
'7' => [ 'Repair',
    'To effect repair.' ],
'8' => [ 'Laid-up',
    'Inactive service.' ],
'9' => [ 'Awaiting orders',
    'Awaiting job order.' ],
'10' => [ 'Miscellaneous',
    'Miscellaneous purpose of call.' ],
'11' => [ 'Crew movement',
    'Embarking and/or disembarking of crews.' ],
'12' => [ 'Cruise, leisure and recreation',
    'To visit a port for cruise, leisure and recreation.' ],
'13' => [ 'Under government order',
    'This is a visit to a port which has been ordered by government.' ],
'14' => [ 'Quarantine inspection',
    'To have a quarantine inspection.' ],
'15' => [ 'Refuge',
    'To seek protection against something unpleasant and/or threatening such as bad weather or danger.' ],
'16' => [ 'Unloading cargo',
    'Discharging of cargo from the means of transport.' ],
'17' => [ 'Loading cargo',
    'Loading of cargo onto the means of transport.' ],
'18' => [ 'Repair in dry dock',
    'Vessel to undergo repair in a dry dock.' ],
'19' => [ 'Repair in wet dock',
    'Repair of a vessel in a dock without removing the surrounding water.' ],
'20' => [ 'Cargo tank cleaning',
    'Cargo tanks of the means of transport will be cleaned.' ],
'21' => [ 'Means of transport customs clearance',
    'Means of transport will be customs cleared.' ],
'22' => [ 'De-gassing',
    'Means of transport will be de-gassed.' ],
'23' => [ 'Waste disposal',
    'Means of transport will dispose of her waste.' ],
);
sub get_codes { return \%code_hash; }

1;
