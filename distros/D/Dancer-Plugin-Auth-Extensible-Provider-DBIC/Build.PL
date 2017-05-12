
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Crypt::SaltedHash" => 0,
    "DBIx::Class::Core" => 0,
    "DBIx::Class::Schema" => 0,
    "Dancer::Plugin::Auth::Extensible" => 0,
    "Dancer::Test" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.88",
    "warnings" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "authenticate via DBIx::Class",
  "dist_author" => [
    "Yanick Champoux <yanick\@cpan.org>"
  ],
  "dist_name" => "Dancer-Plugin-Auth-Extensible-Provider-DBIC",
  "dist_version" => "0.1.3",
  "license" => "perl",
  "module_name" => "Dancer::Plugin::Auth::Extensible::Provider::DBIC",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Dancer" => 0,
    "Dancer::Plugin::Auth::Extensible::Provider::Base" => 0,
    "Dancer::Plugin::DBIC" => 0,
    "base" => 0,
    "strict" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
