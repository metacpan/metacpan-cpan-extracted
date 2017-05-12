package Catalyst::Model::MultiAdaptor::Base;
use strict;
use warnings;
use Carp;
use Class::C3;
use Class::MOP;
use Sub::Install;
use Module::Pluggable::Object;
use Catalyst::Model::MultiAdaptor::LifeCycle;

use base 'Catalyst::Model';

sub load_services {
    my $self         = shift;
    my $base_package = $self->{package};
    croak 'package parameter must be set.' unless $base_package;
    my $finder = Module::Pluggable::Object->new(
        search_path => $base_package,
        except      => $self->_except_classes || []
    );
    for my $service ( $finder->plugins ) {
        $self->_load_class($service);
        my $config = $self->_service_config($service);
        $self->_install_service_as_model( $service, $config );
    }
}

sub _except_classes {
    my $self = shift;
    my @except_classes
        = map { $self->{package} . "::" . $_ } @{ $self->{except} };
    \@except_classes;
}

sub _install_service_as_model {
    my ( $self, $service, $config ) = @_;
    my $model_class_name
        = $self->_convert2modelname( $service, $self->{package} );
    Catalyst::Model::MultiAdaptor::LifeCycle->setup(
        {   adapted_class    => $service,
            model_class_name => $model_class_name,
            config           => $config,
            policy           => $self->{lifecycle} || 'Singleton',
        }
    );
}

sub _service_config {
    my ( $self, $service ) = @_;
    my $short_service_name
        = $self->_short_service_name( $service, $self->{package} );
    my $config = $self->{config} || {};
    return $config->{$short_service_name} || {};
}

sub _convert2modelname {
    my ( $self, $service, $base_package ) = @_;
    my $class = ref($self);
    my $short_service_name
        = $self->_short_service_name( $service, $base_package );
    return "${class}::$short_service_name";
}

sub _short_service_name {
    my ( $self, $service, $base_package ) = @_;
    my $short_service_name = $service;
    $short_service_name =~ s/^$base_package\:\://g;
    return $short_service_name;
}

sub _load_class {
    my ( $self, $adapted_class ) = @_;
    Class::MOP::load_class($adapted_class);
}

sub _create_instance {
    my ( $self, $adapted_class, $config ) = @_;
    return $adapted_class->new( %{$config} );
}

1;

__END__
