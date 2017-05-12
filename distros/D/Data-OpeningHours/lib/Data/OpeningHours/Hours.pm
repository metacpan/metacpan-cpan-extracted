package Data::OpeningHours::Hours;
use strict;
use warnings;

sub new {
    my ($class, $pairs) = @_;

    my $self = bless {
        pairs => $pairs,
    }, $class;

    return bless $self, $class;
}

sub is_open_between {
    my ($self, $hour) = @_;
    for (@{$self->{pairs}}) {
        if ($self->is_pair_open_between($_, $hour)) {
            return 1;
        }
    }
    return;
}

sub is_pair_open_between {
    my ($self, $pair, $hour) = @_;
    return $pair->[0] le $hour && $pair->[1] gt $hour;
}

sub first_hour {
    my ($self) = @_;
    return $self->{pairs}[0][0];
}

1;
