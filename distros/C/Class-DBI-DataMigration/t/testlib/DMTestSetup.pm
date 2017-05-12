#!/usr/bin/perl -w

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;

package DMTestSetup;

# loading these will dynamically set up the test source/target db's (but they
# will be empty):
use DMTestBase::SourceDB;
use DMTestBase::TargetDB;
use Class::DBI::Loader;

BEGIN {
    eval 'require Class::DBI::SQLite';
    die 'Class::DBI::SQLite is required for this module, but it does not appear to be installed.' if $@;
}

use base 'Class::Data::Inheritable';

__PACKAGE__->mk_classdata(qw/src_loader/);
__PACKAGE__->mk_classdata(qw/trg_loader/);

# automagically build CDBI classes for tables in source/target db's
# (whoo, shiny!):

__PACKAGE__->src_loader(Class::DBI::Loader->new(
    dsn => DMTestBase::SourceDB->dsn,
    namespace => 'SourceDB'
));

__PACKAGE__->trg_loader(Class::DBI::Loader->new(
    dsn => DMTestBase::TargetDB->dsn,
    namespace => 'TargetDB'
));

# create relationships:
SourceDB::Car->has_a(body_colour => 'SourceDB::BodyColour');
TargetDB::Automobile->has_a(colour => 'TargetDB::Colour');

=begin testing

use lib 't/testlib';

use_ok('DMTestSetup');

my $class = DMTestSetup->src_loader->find_class('car');
is($class, 'SourceDB::Car', 'Source database class');

$class = DMTestSetup->trg_loader->find_class('automobile');
is($class, 'TargetDB::Automobile', 'Target database class');

=end testing

=cut

1;


