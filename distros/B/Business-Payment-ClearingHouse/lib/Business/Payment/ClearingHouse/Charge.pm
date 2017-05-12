package Business::Payment::ClearingHouse::Charge;
use Moose;

has 'currency' => (
    is => 'ro',
    isa => 'Str'
);

has 'id' => (
    is => 'ro',
    isa => 'Str'
);

has 'number' => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has 'subtotal' => (
    is => 'ro',
    isa => 'Int',
    default => 0
);

has 'tax' => (
    is => 'ro',
    isa => 'Int',
    default => 0
);

sub total {
    my ($self) = @_;

    return $self->subtotal + $self->tax;
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;