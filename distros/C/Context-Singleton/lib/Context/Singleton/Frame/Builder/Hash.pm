
use strict;
use warnings;

package Context::Singleton::Frame::Builder::Hash;

our $VERSION = v1.0.2;

use parent qw[ Context::Singleton::Frame::Builder::Base ];

sub _build_required {
    my ($self) = @_;

    return (
        $self->SUPER::_build_required,
        grep defined, values %{ $self->dep },
    );
}

sub build_callback_args {
    my ($self, $resolved) = @_;

    my $dep = $self->{dep};
    return (
        $self->SUPER::build_callback_args ($resolved),
        map +( $_ => $resolved->{$dep->{$_}} ), keys %$dep,
    );
}

1;

