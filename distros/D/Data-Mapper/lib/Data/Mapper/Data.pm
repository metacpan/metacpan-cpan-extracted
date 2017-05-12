package Data::Mapper::Data;
use strict;
use warnings;
use parent qw(Data::Mapper::Class);

use Carp ();

sub param {
    my $self = shift;
    return keys %$self if !@_;

    if (@_ == 1) {
        my $key = shift;
        return $self->{$key};
    }
    elsif (@_ && @_ % 2 == 0) {
        my %args = @_;

        while (my ($key, $value) = each %args) {
            $self->{$key} = $value;
            $self->mark_as_changed($key);
        }

        return $self;
    }
    else {
        Carp::croak('arguments count must be an even number');
    }
}

my %CHANGES;
sub changed_keys {
    my ($self, $changed_keys) = @_;
    $CHANGES{$self + 0} ||= [];
    $CHANGES{$self + 0} = $changed_keys if defined $changed_keys;
    $CHANGES{$self + 0};
}

sub changes {
    my $self = shift;
    my $changes = {};

    for my $key (@{$self->changed_keys}) {
        $changes->{$key} = $self->param($key);
    }

    $changes;
}

sub mark_as_changed {
    my ($self, $key) = @_;
    push @{$self->changed_keys}, $key;
}

sub is_changed {
    my $self = shift;
    scalar @{$self->changed_keys} > 0;
}

sub discard_changes {
    my $self = shift;
    $self->changed_keys([]);
}

sub DESTROY {
    my $self = shift;
    $self->discard_changes;
}

!!1;
