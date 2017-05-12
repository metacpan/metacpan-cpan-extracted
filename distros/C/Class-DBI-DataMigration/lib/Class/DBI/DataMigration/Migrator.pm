#!/usr/bin/perl -w

=head1 Name

Class::DBI::DataMigration::Migrator - Class that does the actual data migration
from a source database to a target database.

=head1 Synopsis

 use Class::DBI::DataMigration::Migrator;

 # Assume we've slurped config.yaml into $yaml (see below for config.yaml contents):
 my $migrator = new Class::DBI::DataMigration::Migrator($yaml);

 # Assume that @source_objs_to_migrate is a list of CDBI objects from
 # the source db that we want to migrate into the target db:
 my $migrated = $migrator->migrate_objects(\@source_objs_to_migrate); 

 # Target db now contains newly-migrated objects.
 # Also, $migrated is a hashref to a list of the migrated objects.

 # ... Meanwhile, in config.yaml:
 #
 # This is an example that migrates from the car table in a source database,
 # called src_db, to the automobile table in a target database, called trg_db.
 #
 # The source car table has make, model, model_year and body_colour columns
 # (body_colour being a has_a relationship to a body_colour table).
 #
 # The target automobile table has brand, type, year, and colour columns
 # corresponding to the respective source columns.
 #
 # For mapping between the has_a relationships (body_colour and colour), a
 # subclass of Mapping, HasAToHasA, is used (see
 # Class::DBI::DataMigration::Mapping::HasAToHasA.pm for details).

 ---
 source_connection:
   base_class: SourceDB::DBI
   db_name: dbi:mysql:src_db
   username: src_uname
   password: src_pass
 target_connection:
   base_class: TargetDB::DBI
   db_name: dbi:mysql:trg_db
   username: trg_uname
   password: trg_pass
 entities:
   SourceDB::DBI::Car:
     mappings:
       make:
         target_key: brand
       model:
         target_key: type
       model_year:
         target_key: year
       body_colour:
         target_key: colour
         mapping:
           class: Class::DBI::DataMigration::Mapping::HasAToHasA
           config:
             target_class: TargetDB::DBI::Colour
             target_class_search_key: name
             matching_source_key: body_colour->name
     target_cdbi_class: TargetDB::DBI::Automobile

=cut

use strict;

package Class::DBI::DataMigration::Migrator;

use base 'Class::Accessor';

use YAML;
use Carp;
use Carp::Assert;

__PACKAGE__->mk_accessors(
    qw/entities mappers/
);

=head1 Methods

=head2 new

 my $migrator = Class::DBI::DataMigration::Migrator->new($yaml);

Create and initialize a new instance of this class. Expects a YAML
configuration string (see example above) that will be used to initialize the
new object's source and target database connections, its entities hash, and its
mappers.

=head2 entities

Accessor/mutator for a hashref of hashrefs, describing the ways in which data
in entities (tables) in the source database will get migrated by this migrator
to data in the entities in the target database.

=head2 mappers

Accessor/mutator for a hashref of mapper objects (see Class::DBI::Mapper),
keyed on the various source database entity classes from which this migrator
will migrate data.

=cut

sub new {
    my ($class, $yaml) = @_;
    my $self = {};
    bless $self, $class;
    $self->mappers({});
    $self->_initialize(Load($yaml));
    return $self;
}

=head2 migrate_objects

Expects a reference to a list of source database objects to be migrated.
Iterates through the list and calls $self->map() with each source object,
collecting and returning a reference to the list of resultant target database
objects.

=cut

sub migrate_objects {
    my ($self, $to_migrate) = @_;

    # iterate through the list referred to by $to_migrate, mapping each object as we go:
    my @migrated = ();
    foreach my $obj (@$to_migrate) {
        my $newobj = $self->map($obj); # will create a target db object and return it, or return an error string
        confess $newobj unless (ref($newobj));
        push @migrated, $newobj;
    }

    return \@migrated;
}

=head2 map

Given a source database object, looks for a mapper object for that object's
class in the mappers hash, and calls map() on it with the source object. Returns
the result of that map() call (presumably a target database object), or an error
message if no suitable mapper could be found.

=cut

sub map {
    my ($self, $to_map) = @_;

    # find appropriate mapper and use it
    my $mapper = $self->mappers->{ref($to_map)}
        or return __PACKAGE__ . " couldn't find mapper for object of class: " . ref($to_map);
    return $mapper->map($to_map);
}

sub _initialize {
    my ($self, $config) = @_;

    $self->_initialize_connection($config->{source_connection}) if $config->{source_connection};
    $self->_initialize_connection($config->{target_connection}) if $config->{target_connection};
    $self->entities($config->{entities});
    $self->_build_mappers();
}

sub _initialize_connection {
    my ($self, $config) = @_;

    eval "require $config->{base_class}";
    carp("Error requiring $config->{base_class}: " . $@) if $@;

    $config->{base_class}->set_db(
        'Main',
        $config->{db_name},
        $config->{username},
        $config->{password}) 
    unless $config->{base_class}->db_Main; # don't overwrite db connection 
                                           # if it's already in place
}

my $DEFAULT_MAPPER = { class => 'Class::DBI::DataMigration::Mapper' };

