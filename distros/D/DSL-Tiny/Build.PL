
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "A simple yet powerful DSL builder.",
  "dist_author" => [
    "George Hartzell <hartzell\@alerce.com>"
  ],
  "dist_name" => "DSL-Tiny",
  "dist_version" => "0.001",
  "license" => "perl",
  "module_name" => "DSL::Tiny",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Data::OptList" => 0,
    "Moo::Role" => 0,
    "MooX::Types::MooseLike::Base" => 0,
    "Params::Util" => 0,
    "Sub::Exporter" => 0,
    "Sub::Exporter::Util" => 0,
    "perl" => "5.014"
  },
  "script_files" => [],
  "test_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Moo" => 0,
    "Moose" => 0,
    "Test::Deep" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
