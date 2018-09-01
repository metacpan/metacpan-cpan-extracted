
use strict;
use warnings;

package Context::Singleton::Frame::Builder::Array;

our $VERSION = v1.0.2;

use parent qw[ Context::Singleton::Frame::Builder::Base ];

sub _build_required {
    my ($self) = @_;

    return (
        $self->SUPER::_build_required,
        @{ $self->dep // [] },
    );
}

sub build_callback_args {
    my ($self, $resolved) = @_;

    return (
        $self->SUPER::build_callback_args ($resolved),
        @$resolved{@{ $self->dep }},
    );
}

1;

