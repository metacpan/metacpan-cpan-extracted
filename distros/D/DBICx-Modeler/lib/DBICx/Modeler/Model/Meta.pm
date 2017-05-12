package DBICx::Modeler::Model::Meta;

use strict;
use warnings;

use Moose;

use DBICx::Modeler::Carp;
use constant TRACE => DBICx::Modeler::Carp::TRACE;

has parent => qw/is ro isa Maybe[DBICx::Modeler::Model::Meta] lazy_build 1/;
sub _build_parent {
    my $self = shift;
    if (my $method = $self->model_class->meta->find_next_method_by_name( '_model__meta' )) {
        return $method->();
    }
    return undef;
}
has model_class => qw/is ro required 1/;
has _specialization => qw/is ro isa HashRef/, default => sub { {} };
has _initialized => qw/is rw/;

sub _specialize_relationship {
    my $self = shift;
    my ($relationship_kind, $relationship_name, $model_class) = @_;
    $self->_specialization->{relationship}->{$relationship_name} = {
            kind => $relationship_kind,
            name => $relationship_name,
            model_class => $model_class,
    };
}

sub belongs_to {
    my $self = shift;
    $self->_specialize_relationship( belongs_to => @_ );
}

sub has_one {
    my $self = shift;
    $self->_specialize_relationship( has_one => @_ );
}

sub has_many {
    my $self = shift;
    $self->_specialize_relationship( has_many => @_ );
}

sub might_have {
    my $self = shift;
    $self->_specialize_relationship( might_have => @_ );
}

sub specialize_model_source {
    my $self = shift;
    my $model_source = shift;
    if ( local $_ = $self->_specialization->{relationship} ) {
        for my $specialized_relationship (values %$_) {
            my ($name, $kind, $model_class) = @$specialized_relationship{qw/ name kind model_class /};
            my $relationship = $model_source->relationship( $name );
            $model_class = '+' . $relationship->default_model_class unless defined $model_class;
            $model_class = $model_source->modeler->find_model_class( $model_class );
            $relationship->model_class( $model_class );
        }
    }
    return $model_source;
}

sub initialize_base_model_class {
    my $self = shift;
    my $model_source = shift;

    my $model_class = $self->model_class;

    if ($self->_initialized) {
        TRACE->( "[$self] Already initialized $model_class" );
        return;
    }

    $self->_initialized( 1 );

    my $meta = $model_class->meta;

    if ($self->parent) {
        $self->parent->initialize_base_model_class( $model_source );
    }
    else {
        my $result_source = $model_source->result_source;

        TRACE->( "[$self] Initializing base model class $model_class" );

        # $model_source should have been specialized already
        for my $relationship ( $model_source->relationships ) {
            my $name = $relationship->name;
            my $method = "_model__relation_$name";
            my $is_many = $relationship->is_many;
            my $alias = ! $meta->has_method( $name );

            if ($is_many) {
                $meta->add_method( $method => sub {
                    my $self = shift;
                    return $self->_model__source->search_related( $self, $name, @_ );
                } );
                if ($alias) {
                    $meta->add_method( $name => sub {
                        my $self = shift;
                        return $self->$method( @_ );
                    } );
                }
            }
            else {
                $meta->add_attribute( $method => qw/is ro lazy 1/, default => sub {
                    my $self = shift;
                    return $self->_model__source->inflate_related( $self, $name );
                } );
                if ($alias) {
                    $meta->add_method( $name => sub {
                        my $self = shift;
                        return $self->$method( @_ );
                    } );
                }
            }
        }

        unless ($meta->has_method( 'create_related' )) {
            $meta->add_method( 'create_related' => sub {
                my $self = shift;
                return $self->_model__source->create_related( $self, @_ );
            });
        }

        unless ($meta->has_method( 'search_related' )) {
            $meta->add_method( 'search_related' => sub {
                my $self = shift;
                return $self->_model__source->search_related( $self, @_ );
            });
        }

        my $attribute;
        if ($attribute = $meta->get_attribute( '_model__storage' )) {

            if ($attribute->has_handles) { 
                TRACE->("[$self] Not setting up model storage handles for $model_class since it already has them");
                # Assume the user know's what they're doing
            }
            else {
                my @columns = $result_source->columns;
                my %handles = map { $_ => $_ } qw/insert update/;
                $handles{$_} = $_ for grep { ! $meta->has_method( $_ ) } @columns;
                @handles{ map { "_model__column_$_" } @columns } = @columns;
                my $new_attribute = $meta->_process_inherited_attribute( $attribute->name, handles => \%handles );
                $meta->add_attribute( $new_attribute );
            }
        }
        else {
            croak "Couldn't set up model storage handles for $model_class since it doesn't have a '_model__storage' attribute"
        }
    }

    for my $method_modifier (@{ $self->_specialization->{method_modifier} }) {
        my ($kind, @arguments) = @$method_modifier;
        Moose::Util::add_method_modifier( $model_class, $kind, \@arguments );
    }
}

1;
