package Catalyst::Model::MultiAdaptor::LifeCycle::PerRequest;
use Sub::Install;

use base 'Catalyst::Model::MultiAdaptor::LifeCycle';

sub install {
    my $self = shift;
    Sub::Install::install_sub(
        {   code => sub {
                my ( $component, $context ) = @_;
                my $id = '__' . $self->model_class_name;
                $context->stash->{$id}
                    ||= $self->create_instance( $self->adapted_class,
                    $self->config );
                return $context->stash->{$id};
            },
            into => $self->model_class_name,
            as   => 'ACCEPT_CONTEXT',
        }
    );
}

1;
