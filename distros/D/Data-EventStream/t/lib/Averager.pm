package Averager;
use Moose;

has value_sub => (
    is      => 'rw',
    default => sub {
        sub { shift->{val} }
    },
);

has _sum => (
    is      => 'rw',
    traits  => ['Number'],
    default => 0,
    handles => {
        _sum_add => 'add',
        _sum_sub => 'sub',
    },
);

has _count => (
    is      => 'rw',
    traits  => ['Counter'],
    default => 0,
    handles => {
        _inc_count   => 'inc',
        _dec_count   => 'dec',
        _reset_count => 'reset',
    },
);

sub value {
    my $self = shift;
    return $self->_count ? sprintf( "%.6g", $self->_sum / $self->_count ) : 'NaN';
}

sub enter {
    my ( $self, $event ) = @_;
    my $val = $self->value_sub->($event);
    $self->_sum_add($val);
    $self->_inc_count;
}

sub reset {
    my $self = shift;
    $self->_sum(0);
    $self->_reset_count;
}

sub leave {
    my ( $self, $event ) = @_;
    my $val = $self->value_sub->($event);
    $self->_dec_count;
    $self->_sum_sub($val);
}

__PACKAGE__->meta->make_immutable;

1;
