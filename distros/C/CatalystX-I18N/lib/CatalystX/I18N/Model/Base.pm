# ============================================================================
package CatalystX::I18N::Model::Base;
# ============================================================================

use namespace::autoclean;
use Moose;
extends 'Catalyst::Model';

has '_app' => (
    is          => 'rw', 
    isa         => 'Str',
    required    => 1,
);

has 'class' => (
    is          => 'rw', 
    isa         => 'Str',
    lazy_build  => 1,
);

has 'directories' => (
    is          => 'rw', 
    isa         => 'CatalystX::I18N::Type::DirList',
    coerce      => 1,
    lazy_build  => 1,
);

around BUILDARGS => sub {
    my $orig  = shift;
    my ( $self,$app,$config ) = @_;
    
    # Set _app class
    $config->{_app} = $app;
    
    # Call original BUILDARGS
    return $self->$orig($app,$config);
};

sub _build_class {
    my ($self) = @_;
    return $self->_app.'::'.class_name($self);
}

sub class_name {
    my ($class_name) = @_;
    $class_name = ref($class_name)
        if ref($class_name);
    my ($return) = reverse split(/::/,$class_name);
    return $return;
}

sub _build_directories {
    my ($self) = @_;
    
    my $class_name = class_name($self->class);
    my $calldir = $self->_app;
    $calldir =~ s{::}{/}g;
    
    my $file = $calldir.".pm";
    my $path = $INC{$file};
    $path =~ s{\.pm$}{/$class_name};
    
    return [ Path::Class::Dir->new($path) ];
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
no Moose;
1;
