package DBIx::Class::Indexed;

use strict;
use warnings;
use Module::Load;

use base qw( DBIx::Class );

our $VERSION = '0.03';

__PACKAGE__->mk_classdata( _indexer                => undef );
__PACKAGE__->mk_classdata( indexer_connection_info => {} );
__PACKAGE__->mk_classdata( indexer_package         => undef );
__PACKAGE__->mk_classdata( index_fields            => {} );
__PACKAGE__->mk_classdata( index_on_insert         => 1 );
__PACKAGE__->mk_classdata( index_on_update         => 1 );
__PACKAGE__->mk_classdata( index_on_delete         => 1 );

=head1 NAME

DBIx::Class::Indexed - Index data via external indexing facilities.

=head1 SYNOPSIS
    
    package Foo;
    
    use base qw( DBIx::Class );
    
    __PACKAGE__->load_components( qw( Indexed Core ) );
    __PACKAGE__->set_indexer( 'WebService::Lucene', {
        server => 'http://localhost:8080/lucene/',
        index  => 'stuff',
    });
    
    __PACKAGE__->add_columns(
        foo_id => {
            data_type         => 'integer',
            is_auto_increment => 1,
        },
        name => {
            data_type => 'varchar',
            size      => 256,
            indexed   => 1,
        },
        description => {
            data_type => 'text',
            indexed  => 1,
        },
    );
    
=head1 ACCESSORS

=head2 indexer_package( [ $indexer ] )

Sets which indexer will be responsible for indexing this class' data. 
Corresponds to the package name after the DBIx::Class::Indexer prefix.

=head2 indexer_connection_info( [ \%info ] )

Sets the extra information passed to the indexer on instantiation.

=head2 index_on_insert

Determines whether or not DBIx::Class::Indexed will index the document 
when it is inserted.

=head2 index_on_update

Determines whether or not DBIx::Class::Indexed will index the document 
when it is updated.

=head2 index_on_delete

Determines whether or not DBIx::Class::Indexed will remove the document 
when it is deleted.

=head1 METHODS

=head2 indexer( )

Accessor for the indexer object; lazy loaded. 

=cut

sub indexer {
    my $self    = shift;
    my $schema  = $self->result_source->schema;
    my $key     = $self->indexer_connection_info->{ storage_key } || $self->table;

    $schema->{ _indexers } = {} unless $schema->{ _indexers };     

    my $indexer = $schema->{ _indexers }->{ $key };
    
    # lazy load the indexer
    if( !$indexer ) {
        my $name    = $self->indexer_package;
        my $package = "DBIx::Class::Indexer::$name";
        
        load $package;

        $indexer = $package->new( $self->indexer_connection_info, ref $self );
        $schema->{ _indexers }->{ $key } = $indexer;
    }

    return $indexer;
}

=head2 set_indexer( $name [, \%connection_info ] )

Set the indexer information. Connection information is stored in the C<indexer_connection_info> 
accessor and the package name is stored in C<indexer_package>.

=cut

sub set_indexer {
    my $class        = shift;
    my $name         = shift;
    my $connect_info = shift;
    
    $class->indexer_package( $name );
    $class->indexer_connection_info( $connect_info || {} );
}

=head2 insert( )

Sends the object to the indexer's C<insert> method, if C<index_on_insert> is true.

=cut

sub insert {
    my $self   = shift;
    my $result = $self->next::method( @_ );
    
    if ( $self->index_on_insert and my $indexer = $self->indexer ) {
        $indexer->insert( $self, @_ );
        
        if ( $self->is_changed ) {
            $result = $self->next::method( @_ );
        }
    }
    
    return $result;
}

=head2 update( )

Sends the object to the indexer's C<update> method, if C<index_on_update> is true.

=cut

sub update {
    my $self   = shift;
    my $result = $self->next::method( @_ );
    
    if ( $self->index_on_update and my $indexer = $self->indexer ) {
        $indexer->update( $self, @_ );
        
        if ( $self->is_changed ) {
            $result = $self->next::method( @_ );
        }
    }
    
    return $result;
}

=head2 delete( )

Sends the object to the indexer's C<delete> method, if C<index_on_delete> is true.

=cut

sub delete {
    my $self = shift;
    
    if ( $self->index_on_delete and my $indexer = $self->indexer ) {
        $indexer->delete( $self, @_ );
    }
    
    $self->next::method( @_ );
}

=head2 register_column ( $column, \%info )

Overrides DBIx::Class's C<register_column>. If %info contains
the key 'indexed', calls C<register_field>.

=cut

sub register_column {
    my( $class, $column, $info ) = @_;
    $class->next::method( $column, $info );
    
    if (exists $info->{ indexed }) {
        $class->register_field( $column => $info->{ indexed } );
    }
}

=head2 add_index_fields ( @fields )

Behaves similarly to DBIx::Class's C<add_columns>. Calls
C<register_field> underneath.

=cut

sub add_index_fields {
    my( $class, @fields ) = @_;
    my $fields = $class->index_fields;
    
    while ( my $field = shift @fields ) {
        # If next entry is { ... } use that for the column info, if not
        # use an empty hashref
        my $field_info = ref $fields[ 0 ] ? shift @fields : {};
        $class->register_field( $field, $field_info );
    }
}

=head2 register_field( $field, \%info )

Registers a field as indexed.

=cut

sub register_field {
    my( $class, $field, $info ) = @_;
    $class->index_fields->{ $field } = $info;
}

=head1 AUTHORS

=over 4

=item * Adam Paynter E<lt>adapay@cpan.orgE<gt>

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Adam Paynter, 2007-2011 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
