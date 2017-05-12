package Catalyst::Model::MultiAdaptor::LifeCycle;
use Moose;

has 'model_class_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'adapted_class' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'config' => (
    is       => 'ro',
);

sub setup {
    my ( $class, $params ) = @_;
    my $class_name = $class . "::" . $params->{policy};
    Class::MOP::load_class($class_name);
    my $lifecycle = $class_name->new(
        adapted_class    => $params->{adapted_class},
        model_class_name => $params->{model_class_name},
        config           => $params->{config},
    );
    $lifecycle->install;
}

sub create_instance {
    my ( $self, $adapted_class, $config ) = @_;
    return $adapted_class->new( %{$config} );
}

__PACKAGE__->meta->make_immutable;

1;
