
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
  "dist_abstract" => "Python like Syntax Module",
  "dist_author" => [
    "Madison Koenig"
  ],
  "dist_name" => "Acme-Syntax-Python",
  "dist_version" => "0.02",
  "license" => "restrictive",
  "module_name" => "Acme::Syntax::Python",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Filter::Util::Call" => 0,
    "strict" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {}
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
