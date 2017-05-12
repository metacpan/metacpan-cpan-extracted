
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
  "dist_abstract" => "A wrapper around autossh.",
  "dist_author" => [
    "DBR <dbr\@cpan.org>"
  ],
  "dist_name" => "App-assh",
  "dist_version" => "1.1.2",
  "license" => "unrestricted",
  "module_name" => "App::assh",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "FindBin" => 0,
    "Moo" => 0,
    "MooX::Options" => 0,
    "MooX::Types::MooseLike::Base" => 0,
    "lib" => 0,
    "methods" => 0,
    "perl" => "5.010",
    "strict" => 0,
    "true" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/assh",
    "bin/assh"
  ],
  "test_requires" => {
    "Carp" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec::Functions" => 0,
    "List::Util" => 0,
    "Scalar::Util" => 0,
    "Test::CheckDeps" => "0.006",
    "Test::More" => "0.94",
    "Test::UseAllModules" => 0
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
