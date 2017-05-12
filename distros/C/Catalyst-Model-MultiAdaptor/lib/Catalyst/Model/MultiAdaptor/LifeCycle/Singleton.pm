package Catalyst::Model::MultiAdaptor::LifeCycle::Singleton;
use Sub::Install;

use base 'Catalyst::Model::MultiAdaptor::LifeCycle';

sub install {
    my $self = shift;
    my $instance = $self->create_instance( $self->adapted_class, $self->config );
    Sub::Install::install_sub(
        {   code => sub { return $instance },
            into => $self->model_class_name,
            as   => 'COMPONENT',
        }
    );
}

1;
