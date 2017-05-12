package App::perl2js::Node;

use strict;
use warnings;

use App::perl2js::Node::Nop;

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

sub token {
    my ($self) = @_;
    return $self->{token};
}

sub next {
    my ($self) = @_;
    return $self->{next} // App::perl2js::Node::Nop->new;
}

sub is_nop {
    my ($self) = @_;
    return $self->isa("App::perl2js::Node::Nop");
}

sub indent {
    my ($self, $depth) = @_;
    return "    " x $depth;
}

sub to_javascript {
    my ($self) = @_;
    return ("to_javascript not implemented: " . ref($self));
}

1;
