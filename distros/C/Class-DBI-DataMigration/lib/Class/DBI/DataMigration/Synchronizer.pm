#!/usr/bin/perl -w

=head1 Name

Class::DBI::DataMigration::Synchronizer

=head1 Synopsis

 use Class::DBI::DataMigration::Synchronizer;

 my $synch = Class::DBI::DataMigration::Synchronizer->new(
    search_criteria => \%search_criteria);
 my $synched_objects = $synch->synchronize;

=head1 Description

Class::DBI::DataMigration::Synchronizer - Keep records synchronized between
source and target databases.

=for testing
use_ok('Class::DBI::DataMigration::Synchronizer');

=cut

use strict;

package Class::DBI::DataMigration::Synchronizer;

use base qw/Class::Accessor Class::Data::Inheritable/;
use Class::DBI::DataMigration::Migrator;
use Carp;
use Carp::Assert;

use Getopt::Long;

__PACKAGE__->mk_classdata('_criteria_args');
__PACKAGE__->mk_classdata('config_path');
__PACKAGE__->config_path('./');

sub _initialize {
    my $class = shift;
    $class->_criteria_args([]);
    GetOptions("table=s" => $class->_criteria_args);
    1;
}

__PACKAGE__->_initialize;


=head1 Methods

=head2 config_path

Class accessor/mutator for the directory in which our config.yaml can be found.
This config.yaml will be used to build a C<Class::DBI::DataMigration::Migrator>,
which we will then use to synchronize the appropriate data. Defaults to './'.

=head2 search_criteria

Accessor/mutator for a hashref of hashes of search criteria to use, per table,
to locate objects for migration between the source and target databases.

The hash should be keyed on source db CDBI class names, with hashrefs of
key/value pairs to search for in each class as values; these latter key/value
hashes will be used to search() each class. Classes whose values are empty
hashes will have retrieve_all() called on them -- that is, *all* objects in
that class will be migrated. For example:

 { 
    SourceClass1 => { 
        key1 => value1, 
        key2 => value2 
    },                                    # migrate objects in SourceClass1 that match
                                          # key1 => value1, key2 => value2

    SourceClass2 => {}                    # migrate all objects in SourceClass2
 }

=for testing
can_ok('Class::DBI::DataMigration::Synchronizer', 'search_criteria');

=cut

__PACKAGE__->mk_accessors(
    qw/search_criteria/
);

=head2 new

This constructor uses Getopt::Long to parse command-line arguments, producing a
search_criteria hash suitable for use at synchronize() time.

 --table=class1,key1,value1,key2,value2... --table=class2,key3,value3... --table=class3...

The keys and values supplied for each --table argument will be used to search()
the given class for objects to be migrated. If no keys/values are given, *all*
objects in the class (i.e., all rows in the table) will be migrated. So, in the
example above, the search_criteria hashref produced would be:

 {
    class1 => {
        key1 => value1,
        key2 => value2
    },

    class2 => {
        key3 => value3
    },

    class3 => {}
 }

Class/key/value lists must contain no spaces and be separated by commas, as in
the example above.

=begin testing

push @ARGV, '--table=class1,key1,value1,key2,value2',
'--table=class2,key3,value3', '--table=class3';

ok(Class::DBI::DataMigration::Synchronizer->_initialize);

my $synch = Class::DBI::DataMigration::Synchronizer->new;
is_deeply($synch->search_criteria, 
{
    class1 => {
        key1 => 'value1',
        key2 => 'value2'
    },

    class2 => {
        key3 => 'value3'
    },

    class3 => {}
 }
);

=end testing

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->search_criteria({});
    foreach(@{$class->_criteria_args}) {
        my ($class, %criteria) = split /,/;
        $self->search_criteria->{$class} = \%criteria;
    }

    return $self;
}

=head2 synchronize

Collect together all objects from the various CDBI classes matching our
search_criteria; build a migrator for our class's config.yaml file and
migrate the objects we've collected.

NB: our config.yaml file is expected to be found in config_path(), which defaults to ./.

=cut

sub synchronize {
    my ($self) = @_;
    my $class = ref($self) || $self;

    my @source_objects = $self->_collect_source_objects();

    open IN, ($class->config_path . 'config.yaml') or 
        confess "Couldn't open yaml config for data migration: $!";
    my $migrator = new Class::DBI::DataMigration::Migrator(join '', <IN>);
    return $migrator->migrate_objects(\@source_objects);
}

sub _collect_source_objects {
    my ($self) = @_;
    return unless $self->search_criteria;
    Carp::Assert::should(ref $self->search_criteria, 'HASH');
    my @results;
    while (my ($class, $criteria) = each %{$self->search_criteria}) {
        eval "require $class" unless $class->can('new');
        confess $@ if $@;
        Carp::Assert::should(ref $criteria, 'HASH');
        if (scalar(keys(%$criteria))) {
            push @results, $class->search(%$criteria);
        } else {
            @results = $class->retrieve_all;
        }
    }
    return @results;
}

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
