
use strict;
use warnings;

package Context::Singleton::Frame::Promise::Builder;

our $VERSION = v1.0.0;

use parent qw[ Context::Singleton::Frame::Promise ];

sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new (%params);

    $self->{builder} = $params{builder};

    $self;
}

sub builder {
    $_[0]->{builder};
}

sub notify_deducible {
    my ($self, $in_depth) = @_;

    $self->set_deducible ($in_depth)
        if $self->deducible_dependencies == $self->dependencies;
}

1;

