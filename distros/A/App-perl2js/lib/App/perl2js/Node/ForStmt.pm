package App::perl2js::Node::ForStmt;

use strict;
use warnings;
use parent qw(App::perl2js::Node::BlockStmt);

use App::perl2js::Node::Nop;

sub init {
    my ($self) = @_;
    return $self->{init} // App::perl2js::Node::Nop->new;
}

sub cond {
    my ($self) = @_;
    return $self->{cond} // App::perl2js::Node::Nop->new;
}

sub progress {
    my ($self) = @_;
    return $self->{progress} // App::perl2js::Node::Nop->new;
}

sub to_javascript {
    my ($self, $depth) = @_;
    return (
        "for (",
        $self->init->to_javascript,
        "; ",
        $self->cond->to_javascript,
        "; ",
        $self->progress->to_javascript,
        ") {\n",
        $self->sentences_to_javascript($depth + 1),
        $self->indent($depth),
        "}",
    );
}

1;
