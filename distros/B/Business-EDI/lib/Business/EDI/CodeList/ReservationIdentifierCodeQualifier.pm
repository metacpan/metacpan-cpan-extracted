package Business::EDI::CodeList::ReservationIdentifierCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9043;}
my $usage       = 'I';

# 9043  Reservation identifier code qualifier                   [I]
# Desc: Code qualifying the reservation identifier.
# Repr: an..3

my %code_hash = (
'1' => [ 'Confirmation number',
    'Number issued by the provider system by which they reference the reservation.' ],
'2' => [ 'Cancellation number',
    'Number issued by the provider system by which they reference the reservation marked as cancelled.' ],
'3' => [ 'Dossier',
    'The reservation identifier refers to a dossier.' ],
'4' => [ 'Booking',
    'The reservation identifier refers to a booking.' ],
'5' => [ 'Breakfast',
    'The reservation identifier refers to a breakfast reservation.' ],
'6' => [ 'Lunch',
    'The reservation identifier refers to a lunch reservation.' ],
'7' => [ 'Dinner',
    'The reservation identifier refers to a dinner reservation.' ],
'8' => [ 'Composite booking',
    'The reservation identifier refers to a booking including several reservations.' ],
);
sub get_codes { return \%code_hash; }

1;
