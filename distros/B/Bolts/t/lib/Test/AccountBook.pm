package Test::AccountBook;
use Moose;

use List::Util qw( reduce );
use Moose::Util::TypeConstraints;

has name => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

has account_type => (
    is          => 'rw',
    isa         => enum([ 'debit', 'credit' ]),
    required    => 1,
);

has journal => (
    is          => 'ro',
    isa         => 'ArrayRef[Test::JournalEntry]',
    required    => 1,
    traits      => [ 'Array' ],
    handles     => {
        ledger     => 'elements',
        add_ledger => 'push',
    },
);

sub balance {
    my $self = shift;

    use vars qw( $a $b );
    my $sum = reduce { $a + $b->amount } (0, $self->ledger);
    return $self->account_type eq 'debit' ? -$sum : $sum;
}

__PACKAGE__->meta->make_immutable;
