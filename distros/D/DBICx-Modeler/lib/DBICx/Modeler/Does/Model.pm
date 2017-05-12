package DBICx::Modeler::Does::Model;

use DBICx::Modeler::Carp;
use constant TRACE => DBICx::Modeler::Carp::TRACE;

#########
# Class #
#########

# This is a class method!
# This method is for DBix::Class::ResultSet, so it can inflate into our model classes
sub inflate_result {
    my $class = shift;
    my $source = shift;
    my $storage = $source->result_class->inflate_result( $source, @_ ); # Inflate into the "original" DBIx::Class::Row-kind
    return $class->new( _model__storage => $storage ); # Only need to pass in the storage, model_modeler is gotten from the schema
}

##########
# Object #
##########

use Moose::Role;

requires qw/_model__meta/;
# requires model_meta 

has _model__modeler => qw/is ro lazy_build 1 weak_ref 1/;
sub _build__model__modeler {
    return shift->_model__schema->modeler;
};

has _model__schema => qw/is ro lazy_build 1 weak_ref 1/;
sub _build__model__schema {
    return shift->_model__storage->result_source->schema;
};

has _model__storage => qw/is ro required 1/;

sub _model__source {
    my $self = shift;
    return $self->_model__modeler->model_source_by_model_class( ref $self );
}

sub _model__search_related {
    my $self = shift;
    my $relationship_name = shift;
    return $self->_model__source->search_related( $self => $relationship_name => @_ );
}

sub _model__create_related {
    my $self = shift;
    my $relationship_name = shift;
    return $self->_model__source->create_related( $self => $relationship_name => @_ );
}

1;
