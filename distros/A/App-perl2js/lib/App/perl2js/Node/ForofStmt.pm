package App::perl2js::Node::ForofStmt;

use strict;
use warnings;
use parent qw(App::perl2js::Node::BlockStmt);

use App::perl2js::Node::Nop;

sub cond {
    my ($self) = @_;
    return $self->{cond} // App::perl2js::Node::Nop->new;
}

sub itr {
    my ($self) = @_;
    return $self->{itr} // App::perl2js::Node::Nop->new;
}

sub to_javascript {
    my ($self, $depth) = @_;
    return (
        "for (",
        $self->itr->to_javascript,
        " of ",
        $self->cond->to_javascript,
        ") {\n",
        $self->sentences_to_javascript($depth + 1),
        $self->indent($depth),
        "}",
    );
}

1;
