#!/usr/bin/perl -w

=head1 Name

Class::DBI::DataMigration::Mapper - Abstract class for mapping a single row in
the source database to a single row in the target database.

=head1 Synopsis

 use Class::DBI::DataMigration::Mapper;

 # ... later ...
 # Assume we've retrieved a $source_object of class Class from the source
 # database, and have assembled $mappings, a ref to an appropriate hash of
 # Class::DBI::DataMigration::Mapping objects:

 my $mapper = new Class::DBI::DataMigration::Mapper({
     target_cdbi_class => Class, 
     mappings => $mappings,
     target_search_keys => \@search_keys
 });

 my $new_db_object = $mapper->map($source_object);

 # ... now $new_db_object is in the new database ... 

=head1 Description

Class::DBI::DataMigration::Mapper is an abstract parent class for objects that
will map a single row at a time from the source database into a single row in
the new one. This is accomplished via Class::DBI; it's assumed that appropriate
classes exist representing the tables in the source and target databases. 

Mapping is accomplished using a hash of instances of
Class::DBI::DataMigration::Mapping objects.

=cut

use strict;

package Class::DBI::DataMigration::Mapper;

use Carp;
use base 'Class::Accessor';

__PACKAGE__->mk_accessors(
    qw/target_cdbi_class target_keys target_search_keys mappings/
);

=head1 Methods

=head2 mappings

Gets/sets a ref to a hash of Class::DBI::DataMigration::Mapping objects, keyed
on keys into the source class whose values will be used to produce values for
the target class.

=head2 target_cdbi_class

Gets/sets the target class in which to build a new object (or edit an existing
one) using the mappings and the source_object supplied to map()

=head2 target_keys

Gets/sets a ref to a hash that acts as a dictionary between the target and
source classes; the keys in this hash are keys into the target class, and the
values are the corresponding keys into the source class.

=head2 target_search_keys

Gets/sets a ref to a list of keys that will be used during mapping to search
for a target class object; if found, data from the matching source db object will
be used to edit the already-existing target db object. Otherwise, a new object will
be created in the target db. If target_search_keys is left empty, no searching
will be done, and all objects from the source db will be mirrored as new
objects in the target db.

=head2 map

Expects one parameter: the source_object in the source database whose data is to 
be mapped into an object in the target_cdbi_class.

This method causes the Mapper to iterate through its target_keys hash, calling
map() on each mapping with the source object and the source key under which it
was stored in the mappings hash. The returned values of each of these map()
calls are collected into a hash and used to do one of the following:

- if an object matching our target_search_keys in the data hash is found in
the target_cdbi_class (we use the first one found), that object is synchronized
using the rest of the data in the data hash and returned; and,

- if our target_search_keys is empty, or if no object matching the
those keys in the data hash exists in the target_cdbi_class, a new target
class object is created and returned.

If errors are encountered during this process, an error message is returned
instead of the affected object.

Subclasses may do something fancier.

=cut

sub map {
    my ($self, $source_object) = @_;  
    my %newobj_data = ();
    while ((my $source_key, my $target_key) = each %{$self->target_keys}) {
        my $mapping = $self->mappings->{$source_key}
            or confess "Couldn't retrieve mapping for source key $source_key";
        my $mapped = $mapping->map($source_key, $source_object);
        $newobj_data{$target_key} = $mapped if $target_key;
    }

    return $self->_create_or_edit_object($source_object, \%newobj_data);
}

sub _create_or_edit_object {
    # Useful for subclasses to override for post-mapping-processing
    # (in this version we don't use $source_object, but subclasses can).

    my ($self, $source_object, $newobj_data) = @_;

    eval "require " . $self->target_cdbi_class unless $self->target_cdbi_class->can('new');
    confess $@ if $@;

    if (($self->target_search_keys) and 
        (scalar(@{$self->target_search_keys}) > 0)) {
        my %search_criteria;
        foreach (@{$self->target_search_keys}) {
            $search_criteria{$_} = $newobj_data->{$_};
        }
        my $search_results = $self->target_cdbi_class->search(%search_criteria);
        my $search_obj = $search_results->next;
        my $errstr = '';
        if ($search_obj) {
            while (my ($key, $value) = each %$newobj_data) {
                if (ref $value) {
                    eval qq{ \$search_obj->$key($value) };
                } else {
                    # quote $value if it's not a reference:
                    eval qq{ \$search_obj->$key('$value') } if $value;
                }
                $errstr .= $@ if $@;
            }
            return $errstr if $errstr;
            return $search_obj;
        }
    }

    # If we've gotten this far, then either there were no target class search keys,
    # or no target class object matched the search keys. Either way, we create a new one.

    my $created_obj = eval { return $self->target_cdbi_class->create($newobj_data); };
    $created_obj = $@ if $@;
    return $created_obj;
}

=begin testing

use_ok('Class::DBI::DataMigration::Mapper');
can_ok('Class::DBI::DataMigration::Mapper', 'map');
can_ok('Class::DBI::DataMigration::Mapper', 'mappings');
can_ok('Class::DBI::DataMigration::Mapper', 'target_keys');
can_ok('Class::DBI::DataMigration::Mapper', 'target_cdbi_class');

=end testing

=head1 See Also

C<Class::DBI::DataMigration>

=head1 Author

Dan Friedman <lamech@cpan.org>

=head1 Copyright & License

Copyright 2004 Dan Friedman, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Please note that these modules are not products of or supported by the
employers of the various contributors to the code.

=cut

1;
