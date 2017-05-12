package Business::EDI::CodeList::TransitDirectionIndicatorCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {8101;}
my $usage       = 'B';

# 8101  Transit direction indicator code                        [B]
# Desc: Code specifying the direction of transport.
# Repr: an..3

my %code_hash = (
'BS' => [ 'Buyer to seller',
    'The transport from the buyer to the seller.' ],
'SB' => [ 'Seller to buyer',
    'The transport from the seller to the buyer.' ],
'SC' => [ 'Subcontractor to seller',
    'The transport from the subcontractor to the seller.' ],
'SD' => [ 'Seller to drop ship designated location',
    'The transport from the seller to the drop ship designated location.' ],
'SF' => [ 'Seller to freight forwarder',
    'The transport from the seller to the freight forwarder.' ],
'SS' => [ 'Seller to subcontractor',
    'The transport from the seller to the subcontractor.' ],
'ST' => [ 'Mother vessel to lighter',
    'Cargo is transferred from the main carriage or mother vessel to a lighter.' ],
'SU' => [ 'Lighter to mother vessel',
    'Cargo is transferred from the lighter vessel to a main carriage or mother vessel.' ],
'ZZZ' => [ 'Mutually defined',
    'A code assigned within a code list to be used on an interim basis and as defined among trading partners until a precise code can be assigned to the code list.' ],
);
sub get_codes { return \%code_hash; }

1;
