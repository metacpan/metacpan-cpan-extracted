# TODO: this package is not BlockStmt.
# field 'body' is used as statements in C::P::Node::Function.

package App::perl2js::Converter::Node::Return;
use strict;
use warnings;
use parent 'App::perl2js::Converter::Node::BlockStmt';

use App::perl2js::Node::Return;

sub to_js_ast {
    my ($self, $context) = @_;
    return App::perl2js::Node::Return->new(
        token => $self->token,
        statements => [ map { $_->to_js_ast($context) } @{$self->statements || []} ],
    );
}

1;
