#!perl -w

use Test::More tests => 3;

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

my $Original_File = 'HasAToHasA.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 157 /Users/dan/work/dan/Class-DBI-DataMigration/lib/Class/DBI/DataMigration/Mapping/HasAToHasA.pm

SKIP: {

eval 'require Class::DBI::Test::TempDB';
skip 'Class::DBI::Test::TempDB not installed' if $@;

use lib 't/testlib';

# loading this will dynamically set up the test source/target db's (but they
# will be empty; see below...):
require DMTestSetup;

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

} # SKIP block


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

