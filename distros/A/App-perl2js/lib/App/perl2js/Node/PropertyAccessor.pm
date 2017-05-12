package App::perl2js::Node::PropertyAccessor;

use strict;
use warnings;
use parent qw(App::perl2js::Node);

use App::perl2js::Node::Nop;

sub data {
    my ($self) = @_;
    return $self->{data} // App::perl2js::Node::Nop->new;
}

sub key {
    my ($self) = @_;
    return $self->{key} // App::perl2js::Node::Nop->new;
}

sub to_javascript {
    my ($self, $depth) = @_;
    return (
        $self->data->to_javascript($depth),
        "[",
        $self->key->to_javascript($depth),
        "]",
    );
}

1;
