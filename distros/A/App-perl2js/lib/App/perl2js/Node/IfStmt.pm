package App::perl2js::Node::IfStmt;

use strict;
use warnings;
use parent qw(App::perl2js::Node::BlockStmt);

use App::perl2js::Node::Nop;

sub expr {
    my ($self) = @_;
    return $self->{expr} // App::perl2js::Node::Nop->new;
}

sub false_stmt {
    my ($self) = @_;
    return $self->{false_stmt} // App::perl2js::Node::Nop->new;
}

sub to_javascript {
    my ($self, $depth) = @_;
    return (
        "if (",
        $self->expr->to_javascript($depth),
        ") {\n",
        $self->sentences_to_javascript($depth + 1),
        $self->indent($depth),
        "}",
        ($self->false_stmt->is_nop ?
         () :
         (" else ",
          $self->false_stmt->to_javascript($depth),
         )
        ),
    );
}

1;
