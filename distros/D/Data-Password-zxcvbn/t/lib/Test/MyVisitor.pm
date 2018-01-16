package Test::MyVisitor;
use Moose;
extends 'Data::Visitor::Callback';

sub visit_hash_key {
    my ( $self, $key, $value, $hash ) = @_;
    $self->SUPER::visit_hash_key($self->callback(hash_key=> $key, $value, $hash));
}

sub visit_hash_value {
    my ( $self, $value, $key, $hash ) = @_;
    $self->SUPER::visit_hash_value($self->callback_and_reg(hash_value=> $_[1], $key, $hash));
}


1;
