
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "DBIx::Class::InflateColumn::Serializer" => 0,
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "DBIx::Class::InflateColumn::Serializer::CompressJSON - JSON compressed Inflator",
  "dist_author" => [
    "Baptiste Fosse <baptiste\@weborama.com>"
  ],
  "dist_name" => "DBIx-Class-InflateColumn-Serializer-CompressJSON",
  "dist_version" => "0.004",
  "license" => "restrictive",
  "module_name" => "DBIx::Class::InflateColumn::Serializer::CompressJSON",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Compress::Zlib" => 0,
    "DBIx::Class::InflateColumn::Serializer" => 0,
    "JSON" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
