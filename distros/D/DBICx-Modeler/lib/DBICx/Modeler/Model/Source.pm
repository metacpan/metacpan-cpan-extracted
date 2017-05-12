package DBICx::Modeler::Model::Source;

use strict;
use warnings;

use Moose;

use DBICx::Modeler::Carp;
use constant TRACE => DBICx::Modeler::Carp::TRACE;

use DBICx::Modeler::Model::Relationship;

has modeler => qw/is ro required 1 weak_ref 1/;
has schema => qw/is ro lazy_build 1 weak_ref 1/;
sub _build_schema {
    return shift->modeler->schema;
}
has moniker => qw/is ro required 1/;
has model_class => qw/is rw required 1/;
has result_source => qw/is ro lazy_build 1 weak_ref 1/;
sub _build_result_source {
    my $self = shift;
    return $self->schema->source( $self->moniker );
};
has create_refresh => qw/is rw lazy_build 1/;
sub _build_create_refresh {
    my $self = shift;
    return $self->modeler->create_refresh;
};
has _relationship_map => qw/is ro isa HashRef/, default => sub { {} };
sub relationship {
    my $self = shift;
    my $relationship_name = shift;
    return $self->_relationship_map->{$relationship_name} ||= $self->_build_relationship( $relationship_name );
}
sub relationships {
    my $self = shift;
    return values %{ $self->_relationship_map };
}

sub _build_relationship {
    my $self = shift;
    my $relationship_name = shift;

    my $result_source = $self->result_source;
    my $moniker = $self->moniker;

    TRACE->("[$self] Processing relationship $relationship_name for $moniker");
    my $schema_relationship = $result_source->relationship_info( $relationship_name );
    croak "No such relationship $relationship_name for ", $self->moniker unless $schema_relationship;
    my $model_relationship = DBICx::Modeler::Model::Relationship->new(
        modeler => $self->modeler,
        name => $relationship_name,
        model_source => $self,
        schema_relationship => $schema_relationship
    );
}

sub clone {
    my $self = shift;
    my %override = @_;
    my $clone = (blessed $self)->new(
        clone => 1,
        _relationship_map => { map { $_ => $self->_relationship_map->{$_}->clone } keys %{ $self->_relationship_map } },
        ( map { $_ => $self->$_ } qw/ modeler schema moniker model_class create_refresh / ),
        %override,
    );
    $clone->model_class->_model__meta->specialize_model_source( $clone ) if $override{model_class};
    return $clone;
}

sub BUILD {
    my $self = shift;
    my $given = shift;

    unless ($given->{clone}) {
        my $schema = $self->schema;
        my $moniker = $self->moniker;
        my $result_source = $self->result_source;

        for my $relationship_name ($result_source->relationships) {
            TRACE->( "[$self] Processing relationship $relationship_name for $moniker" );
            my $relationship = $result_source->relationship_info($relationship_name);
            my $model_relationship = DBICx::Modeler::Model::Relationship->new(parent_model_source => $self,
                modeler => $self->modeler, name => $relationship_name, schema_relationship => $relationship);
            $self->_relationship_map->{$relationship_name} = $model_relationship;
        }
        $self->model_class->_model__meta->specialize_model_source( $self );
    }
}

sub create {
    my $self = shift;
    my $given = shift;

    my $rs = $self->schema->resultset( $self->moniker );
    my $storage = $rs->create( $given );
    $storage->discard_changes if $self->create_refresh && $storage->can( 'discard_changes' );
    return $self->inflate( _model__storage => $storage, @_ );
}

sub update_or_create {
    my $self = shift;
    my $given = shift;

    my $rs = $self->schema->resultset( $self->moniker );
    my $storage = $rs->update_or_create( $given );
    $storage->discard_changes if $self->create_refresh && $storage->can( 'discard_changes' );
    return $self->inflate( _model__storage => $storage, @_ );
}

sub inflate {
    my $self = shift;
    return $self->_inflate( $self->model_class, @_ );
}

sub _inflate {
    my $self = shift;
    my $model_class = shift;
    my $inflate = @_ > 1 ? { @_ } : $_[0];
    return $model_class->new( %$inflate );
}

sub search {
    my $self = shift;
    my $cond = shift || undef;
    my $attr = shift || {};

    return $self->result_source->resultset->search( $cond, { result_class => $self->model_class, %$attr }, @_ );
}

sub inflate_related {
    my $self = shift;
    my $entity = shift;
    my $relationship_name = shift;
    my $inflate = @_ > 1 ? { @_ } : $_[0];

    my $relationship = $self->relationship( $relationship_name );

    # Don't create if entity doesn't have a relationship
    return undef unless my $storage = $entity->_model__storage->$relationship_name;

    return $self->_inflate( $relationship->model_class, _model__storage => $storage );
}

sub create_related {
    my $self = shift;
    my $entity = shift;
    my $relationship_name = shift;
    my $values = shift;

    my $relationship = $self->relationship( $relationship_name );

    my $storage = $entity->_model__storage->create_related( $relationship_name => $values );
    $storage->discard_changes if $self->create_refresh && $storage->can( 'discard_changes' );

    return $self->_inflate( $relationship->model_class, _model__storage => $storage );
}

sub search_related {
    my $self = shift;
    my $entity = shift;
    my $relationship_name = shift;
    my $condition = shift || undef;
    my $attributes = shift || {};

    my $relationship = $self->relationship( $relationship_name );

    return $entity->_model__storage->search_related( $relationship_name => $condition,
        { result_class => $relationship->model_class, %$attributes } );
}

1;
