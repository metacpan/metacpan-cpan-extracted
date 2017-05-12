package DBIx::Class::Indexer::WebService::Lucene;

use strict;
use warnings;

use Scalar::Util ();
use WebService::Lucene::Document;
use WebService::Lucene::Field;
use WebService::Lucene::Index;

our $VERSION = '0.02';

use base qw( DBIx::Class::Indexer DBIx::Class );

__PACKAGE__->mk_classdata( _obj        => undef );
__PACKAGE__->mk_classdata( _field_prep => {} );

my %FIELD_TYPES = (
    #
    # MySQL types
    #
    bigint     => 'keyword',
    double     => 'keyword',
    decimal    => 'keyword',
    float      => 'keyword',
    int        => 'keyword',
    mediumint  => 'keyword',
    smallint   => 'keyword',
    tinyint    => 'keyword',
    char       => 'text',
    varchar    => 'text',
    longtext   => 'text',
    mediumtext => 'text',
    text       => 'text',
    tinytext   => 'text',
    tinyblob   => 'text',
    blob       => 'text',
    mediumblob => 'text',
    longblob   => 'text',
    enum       => 'text',
    set        => 'text',
    date       => 'text',
    datetime   => 'text',
    time       => 'text',
    timestamp  => 'text',
    year       => 'text',

    #
    # Oracle types
    #
    number     => 'keyword',
    char       => 'text',
    varchar2   => 'text',
    long       => 'keyword',
    CLOB       => 'text',
    date       => 'text',

    #
    # Sybase types
    #
    int        => 'keyword',
    money      => 'keyword',
    varchar    => 'text',
    datetime   => 'keyword',
    text       => 'text',
    real       => 'keyword',
    comment    => 'text',
    bit        => 'keyword',
    tinyint    => 'keyword',
    float      => 'keyword',
);

=head1 NAME

DBIx::Class::Indexer::WebService::Lucene - Automatic indexing of DBIx::Class objects via 
WebService::Lucene

=head1 SYNOPSIS

    package MySchema::Foo;
    
    use base qw( DBIx::Class );
    
    __PACKAGE__->load_components( qw( Indexed Core ) );
    __PACKAGE__->table('foo');
    __PACKAGE__->set_indexer('WebService::Lucene');
    __PACKAGE__->add_columns(
        foo_id => {
            data_type         => 'integer',
            is_auto_increment => 1
        },
        name => {
            data_type => 'varchar',
            size      => 10,
            indexed   => {
                type => 'text',
            }
        },
        location => {
            data_type => 'varchar',
            size      => 50,
            indexed   => 'text'
        }
    );
    
    __PACKAGE__->has_many( widgets => 'widget' );
    __PACKAGE__->add_index_fields(
        widget => {
            source => 'widgets.name'
            type   => 'unstored'
        },
        widget_updated => {
            source => 'widgets.ctime.epoch',
        },
        author => {
            source => sub {
                map {
                    join ' ', $_->first_name, $_->last_name
                } shift->authors
            },
        },
        all => {
            source => sub {
                my $self = shift;
                join ' ', map { $self->$_ } qw( name location );
            }
            type => 'unstored',
            role => 'default_field' # will be search if no field prefix
                                    # is specified
        }
    );
    
=head1 DESCRIPTION

This is a DBIx::Class component to make full-text indexing a seamless 
part of database objects. All that is required is the registration of
desired fields for the index. Notice that fields are not necessarily the
same as columns. For instance, suppose you have a schema representing
a film and its actors. The index representing the film table may have
a fields called 'actor' which can have multiple values, depending on
the number of actors associated with the film.
    
    package Film;
    
    __PACKAGE__->add_index_fields(
        actor => {
            type   => 'text',
            source => 'actors.name'
        },
    );
    
=head1 METHODS

=head2 new( \%connect_info, $source_class )

Instantiates a new Lucene Web Service indexer. 

=cut

sub new {
    my $class        = shift;
    my $connect_info = shift;
    my $source       = shift;
    
    my $self = bless { }, $class;
    $self->setup_fields( $source );

    my $server = $connect_info->{ server } || 'http://localhost:8080/lucene';
    $server    =~ s{/$}{};
    my $name   = $connect_info->{ index } || $source->table;
    my $index  = WebService::Lucene::Index->new( "${server}/${name}" );

    $self->setup_index( $source, $index ) unless $index->exists;    
    $self->_obj( $index );

    return $self;
}

=head2 setup_index( $source, $index )

If the index does not yet exist, this method will create it for you.

=cut

sub setup_index {
    my( $self, $source, $index ) = @_;
    
    my $pk      = $self->field_for_role( $source, 'identifier' );
    my $default = $source->indexer_connection_info->{ default_field }
        || $self->field_for_role( $source, 'default_field' )
        || $pk;
    my $name    = $index->name;
    my %properties = (
        'index.defaultoperator' => 'AND',
        'index.summary'         => $name,
        'index.title'           => $name,
        'field.<default>'       => $default,
        'field.identifier'      => $pk,
        'field.<title>'         => "[$pk]",
    );
    
    my $fields = $source->index_fields;

    # attempt to determine what field determines the mtime of a document
    if( my $mtime = $self->field_for_role( $source, 'updated' ) ) {
        $properties{ 'field.<modified>' } = $mtime;
    }
    
    # attempt to determine what field determines the title of a document
    if( my $title = $self->field_for_role( $source, 'title' ) ) {
        $properties{ 'field.<title>' } = "[$title]";
    }
        
    $index->properties_ref( \%properties );
    $index->create;
}

