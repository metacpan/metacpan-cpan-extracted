package App::perl2js::Node::Class;

use strict;
use warnings;
use parent qw(App::perl2js::Node::Block);

use App::perl2js::Node::Nop;

sub to_javascript {
    my ($self, $depth) = @_;
    return (
        "var ", $self->token->data, " = (function() {\n",
        $self->indent($depth + 1),
        "var ", $self->token->data, " = {\n",
        # ($self->{super_class} ? (" extends ", $self->{super_class}) : ()),
        # " {\n",
        (join "", map {
            $self->indent($depth + 2),
            join('', $_->to_javascript($depth + 2)),
            ",\n",
         } grep {
             $_->isa('App::perl2js::Node::Method')
         } @{$self->statements}),
        $self->indent($depth + 1), "}\n",
        $self->sentences_to_javascript($depth + 1, [ grep {
             !$_->isa('App::perl2js::Node::Nop') &&
             !$_->isa('App::perl2js::Node::Method')
         } @{$self->statements} ]),
        $self->indent($depth + 1),
        "return ", $self->token->data, ";\n",
        $self->indent($depth),
        "})();\n",
        "export { " . $self->token->data . " }\n",
    );
}

1;
