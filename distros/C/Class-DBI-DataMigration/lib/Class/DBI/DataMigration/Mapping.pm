#!/usr/bin/perl -w

=head1 Name

Class::DBI::DataMigration::Mapping - Abstract parent class for objects that
map a single column in a single row from the source database to the target
database.

=head1 Synopsis

 use Class::DBI::DataMigration::Mapping;

 # ... Later, when building $mappings hashref for use by a
 # Class::DBI::DataMigration::Mapper (which see for synopsis --
 # in this example, assume an appropriate @source_keys):

 foreach my $source_key (@source_keys) {
     $mappings{$source_key} = new Class::DBI::DataMigration::Mapping;
 }

 # ... Now we can assign $mappings to our Mapper ...

=head1 Description

Class::DBI::DataMigration::Mapping objects are used by
Class::DBI::DataMigration::Mapper objects to retrieve the values for
particular keys into source database objects; these will in turn be stored
under particular keys into newly-created target database objects.

=cut

use strict;

package Class::DBI::DataMigration::Mapping;

use base 'Class::Accessor';
use Carp;

=head1 Methods

=head2 map

Expects two parameters: the key into the source object, and the source object
itself. 

The default map() implementation simply uses the source key as a method call on
the source object and returns the value thus retrieved. 

Subclasses may do something fancier.

=cut

# subs:

sub map {
    my ($self, $source_key, $source_object) = @_;
    my $retval = eval qq{ return \$source_object->$source_key };
    $retval = $@ if $@;
    return $retval;
}

=begin testing

use_ok('Class::DBI::DataMigration::Mapping');
can_ok('Class::DBI::DataMigration::Mapping', 'map');

=end testing

=head1 Author

Dan Friedman, C<< <lamech@cpan.org> >>

=head1 Copyright & License

Copyright 2004 Dan Friedman, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Please note that these modules are not products of or supported by the
employers of the various contributors to the code.

=cut

1;


