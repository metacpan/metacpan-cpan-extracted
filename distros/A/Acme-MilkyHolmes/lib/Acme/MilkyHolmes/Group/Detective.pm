package Acme::MilkyHolmes::Group::Detective;
use Mouse;
extends 'Acme::MilkyHolmes::Character';
with 'Acme::MilkyHolmes::Role::ToysOwner';

sub toys {
    my ($self) = @_;
    return $self->_localized_field('toys');
}

no Mouse;
1;
