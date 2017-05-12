package Collection;

#$Id$

=head1 NAME

Collection - CRUD framework

=head1 SYNOPSIS

    package MyCollection;
    use Collection;
    @MyCollection::ISA = qw(Collection);

=head1 DESCRIPTION

A collection - sometimes called a container - is simply an object that groups multiple elements into a single unit. I<Collection> are used to store, retrieve, manipulate, and communicate aggregate data.

The primary advantages of a I<Collection> framework are that it reduces programming effort by providing useful data structures and algorithms so you don't have to write them yourself.


The I<Collection> framework consists of:

=over 2

=item * Wrapper Implementations - Add functionality, such as mirroring and lazy load, to other implementations.

=item * Algorithms - methods that perform useful functions, such as caching.

=back

This module has a task - to be a base class for ather Collections.
You can inherit the methods B<_create>, B<_delete>, B<_fetch>, B<_store> and may be B<_prepare_record> for new source of data. As you see this is similar to B<CRUD> (Create - Read - Update- Delete).

Sample:

        my $col = new MyCollection:: <some params>;
        #fetch objects or data by keys
        my $data = $col->fetch(1,2,3,4,5);
        #do something
        foreach my $item ( values %$data) {
            $_->attr->{inc} ++
        }
        #You can use "lazy" functionality
        my $not_actualy_fetch = $col->get_lazy(6,7,8,9);
        #store changed data or objects
        $col->store;
        #free memory
        $col->release;


Sample from L<Collection::AutoSQL>:

 my $beers = new Collection::AutoSQL::
  dbh     => $dbh,          #database connect
  table   => 'beers',       #table name
  field   => 'bid',         #key field (IDs), usually primary,autoincrement
  cut_key => 1;             #delete field 'bid' from readed records,
    
    my $heineken = $beers->fetch_one(1);
    #SELECT * FROM beers WHERE bid in (1)


Sample from L<Collection::Memcached>:

    use Collection::Memcached;
    use Cache::Memcached;
    $memd = new Cache::Memcached {
    'servers' => [ "127.0.0.1:11211" ],
    'debug' => 0,
    'compress_threshold' => 10_000,
  };
  my $collection = new Collection::Memcached:: $memd;
  my $collection_prefix = new Collection::Memcached:: $memd, 'prefix';

=head1 METHODS

=cut

use strict;
use warnings;
use Carp;
use Data::Dumper;
use Collection::Utl::ActiveRecord;
use Collection::Utl::Base;
use Collection::Utl::LazyObject;
@Collection::ISA     = qw(Collection::Utl::Base);
$Collection::VERSION = '0.58';
attributes qw( _obj_cache  _on_store _on_create _on_delete);

sub _init {
    my $self = shift;
    my %arg  = @_;
    $self->_obj_cache( {} );
    $self->_on_store( $arg{on_store} );
    $self->_on_create( $arg{on_create} );
    $self->_on_delete( $arg{on_delete} );
    $self->SUPER::_init(@_);
}

=head2 _store( {ID1 => <ref to object1>[, ID2 => <ref to object2>, ...]} )

Method for store changed objects. Called with ref to hash :

 {
    ID1 => <reference to object1>
    [,ID2 => <reference to object2>,...]
 }

=cut

sub _store {
    my $pkg = ref $_[0];
    croak "$pkg doesn't define an _store method";
}

=head2 _fetch(ID1[, ID2, ...])

Read data for given IDs. Must return reference to hash, where keys is IDs,
values is readed data.
For example:

    return {1=>[1..3],2=>[5..6]}
    
=cut

sub _fetch {
    my $pkg = ref $_[0];
    croak "$pkg doesn't define an _fetch method";
}

=head2 _create(<user defined>)

Create recods in data storage.

Parametrs:

    user defined format

Result:
Must return reference to hash, where keys is IDs, values is create records of data

=cut

sub _create {
    my $pkg = ref $_[0];
    croak "$pkg doesn't define an _create method";
}

=head2 _delete(ID1[, ID2, ...]) 

Delete records in data storage for given IDs.

Parametrs:
array id IDs

    ID1, ID2, ...

or array of refs to HASHes

    {  id=>ID1 }, {id => ID2 }, ...
 

Format of parametrs depend method L<delete>

=cut

sub _delete {
    my $pkg = ref $_[0];
    croak "$pkg doesn't define an _delete method";
}

=head2 _prepare_record( ID1, <reference to readed by _create record>)

Called before insert readed objects into collection.
Must return ref to data or object, which will insert to callection.

=cut

sub _prepare_record {
    my ( $self, $key, $ref ) = @_;
    return $ref;
}

=head2 create(<user defined>)

Public method for create objects.


=cut

sub create {
    my $self     = shift;
    my $coll_ref = $self->_obj_cache();
    my $results  = $self->_create(@_);
    my $created = $self->fetch( keys %$results );
    if (%$created) {
      if ( ref( $self->_on_create ) eq 'CODE' ) {
        $self->_on_create()->(%$created);
      }
    }
    return $created
}

=head2 fetch_one(ID1), get_one(ID1)

