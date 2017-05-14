package Contact::DBSQL::DBAdaptor;
use strict;
use vars qw(@ISA);
use AutoSQL::DBSQL::DBAdaptor;
@ISA=qw(AutoSQL::DBSQL::DBAdaptor);

use ContactSchema;
use AutoSQL::AdaptorFactory;
sub _initialize {
    my ($self, @args)=@_;
    # To satisfy general DBAdaptor, I have to build a factory and put it into
    # @args before called SUPER::_initialize.
    my ($factory) = $self->_rearrange([qw(FACTORY)], @args);
    unless(defined $factory){
        $factory=AutoSQL::AdaptorFactory->new(
            -schema => ContactSchema->new
        );
        push @args, -factory => $factory;
    }
    
    $self->SUPER::_initialize(@args);
    $self->add_object_adaptor(
        'Person'); # , 'Contact::DBSQL::PersonAdaptor');
    $self->add_object_adaptor('NRIC');
    $self->add_object_adaptor('Email');
}

1;
