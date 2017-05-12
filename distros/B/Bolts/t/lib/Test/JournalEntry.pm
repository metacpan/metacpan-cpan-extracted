package Test::JournalEntry;
use Moose;

has ledger => (
    is          => 'ro',
    isa         => 'Test::GeneralLedger',
    required    => 1,
    weak_ref    => 1,
);

has description => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

has account => (
    is          => 'rw',
    isa         => 'Test::AccountBook',
    required    => 1,
    weak_ref    => 1,
);

has memo => (
    is          => 'rw',
    isa         => 'Str',
);

has amount => (
    is          => 'ro',
    isa         => 'Int', # pennies
    required    => 1,
    default     => 0,
);

sub debit {
    my $self = shift;
    my $amount = $self->amount;
    return $amount < 0 ? -$amount : 0;
}

sub credit {
    my $self = shift;
    my $amount = $self->amount;
    return $amount > 0 ? $amount : 0;
}

__PACKAGE__->meta->make_immutable;
