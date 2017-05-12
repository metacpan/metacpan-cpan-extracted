package Autocache::Strategy::Eviction::LRU::Entry;

use Any::Moose;

use Time::HiRes qw( time );

has 'key' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has 'size' => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);

has 'atime' => (
    is => 'rw',
    isa => 'Num',
    default => sub { time },
);

sub touch
{
    my ($self) = @_;
    $self->atime( time );
}

sub cmp
{
    my ($lhs,$rhs) = @_;
    return $lhs->atime <=> $rhs->atime;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
