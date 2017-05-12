package App::perl2js::Converter::Node::ControlStmt;
use strict;
use warnings;
use parent 'App::perl2js::Converter::Node';

use App::perl2js::Node::ControlStmt;

sub to_js_ast {
    my ($self, $context) = @_;
    my $token = $self->token;
    if ($token->name eq 'Next') {
        $token->{name} = 'Continue';
        $token->{data} = 'continue';
    } elsif ($token->name eq 'Last') {
        $token->{name} = 'Break';
        $token->{data} = 'break';
    }
    return App::perl2js::Node::ControlStmt->new(
        token => $self->token,
    );
}


1;
