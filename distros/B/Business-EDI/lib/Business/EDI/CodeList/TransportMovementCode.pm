package Business::EDI::CodeList::TransportMovementCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {8323;}
my $usage       = 'B';

# 8323  Transport movement code                                 [B]
# Desc: Code specifying the transport movement.
# Repr: an..3

my %code_hash = (
'1' => [ 'Export',
    'The transport movement is to export the goods from the country.' ],
'2' => [ 'Import',
    'The transport movement is to import the goods into the country.' ],
'3' => [ 'Transit',
    'The cargo is moving in transit through a country and will not become part of the commerce of that country.' ],
'4' => [ 'Relay',
    'The cargo is being moved by more than one transport means in succession under the responsibility of the same carrier.' ],
'5' => [ 'Transshipment',
    'The cargo is being moved by more than one transport means in succession.' ],
);
sub get_codes { return \%code_hash; }

1;
