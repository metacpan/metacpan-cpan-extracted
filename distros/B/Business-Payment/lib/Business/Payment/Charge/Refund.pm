package Business::Payment::Charge::Refund;

use Moose::Role;

has 'order_number' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1
);

1;
