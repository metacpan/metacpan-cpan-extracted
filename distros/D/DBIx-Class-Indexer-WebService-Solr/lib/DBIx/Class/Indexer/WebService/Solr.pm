package DBIx::Class::Indexer::WebService::Solr;

use strict;
use warnings;

our $VERSION = '0.02';

use base qw( DBIx::Class::Indexer DBIx::Class );

use WebService::Solr;
use Scalar::Util ();

__PACKAGE__->mk_classdata( _obj        => undef );
__PACKAGE__->mk_classdata( _field_prep => {} );

=head1 NAME

DBIx::Class::Indexer::WebService::Solr - Automatic indexing of DBIx::Class objects via WebService::Solr

=head1 SYNOPSIS

    package MySchema::Foo;
    
    use base qw( DBIx::Class );
    
    __PACKAGE__->load_components( qw( Indexed Core ) );
    __PACKAGE__->table('foo');
    __PACKAGE__->set_indexer('WebService::Solr');
    __PACKAGE__->add_columns(
        foo_id => { # automatically indexed as "id"
            data_type         => 'integer',
            is_auto_increment => 1
        },
        name => {
            data_type => 'varchar',
            size      => 10,
            indexed   => {
                boost => '2.0',
            }
        },
        location => {
            data_type => 'varchar',
            size      => 50,
            indexed   => 1
        }
    );
    
    __PACKAGE__->has_many( widgets => 'widget' );
    __PACKAGE__->add_index_fields(
        widget => {
            source => 'widgets.name'
        },
    );
    
=head1 DESCRIPTION

Connects a DBIx::Class-based class to a Solr index.
    
=head1 METHODS

=head2 new( \%connect_info, $source_class )

Creates a new WebSevice::Solr object and normalizes the fields to be
indexed.

=cut

sub new {
    my $class        = shift;
    my $connect_info = shift;
    my $source       = shift;
    
    my $self = bless { }, $class;
    $self->setup_fields( $source );

    my $server = $connect_info->{ server };
    my $opts   = $connect_info->{ options } || {};
    $opts->{ autocommit } = 1;
    my $solr   = WebService::Solr->new( $server, $opts );

    $self->_obj( $solr );

    return $self;
}

=head2 setup_fields( $source )

Normalizes the index fields so they all have hashref members with an optional
boost key.

=cut

sub setup_fields {
    my( $self, $source ) = @_;

    return if $self->_field_prep->{ $source };

    my $fields = $source->index_fields;
  
    # normalize field defs
    for my $key ( keys %$fields ) {
        $fields->{ $key } = { } if !ref $fields->{ $key };
    }

    if( !exists $fields->{ id } ) {
        $fields->{ id } = { };
    }

    $self->_field_prep->{ $source } = 1;
}

=head2 value_for_field( $object, $key )

Uses the indexed fields information to determine how to get
the values for C<$key> out of C<$object>. 

=cut

sub value_for_field {
    my( $self, $object, $key ) = @_;
    my $info   = $object->index_fields->{ $key };
    my $source = $info->{ source } || $key;
     
    if( ref $source eq 'CODE' ) {
        return $source->( $object );
    }
    elsif( not ref $source ) {
        my @accessors = split /\./, $source;
        
        # no use calling 'me' on myself...
        shift @accessors if lc $accessors[ 0 ] eq 'me';
        
        # traverse accessors
        my @values = $object;
        for my $accessor ( @accessors ) {
            @values = grep { defined }
                 map  {
                       Scalar::Util::blessed( $_ ) and $_->can( $accessor ) ? $_->$accessor
                     : ref $_ eq 'HASH' ? $_->{ $accessor }
                     : undef
                 } @values;
        }
        return wantarray ? @values : $values[ 0 ];
    }
}

=head2 as_document( $object )

Constructs a new WebService::Solr::Document object, populates it with
data from C<$object>, and returns it.

=cut

sub as_document {
    my( $self, $object ) = @_;
    my $document = WebService::Solr::Document->new;

    # this is basically a no-op if it's already been done
    # but it needs to be done in case the same indexer is
    # used for multiple sources
    $self->setup_fields( ref $object );
    
    my $fields = $object->index_fields;

    # for each field...
    for my $name ( keys %$fields ) {
        my $opts    = $fields->{$name};
        my @values  = $self->value_for_field( $object, $name );
    
        for( @values ) {
            $document->add_fields( [ $name => $_, $opts ] );
        }
    }

    return $document;
}

=head2 insert( $object )

Calls C<update_or_create_document>.

=cut

sub insert {
    my $self   = shift;
    my $object = shift;
    $self->update_or_create_document( $object );
}

=head2 update( $object )

Calls C<update_or_create_document>.

=cut

sub update {
    my $self   = shift;
    my $object = shift;
    
    $self->update_or_create_document( $object );
}

=head2 delete( $object )

Deletes document from the index.

=cut

sub delete {
    my $self   = shift;
    my $object = shift;
    my $solr  = $self->_obj;

    $self->setup_fields( ref $object );
    my $id = $self->value_for_field( $object, 'id' );

    $solr->delete_by_id( $id );  
}

=head2 update_or_create_document( $object )

Will either update or add a document to the index.

=cut

sub update_or_create_document {
    my $self   = shift;
    my $object = shift;
    my $solr  = $self->_obj;

    $self->setup_fields( ref $object );

    # add == update
    $solr->add( $self->as_document( $object ) );
}

=head1 SEE ALSO

=over 4

=item * DBIx::Class

=item * DBIx::Class::Indexed

=item * WebService::Solr

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