=head2 setup_fields( $source )

Normalizes the index fields so they all have hashref members with a 
"type" key at a minimum. It all attemps to figure out which field
will be used as the primary identifier and what field might be
used for the last updated column (optional).

=cut

sub setup_fields {
    my( $self, $source ) = @_;

    return if $self->_field_prep->{ $source };

    my $fields = $source->index_fields;
    my $pk_field;

    # normalize field defs
    for my $key ( keys %$fields ) {
        my $value = $fields->{ $key };
        if( !ref $value ) {
            # indexed => 'keyword'
            if( $value =~ m{\D} ) {
                $value = { type => $value };
            }
            # indexed => 1
            else {
                $value = { };
            }
        }
        
        if( !$value->{ type } ) {
            if( $source->has_column( $key ) and my $info = $source->column_info( $key ) ) {
                $value->{ type } = $FIELD_TYPES{ $info->{ data_type } } || 'text';
            }
        }
        
        if( exists $value->{ role } and $value->{ role } eq 'identifier' ) {
            $pk_field = $key;
        }
        
        $fields->{ $key } = $value;
    } 

    # ensure there's an identifier
    if( !$pk_field ) {
        my( $pk, $multipk ) = $source->primary_columns;
        die 'Indexing can only handle single column primary keys' if $multipk;
        $pk_field = $pk;
    }

    # look for a field to use for "updated"
    my $mtime_cols = $source->can('mtime_columns') ? $source->mtime_columns : [];
    if( $source->can( '__column_timestamp_triggers' ) ) {
        push @$mtime_cols, @{ $source->__column_timestamp_triggers->{ on_update } };
    }
    for my $mtime_col ( @$mtime_cols ) {
        next unless $fields->{ $mtime_col };
        $fields->{ $mtime_col }->{ role   } = 'updated';
        $fields->{ $mtime_col }->{ source } = 'mtime.epoch';
        last;
    }

    # set the primary key's field type to keyword
    $fields->{ $pk_field }->{ type } = 'keyword';
    $fields->{ $pk_field }->{ role } = 'identifier';

    $self->_field_prep->{ $source } = 1;
}

=head2 field_for_role( $source, $role )

Looks through the field list for a member with role equal to C<$role>.

=cut

sub field_for_role {
    my( $self, $source, $role ) = @_;
    my $fields = $source->index_fields;

    for my $key ( keys %$fields ) {
        return $key if
            exists $fields->{ $key }->{ role }
            and $fields->{ $key }->{ role } eq $role;
    }
    
    return;
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

=head2 as_document( [ $document ] )

If a document is passed to the method, it will replaces the document's
current fields with those outlined by the source's registered fields.
If no document is passed, it will construct a new
WebService::Lucene::Document object, populate it, and return it.

=cut

sub as_document {
    my( $self, $object, $document ) = @_;
    $document ||= WebService::Lucene::Document->new;

    # this is basically a no-op if it's already been done
    # but it needs to be done in case the same indexer is
    # used for multiple sources
    $self->setup_fields( ref $object );
    
    my $fields = $object->index_fields;

    # for each field...
    for my $name ( keys %$fields ) {
        my $info    = $fields->{$name};
        my $type    = $info->{type} || 'text';
        my @values  = $self->value_for_field( $object, $name );

        # make all those fields
        for my $value ( @values ) {
            my $field = WebService::Lucene::Field->new( {
                name  => $name,
                value => $value,
                type  => $type,
            } );
            
            $document->add( $field );
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
    my $index  = $self->_obj;

    $self->setup_fields( ref $object );
    my $id = $self->value_for_field( $object, $self->field_for_role( ref $object, 'identifier' ) );
    
    if ( my $document = eval { $index->get_document( $id ) } ) {
        $document->delete;
    }
}

=head2 update_or_create_document( $object )

Will either update or add a document to the index, depending
on its existence in the index.

=cut

sub update_or_create_document {
    my $self   = shift;
    my $object = shift;
    my $index  = $self->_obj;

    $self->setup_fields( ref $object );
    my $id = $self->value_for_field( $object, $self->field_for_role( ref $object, 'identifier' ) );

    if ( my $document = eval { $index->get_document( $id ) } ) {
        $document->clear_fields;
        $self->as_document( $object, $document );
        $document->update;
    }
    else {
        $index->add_document( $self->as_document( $object ) );
    }
}

=head1 SEE ALSO

=over 4

=item * DBIx::Class

=item * DBIx::Class::Indexed

=item * WebService::Lucene

=item * The Lucene Web Service (http://www.lucene-ws.net/)

=back

=head1 AUTHOR

=over 4

=item * Adam Paynter E<lt>adapay@cpan.orgE<gt>

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Adam Paynter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
