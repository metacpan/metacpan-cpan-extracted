package App::perl2js::Node::Import;

use strict;
use warnings;
use parent qw(App::perl2js::Node);

use App::perl2js::Node::Nop;

sub args {
    my ($self) = @_;
    return $self->{args} // App::perl2js::Node::Nop->new;
}

sub to_javascript {
    my ($self, $depth) = @_;
    my $module_name = $self->token->data;
    return (
        "import ",
        $self->token->data,
    );
}

1;
