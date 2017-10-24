
use strict;
use warnings;

package Context::Singleton::Frame::Promise::Rule;

our $VERSION = v1.0.0;

use parent qw[ Context::Singleton::Frame::Promise ];

sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new (%params);

    $self->{rule} = $params{rule};

    $self;
}

sub rule {
    $_[0]->{rule};
}

sub notify_deducible {
    my ($self, $in_depth) = @_;

    $self->set_deducible ($in_depth)
        if $self->deducible_dependencies;
}

sub deducible_builder {
    my ($self) = @_;

    for my $dependency ($self->deducible_dependencies) {
        next unless $dependency->deduced_in_depth == $self->deduced_in_depth;

        return $dependency;
    }
}

1;

