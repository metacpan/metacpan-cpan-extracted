
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Glues object frameworks together transparently",
  "dist_author" => [
    "Ken Williams <kwilliams\@cpan.org>"
  ],
  "dist_name" => "Class-Container",
  "dist_version" => "0.13",
  "license" => "perl",
  "module_name" => "Class::Container",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "B::Deparse" => 0,
    "Carp" => 0,
    "Params::Validate" => 0,
    "Scalar::Util" => 0,
    "strict" => 0,
    "vars" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "File::Spec" => 0,
    "Test" => 0
  }
);


my %fallback_build_requires = (
  "File::Spec" => 0,
  "Module::Build" => "0.3601",
  "Test" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
