package App::perl2js::Node::ArrayLiteral;

use strict;
use warnings;
use parent qw(App::perl2js::Node);

use App::perl2js::Node::Nop;

sub data_node {
    my ($self) = @_;
    return $self->{data} // App::perl2js::Node::Nop->new;
}

sub to_javascript {
    my ($self, $depth) = @_;
    return (
        "[",
        $self->data_node->to_javascript($depth),
        "]",
    );
}

1;
