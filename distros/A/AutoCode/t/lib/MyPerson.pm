package MyPerson;
use strict;

use AutoCode::CustomMaker 'ContactSchema', 'Person';

sub _initialize {
    my ($self, @args)=@_;
    $self->SUPER::_initialize(@args);

}

sub full_name {
    my $self=shift;
    return $self->first_name .' '. $self->last_name;
}

1;
