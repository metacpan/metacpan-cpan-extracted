#!/usr/bin/perl -w

=head1 Name

Class::DBI::DataMigration::Mapping::HasAToHasA - Map a single column in a
single row that represents a has_a relatsionship from the source database to a
single column in a single row that represents a has_a relationship in the
target database.

=head1 Synopsis

 # Assume:
 #   - we have SourceDB and TargetDB, with two slightly different
 #      schemata for keeping track of cars
 #   - in the source Car class, there's a has_a relationship called
 #      'body_colour' to a BodyColour object
 #   - in the target class, there's a has_a relationship called 'colour'
 #      to a Colour object
 #   - the 'name' field of a given Car's BodyColour should be used to find
 #      a Colour object in the target db, where the matching column is also 'name';
 #      this Colour object will be used to populate the has_a relationship in the
 #      target db

 my $mapping = Class::DBI::DataMigration::Mapping::HasAToHasA->new({
    target_class            => 'TargetDB::Colour',
    target_class_search_key => 'name',
    matching_source_key     => 'body_colour->name'
 });

 my $mapped_colour = $mapping->map('body_colour', $car);

 # ...$mapped_colour is now the Colour object in the target database that should
 # be used to populate the has_a relationship there. See also the sample yaml file in
 # Class::DBI::DataMigration::Migrator for an example of how this would be configured.

=head1 Description

A Class representing the mapping between a single column in a single row that
represents a has_a relatsionship from the source database to a single column in
a single row that represents a has_a relationship in the target database.

=cut

use strict;

package Class::DBI::DataMigration::Mapping::HasAToHasA;

use base qw/Class::DBI::DataMigration::Mapping/;
use Carp;

__PACKAGE__->mk_accessors(qw/
    target_class
    target_class_search_key
    matching_source_key
    target_allows_null
    default_target_search_key_value
/);

=head1 Methods

=head2 target_class

Accessor/mutator for the entity in which the target database object
representing our has_a releationship will be found.

=head2 target_class_search_key

Accessor/mutator for the key into the target entity class which should be used
to search for the object representing the has_a relationship.

=head2 matching_source_key

Accessor/mutator for the key into the source object we are mapping that should
be used to search for a matching value via the target class search key in the
target entity class.

=head2 target_allows_null

Accessor/mutator for a true or false value indicating whether it is an error
to be unable to find a matching object in the target has_a entity class; if set
to false, an error will be reported if no matching object is found at map()
time.

=head2 default_target_search_key_value

Accessor/mutator for a value which, if supplied, will be used as the default value
for searching in the target has_a class when no target has_a object can be found.

=head2 map

Given a primary key into our source entity, and an object from our source
class, attempt to find an object in the target has_a entity that matches the
object returned by calling our matching_source_key on the source object.

If this search fails, and target_allows_null is false, we try again, using our
default_target_search_key_value, if it is defined. If we still haven't found an
object in the target database, we confess with an error.

An error is also confessed if at any point we find more than one matching target
has_a object.

=cut

# subs:

sub map {
    my ($self, $source_key, $source_object) = @_;

    my $source_class = ref $source_object;
    eval "require $source_class" unless $source_class->can('new');
    confess $@ if $@;
    eval "require " . $self->target_class unless $self->target_class->can('new');
    confess $@ if $@;

    my $value = eval 'return $source_object->' . $self->matching_source_key;
    confess $@ if $@;

    my @target_class_objs = $self->target_class->search(
        $self->target_class_search_key => $value
    );


    unless (@target_class_objs == 1) {

        if (@target_class_objs < 1) {
            unless ($self->target_allows_null) {

                if (defined $self->default_target_search_key_value) {
                    @target_class_objs = $self->target_class->search(
                        $self->target_class_search_key =>
                            $self->default_target_search_key_value
                    );
                }

                confess
                    'no target object or multiple target objects found in ' .  $self->target_class .
                    ' for search key "' . $self->target_class_search_key .
                    '" with value "' . $value . '"' .
                    ($self->default_target_search_key_value ?
                        '-- even tried default value "' .
                            $self->default_target_search_key_value . '"' : '')
                    unless (@target_class_objs > 0);
            }

        }

        if (@target_class_objs > 1) {
            confess 'multiple target objects found in ' . $self->target_class . '
                for search key "' . $self->target_class_search_key .
                '" with value "' . $value . '"';
        }

    } else {
        Carp::Assert::should(ref($target_class_objs[0]), $self->target_class)
            if $Carp::Assert::DEBUG;
    }

    return $target_class_objs[0];
}

=begin testing

use lib 't/testlib';

# loading this will dynamically set up the test source/target db's (but they
# will be empty; see below...):
use DMTestSetup;

use_ok('Class::DBI::DataMigration::Mapping::HasAToHasA');
can_ok('Class::DBI::DataMigration::Mapping::HasAToHasA', 'map');

# create sample data:

my $source_grey = SourceDB::BodyColour->create({
    name => 'grey'
});

my $target_grey = TargetDB::Colour->create({
    name => 'grey'
});

my $car = SourceDB::Car->create({
        make        => 'Chevrolet',
        model       => 'Caprice Classic',
        model_year  => '1989',
        body_colour => $source_grey
});

# create & test a HasAToHasA mapping: 

my $mapping = Class::DBI::DataMigration::Mapping::HasAToHasA->new({
    target_class            => 'TargetDB::Colour',
    target_class_search_key => 'name',
    matching_source_key     => 'body_colour->name'
});

my $mapped_colour = $mapping->map('body_colour', $car);

is($mapped_colour->name, $source_grey->name, 'Test mapping');

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


