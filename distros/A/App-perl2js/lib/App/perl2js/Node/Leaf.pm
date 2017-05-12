package App::perl2js::Node::Leaf;

use strict;
use warnings;
use parent qw(App::perl2js::Node);

sub to_javascript {
    my ($self, $depth) = @_;
    return (
        $self->token->data,
    );
}

1;
