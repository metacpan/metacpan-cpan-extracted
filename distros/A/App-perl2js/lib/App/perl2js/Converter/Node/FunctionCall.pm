package App::perl2js::Converter::Node::FunctionCall;
use strict;
use warnings;
use parent 'App::perl2js::Converter::Node';

use App::perl2js::Node::FunctionCall;

sub args {
    my ($self) = @_;
    return $self->{args};
}

sub to_js_ast {
    my ($self, $context) = @_;
    my $current_block = $context->current_block;

    my $token = $self->token;

    return App::perl2js::Node::FunctionCall->new(
        token => $token,
        args => [ map { $_->to_js_ast($context) } @{$self->args} ],
    );
}

1;