sub _build_mappers {
    my $self = shift;

    foreach my $key (keys %{$self->entities}) {
        # Each key should be a cdbi class name in the source db:
        __require_once($key);

        my $entity = $self->entities->{$key};
        my $mapper = $self->_build_mapper(

            ($entity->{mapper} ? 
                $entity->{mapper} : 
                $DEFAULT_MAPPER),

            $entity->{target_cdbi_class},
            $entity->{mappings} 

        );

        $self->mappers->{$key} = $mapper;
    }
}

sub _build_mapper {
    my ($self, $mapper, $target_cdbi_class, $mappings_hash) = @_;
    my $default_mapping_class = 'Class::DBI::DataMigration::Mapping';
    my $target_keys = {};
    my $mappings = {};

    Carp::Assert::should(ref($mappings_hash), 'HASH')
        if $Carp::Assert::DEBUG;

    while (my ($key, $hash) = each %$mappings_hash) {
        $target_keys->{$key} = $hash->{target_key};

        if (my $mapping_hash = $hash->{mapping}) {

            my $mapping_class = (exists $mapping_hash->{class}) ?
                                    $mapping_hash->{class}      :
                                    $default_mapping_class;
            __require_once($mapping_class);

            # In the default case, there will be no config, but the base
            # Mapping class doesn't need any, so that's ok:
            $mappings->{$key} = $mapping_class->new($mapping_hash->{config});
        } else {
            __require_once($default_mapping_class);
            $mappings->{$key} = $default_mapping_class->new;
        }
    }

    $mapper->{class} = $DEFAULT_MAPPER->{class} unless $mapper->{class};
    __require_once($mapper->{class});
    return $mapper->{class}->new({
        target_cdbi_class   => $target_cdbi_class,
        target_keys         => $target_keys,
        target_search_keys  => $mapper->{target_search_keys},
        mappings            => $mappings
    });
}

sub __require_once {
    # only require a package if it's not already loaded
    # (useful for not require'ing modules that have been dynamically 
    # generated, and whose .pm files don't actually exist):
    my $pkg = shift;
    unless (defined %{"$pkg\::"}) {
        eval "require $pkg";
        carp $@ and return 0 if $@;
    }

    return 1;
}

=begin testing

use lib 't/testlib';

use YAML;
use Class::DBI::Loader;

use DMTestSetup; # set up empty test source/target db's and associated CDBI classes

use_ok('Class::DBI::DataMigration::Migrator');
can_ok('Class::DBI::DataMigration::Migrator', 'entities');
can_ok('Class::DBI::DataMigration::Migrator', 'mappers');

# Start filling source data:

my $source_grey = SourceDB::BodyColour->create({
    name => 'grey'
});

my $target_grey = TargetDB::Colour->create({
    name => 'grey'
});

# Build a reference list to check the migrated data against later:

my @reference = (

    {
        make => 'Chevrolet',
        model => 'Caprice Classic',
        model_year => '1989',
        body_colour => $source_grey
    },

    {
        make => 'Jaguar',
        model => 'XJS',
        model_year => '1959',
        body_colour => $source_grey
    },

    {
        make => 'Plymouth',
        model => 'Reliant',
        model_year => '1983',
        body_colour => $source_grey
    }

);


foreach (@reference) {
    SourceDB::Car->create($_);
}

# simulate a config file that maps between our source and target db's (we don't
# need to supply connection info -- see DMTestBase.pm):

my $yaml = <<'...';
---
entities:
  SourceDB::Car:
    mappings:
      make: 
        target_key: brand 
      model: 
        target_key: type
      model_year: 
        target_key: year
      body_colour:
        target_key: colour
        mapping:
          class: Class::DBI::DataMigration::Mapping::HasAToHasA
          config:
            target_class: TargetDB::Colour
            target_class_search_key: name
            matching_source_key: body_colour->name
    target_cdbi_class: TargetDB::Automobile
...

# now do the actual migration:

ok(my $migrator = new Class::DBI::DataMigration::Migrator($yaml), 'migrator construction');
my @objs = SourceDB::Car->retrieve_all;
my $migrated = $migrator->migrate_objects(\@objs);

# finally, check the migrated data against our reference list; to do this, we
# set up two parallel formatted structures -- arrays of hashes which *should*
# have the same keys and values if the data migrated correctly -- and then we
# can use eq_set() to check them:

@formatted_mig = ();
foreach (@$migrated) {
    my $hashref = {
        make        => $_->brand,
        model       => $_->type,
        model_year  => $_->year,        
        body_colour => $_->colour->name
    };
    push @formatted_mig, $hashref;
}

my @formatted_ref =();
foreach (@reference) {
    my $hashref = {
        make        => $_->{make},
        model       => $_->{model},
        model_year  => $_->{model_year},
        body_colour => $_->{body_colour}->name
    };
    push @formatted_ref, $hashref;
}

ok(eq_set(\@formatted_ref, \@formatted_mig), 'data migrated correctly') or
    diag "Data didn't migrate correctly; reference = \n" . Dump(\@formatted_ref) . 
        "\nmigrated = \n" . Dump(\@formatted_mig);

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


