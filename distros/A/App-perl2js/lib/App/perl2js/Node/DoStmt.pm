package App::perl2js::Node::DoStmt;

use strict;
use warnings;
use parent qw(App::perl2js::Node::BlockStmt);

use App::perl2js::Node::Nop;

sub to_javascript {
    my ($self, $depth) = @_;
    return (
        "(function() {\n",
        $self->sentences_to_javascript($depth + 1),
        $self->indent($depth),
        "})()",
    );
}

1;