Public methods. Fetch object from collection for given ID.
Return ref to objects or undef unless exists.

=cut

sub get_one {
    my $self = shift;
    return $self->fetch_one(@_);
}

sub fetch_one {
    my ( $self, $id ) = @_;
    my $res;
    if ( my $item_refs = $self->fetch($id) ) {
        $res = $item_refs->{$id};
    }
    return $res;
}

=head2 fetch(ID1 [, ID2, ...]) , get(ID1 [, ID2, ...])

Public methods. Fetch objects from collection for given IDs.
Return ref to HASH, where where keys is IDs, values is objects refs.


Parametrs:


=cut

sub get {
    my $self = shift;
    return $self->fetch(@_)
}

sub fetch {
    my $self     = shift;
    my @ids      = ();
    my $coll_ref = $self->_obj_cache();
    my @fetch    = ();
    my @exists   = ();
    my @fetched = ();
    foreach my $id (@_) {
        next
          unless defined $id;

        #push nonexists or references to @fetch
        if ( exists $coll_ref->{$id} ) {
            push @exists, $id;
            next;
        }
        push @fetch, $id;
    }
    if ( scalar(@fetch)
        && ( my $results = $self->_fetch(@fetch) ) )
    {
        while ( my ( $key, $val ) = each %{$results} ) {
            push @fetched, $key;
            #filter already loaded
            next if exists $coll_ref->{$key};

            #bless for loaded
            my $ref = $self->_prepare_record( $key, $results->{$key} );
            if ( ref($ref) ) {
                $coll_ref->{$key} = $ref;

                #store loaded keys
                push @exists, $key;
            } else {
                warn "Fail prepare for $key";
            }
        }
    }
    my %result = ();
    foreach my $key (@exists, @fetched) {
        $result{$key} = $coll_ref->{$key};
    }
    return \%result;
}

=head2 release(ID1[, ID2, ...])

Release from collection objects with IDs. Only delete given keys from collection or all if empty

=cut

sub release {
    my $self = shift;
    my (@ids) =  @_;
    my $coll_ref = $self->_obj_cache();
    unless (@ids) {
        my $res = [ keys %$coll_ref ];
        undef %{$coll_ref};
        return $res;
    }
    else {

        [
            map {
                delete $coll_ref->{ $_ };
                $_
              }
             @ids
        ];
    }    #else
}

=head2 store([ID1,[ID2,...]]) 

Call _store for changed objects.
Store all loaded objects without parameters:

    $simple_collection->store(); #store all changed

or (for 1,2,6 IDs )

    $simple_collection->store(1,2,6);

=cut

sub store {
    my $self      = shift;
    my @store_ids = @_;
    my $coll_ref  = $self->_obj_cache();
    @store_ids = keys %$coll_ref unless @store_ids;
    my %to_store;
    foreach my $id (@store_ids) {
        my $ref = $coll_ref->{$id};
        next unless ref($ref);
        if ( $self->is_record_changed($ref) ) {
           $to_store{$id} = $ref;
        }
    }
    if (%to_store) {
      if ( ref( $self->_on_store ) eq 'CODE' ) {
        $self->_on_store()->(%to_store );
      }
      $self->_store( \%to_store );
    }
}

=head2 delete(ID1[,ID2, ...])

Release from collections and delete from storage (by calling L<_delete>)
objects ID1,ID2...

    $simple_collection->delete(1,5,84);

=cut

sub delete {
    my $self = shift;
    my (@ids) =  @_;
    $self->release(@ids);
    if ( ref( $self->_on_delete ) eq 'CODE' ) {
        $self->_on_delete()->(@ids);
    }
    $self->_delete(@ids);
}

=head2 get_lazy(ID1)

Method for base support lazy load objects from data storage.
Not really return lazy object.

=cut

sub get_lazy {
    my ( $self, $id ) = @_;
    return new Collection::Utl::LazyObject:: sub { $self->fetch_one($id) };
}

sub is_record_changed {
    my $self = shift;
    my $record = shift || return;
    if ( ref($record) eq 'HASH' ) {
        return $record->{_changed};
=pod
        if ( my $obj = tied $value ) {
            push @changed, $id if $obj->_changed();
        }
        else {
            push @changed, $id if $value->{_changed};
        }
=cut

    }
    else {
        return $record->_changed() if UNIVERSAL::can($record, '_changed');
        return $self->is_record_changed( $record->_get_attr ) if UNIVERSAL::can($record, '_get_attr');
        carp "Can't check is record changed for class: " . ref($record);
    }

}

sub get_changed_id {
    my $self     = shift;
    my $coll_ref = $self->_obj_cache();
    my @changed  = ();
    while ( my ( $id, $value ) = each %$coll_ref ) {
            push @changed, $id if $self->is_record_changed($value)
    }
    return \@changed;
}

sub list_ids {
    my $pkg = ref $_[0];
    croak "$pkg doesn't define an list_ids method";
}
1;
__END__


=head1 SEE ALSO

Collection::Memcached, Collection::Mem, Collection::AutoSQL, README

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2008 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

