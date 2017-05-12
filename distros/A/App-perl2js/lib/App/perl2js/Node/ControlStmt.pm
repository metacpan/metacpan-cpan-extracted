package App::perl2js::Node::ControlStmt;

use strict;
use warnings;
use parent qw(App::perl2js::Node);

use App::perl2js::Node::Nop;

sub to_javascript {
    my ($self, $depth) = @_;
    return (
        $self->token->data,
    );
}

1;
