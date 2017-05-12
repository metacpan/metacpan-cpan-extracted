package Catalyst::Model::MultiAdaptor::LifeCycle::Prototype;
use base 'Catalyst::Model::MultiAdaptor::LifeCycle';

sub install {
    my $self = shift;
    Sub::Install::install_sub(
        {   code => sub {
                return $self->create_instance( $self->adapted_class,
                    $self->config );
            },
            into => $self->model_class_name,
            as   => 'ACCEPT_CONTEXT',
        }
    );
}

1;
