#!perl -w

use Test::More tests => 5;

package Catch;

sub TIEHANDLE {
    my($class, $var) = @_;
    return bless { var => $var }, $class;
}

sub PRINT  {
    my($self) = shift;
    ${'main::'.$self->{var}} .= join '', @_;
}

sub OPEN  {}    # XXX Hackery in case the user redirects
sub CLOSE {}    # XXX STDERR/STDOUT.  This is not the behavior we want.

sub READ {}
sub READLINE {}
sub GETC {}
sub BINMODE {}

my $Original_File = 'Migrator.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 258 /Users/dan/work/dan/Class-DBI-DataMigration/lib/Class/DBI/DataMigration/Migrator.pm

SKIP: {

eval 'require Class::DBI::Test::TempDB';
skip 'Class::DBI::Test::TempDB not installed' if $@;

use lib 't/testlib';

use YAML;
use Class::DBI::Loader;

require DMTestSetup; # set up empty test source/target db's and associated CDBI classes

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

} # SKIP block


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

