package Business::Payment::Charge::Customer;

use Moose::Role;

has 'first_name' => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

has 'last_name' => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

has 'address' => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

has 'city' => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

has 'state' => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

has 'zip' => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

has 'country' => (
    is => 'rw',
    isa => 'Str',
    required => 0
);

has 'customer_id' => (
    is => 'rw',
    isa => 'Str|Int',
);

no Moose::Role;
1;

