
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "DBICx::TestDatabase" => 0,
    "DBIx::Class::Core" => 0,
    "DBIx::Class::InflateColumn::Serializer" => 0,
    "DBIx::Class::InflateColumn::Serializer::Hstore" => 0,
    "DBIx::Class::InflateColumn::Serializer::JSON" => 0,
    "DBIx::Class::Schema" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "JSON::MaybeXS" => 0,
    "Module::Build" => "0.3601",
    "Moose" => 0,
    "MooseX::MarkAsMethods" => 0,
    "MooseX::NonMoose" => 0,
    "Pg::hstore" => 0,
    "Test::Class" => 0,
    "Test::Exception" => 0,
    "Test::More" => "0.88",
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Parameterized Moose role which provides accessor methods for values stored in a hash-like structure",
  "dist_author" => [
    "Manfred Stock <mstock\@cpan.org>"
  ],
  "dist_name" => "DBIx-Class-InflateColumn-Serializer-Role-HashContentAccessor",
  "dist_version" => "0.001000",
  "license" => "perl",
  "module_name" => "DBIx::Class::InflateColumn::Serializer::Role::HashContentAccessor",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "MooseX::Role::Parameterized" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
