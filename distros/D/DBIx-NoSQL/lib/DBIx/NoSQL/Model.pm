package DBIx::NoSQL::Model;
our $AUTHORITY = 'cpan:YANICK';
$DBIx::NoSQL::Model::VERSION = '0.0021';
use strict;
use warnings;

use Moose;
use Clone qw/ clone /;
use Digest::SHA qw/ sha1_hex /;
use Data::GUID;

has store => qw/ is ro required 1 weak_ref 1 /, handles => [qw/ storage /];
has name => qw/ reader name writer _name required 1 /;

has inflate => qw/ accessor _inflate isa Maybe[CodeRef] /;
has deflate => qw/ accessor _deflate isa Maybe[CodeRef] /;
sub inflator { return shift->_inflate( @_ ) }
sub deflator { return shift->_deflate( @_ ) }

has wrap => qw/ accessor _wrap /;
sub wrapper { return shift->_wrap( @_ ) }

has field_map => qw/ is ro lazy_build 1 isa HashRef /;
sub _build_field_map { {} }
sub field {
    require DBIx::NoSQL::Model::Field;
    my $self = shift;
    my $name = shift;

    return $self->field_map->{ $name } unless @_;

    die "Already have field ($name)" if $self->field_map->{ $name };
    my $field = $self->field_map->{ $name } = DBIx::NoSQL::Model::Field->new( name => $name );
    $field->setup( $self, @_ );
    return $field;
}
has _field2column_map => qw/ is ro /, default => sub { {} };
has _field2inflate_map => qw/ is ro /, default => sub { {} };
has _field2deflate_map => qw/ is ro /, default => sub { {} };

sub _store_set {
    my $self = shift;
    return $self->store->schema->resultset( '__Store__' );
}

sub _find {
    my $self = shift;
    my $key = shift;

    my $result = $self->_store_set->find(
        { __model__ => $self->name, __key__ => $key },
        { key => 'primary' },
    );

    return $result;
}

sub create {
    my $self = shift;
    return $self->create_object( @_ );
}

sub create_object {
    my $self = shift;
    my $target = shift;

    my $data = $self->deserialize( $target );
    my $entity = $self->inflate( $data );
    my $object = $self->wrap( $entity );

    return $object;
}

sub create_entity {
    my $self = shift;
    my $target = shift;

    my $data = $self->deserialize( $target );
    my $entity = $self->inflate( $data );

    return $entity;
}

sub create_data {
    my $self = shift;
    my $target = shift;

    my $data = $self->deserialize( $target );

    return $data;
}

sub set {
    my $self = shift;
    my $key = shift;
    my $target = shift;

    my ( $entity, $data, $value );

    if (ref($key) and !$target) {
      $target = $key;
      $key = Data::GUID->new->as_string;
    }

    if ( blessed $target ) {
        $entity = $self->unwrap( $target );
        $target = $entity;
    }

    if ( ref $target ) {
        $data = $self->deflate( $target );
        $target = $data;
    }

    $value = $self->serialize( $target );

    $self->_store_set->update_or_create(
        { __model__ => $self->name, __key__ => $key, __value__ => $value },
        { key => 'primary' },
    );

    if ( $self->searchable ) {
        $self->index->update( $key => $data );
    }
    return $key;
}

sub exists {
    my $self = shift;
    my $key = shift;

    return $self->_store_set->search({ __key__ => $key })->count;
}

sub get {
    my $self = shift;
    my $key = shift;

    my $result = $self->_find( $key );

    return unless $result;

    return $self->create_object( $result->get_column( '__value__' ) );
}

sub delete {
    my $self = shift;
    my $key = shift;

    my $result = $self->_find( $key );
    if ( $result ) {
        $result->delete;
    }

    if ( $self->searchable ) {
        $self->index->delete( $key );
    }
}

sub wrap {
    my $self = shift;
    my $entity = shift;

    if ( my $wrapper = $self->wrapper ) {
        if ( ref $wrapper eq 'CODE' ) {
            return $wrapper->( $entity );
        }
        else {
            return $wrapper->new( _entity => $entity );
        }
    }

    return $entity;
}

sub unwrap {
    my $self = shift;
    my $target = shift;

    return $target->_entity if blessed $target;
    return $target;
}

sub inflate {
    my $self = shift;
    my $data = shift;

    my $entity = clone $data;
    
    while( my ( $field, $inflator ) = each %{ $self->_field2inflate_map } ) {
        $entity->{ $field } = $inflator->( $entity->{ $field } ) if defined $entity->{ $field };
    }

    return $entity;
}

sub deflate {
    my $self = shift;
    my $target = shift;

    my $data = {};

    while( my ( $field, $deflator ) = each %{ $self->_field2deflate_map } ) {
        $data->{ $field } = $deflator->( $target->{ $field } ) if defined $target->{ $field };
    }

    while( my ( $key, $value ) = each %$target ) {
        next if exists $data->{ $key };
        $data->{ $key } = ref $value ? clone $value : $value;
    }

    return $data;
}

sub deserialize {
    my $self = shift;
    my $value  = shift;

    return $value if ref $value;

    my $data = $self->store->json->decode( $value );
    return $data;
}

sub serialize {
    my $self = shift;
    my $data = shift;

    return $data if ! ref $data;

    my $value = $self->store->json->encode( $data );
    return $value;
}

has searchable => qw/ is rw isa Bool default 1 /;

has index => qw/ reader _index lazy_build 1 /;
sub _build_index {
    require DBIx::NoSQL::Model::Index;
    my $self = shift;
    return unless $self->searchable;
    return DBIx::NoSQL::Model::Index->new( model => $self );
}

sub index {
    my $self = shift;
    return $self->_index unless @_;
    my $field_name = shift;
    return $self->field( $field_name => ( index => 1, @_ ) );
}

sub reindex {
    my $self = shift;

    return unless $self->searchable;

    if ( ! $self->index ) {
        $self->clear_index;
    }

    return $self->index->reindex;
}

sub search {
    my $self = shift;

    die "Trying to search on an unsearchable (unindexed) model" unless $self->searchable;

    return $self->index->search( @_ );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::NoSQL::Model

=head1 VERSION

version 0.0021

=head1 AUTHORS

=over 4

=item *

Robert Krimen <robertkrimen@gmail.com>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
