package Test::GeneralLedger;
use Moose;

use List::Util qw( reduce );

has line_id => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
);

has timestamp => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
);

has split => (
    is          => 'ro',
    isa         => 'ArrayRef[Test::JournalEntry]',
    required    => 1,
    traits      => [ 'Array' ],
    handles     => {
        ledger       => 'elements',
        add_ledger   => 'push',
        ledger_count => 'count',
    },
);

sub is_balanced {
    my $self = shift;

    use vars qw( $a $b );
    my $sum = reduce { $a + $b->amount } (0, $self->ledger);
    return $sum == 0;
}

sub complete {
    my $self = shift;
    return $self->ledger_count > 0 && $self->is_balanced;
}

__PACKAGE__->meta->make_immutable;
