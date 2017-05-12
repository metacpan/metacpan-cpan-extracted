
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "DBIx::Class::Core" => 0,
    "DBIx::Class::Schema" => 0,
    "DDP" => 0,
    "Module::Build" => "0.3601",
    "Moose" => 0,
    "Test::DBIx::Class" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "perl" => "v5.14.2"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "dbic component generating accessors method to get data by a table pointing to a Lookup table (catalog of terms) in a efficient way (cache system)",
  "dist_author" => [
    "[Karl Forner <karl.forner\@gmail.com>, thomas Rubattel <rubattel\@cpan.org>]"
  ],
  "dist_name" => "DBIx-Class-LookupColumn",
  "dist_version" => "0.10",
  "license" => "perl",
  "module_name" => "DBIx::Class::LookupColumn",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Class::MOP" => 0,
    "DBIx::Class" => 0,
    "Data::Dumper" => 0,
    "Hash::FieldHash" => 0,
    "Hash::Merge::Simple" => 0,
    "Smart::Comments" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
