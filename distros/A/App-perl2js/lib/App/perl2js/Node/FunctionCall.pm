package App::perl2js::Node::FunctionCall;

use strict;
use warnings;
use parent qw(App::perl2js::Node);

sub args {
    my ($self) = @_;
    return $self->{args};
}

sub to_javascript {
    my ($self, $depth) = @_;
    my $token = $self->token;
    return (
        $self->token->data,
        "(",
        (join ', ', map { join '', $_->to_javascript($depth) } grep { $_ } @{$self->args}),
        ")",
    );
}

1;
