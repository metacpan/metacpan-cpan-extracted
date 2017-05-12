package Business::EDI::CodeList::OriginatorTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {3457;}
my $usage       = 'I';

# 3457  Originator type code                                    [I]
# Desc: Code specifying the type of originator.
# Repr: an..3

my %code_hash = (
'1' => [ 'Travel agent',
    'The originator is a travel agent.' ],
'2' => [ 'Reservation agent',
    'The originator is a reservation agent.' ],
'3' => [ 'Seller',
    'The originator is the seller.' ],
);
sub get_codes { return \%code_hash; }

1;
