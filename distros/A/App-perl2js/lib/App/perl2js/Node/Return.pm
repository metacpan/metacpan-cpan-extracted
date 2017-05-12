# TODO: this package is not BlockStmt.
# field 'body' is used as statements in C::P::Node::Function.

package App::perl2js::Node::Return;

use strict;
use warnings;
use parent qw(App::perl2js::Node::BlockStmt);

use App::perl2js::Node::Nop;

sub body {
    my ($self) = @_;
    return $self->{body} // App::perl2js::Node::Nop->new;
}

sub to_javascript {
    my ($self, $depth) = @_;
    return (
        'return ',
        ($self->statements->[0] || App::perl2js::Node::Nop->new)->to_javascript($depth + 1)
    );
}

1;
