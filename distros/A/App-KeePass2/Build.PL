
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
  "dist_abstract" => "KeePass2 commandline tools",
  "dist_author" => [
    "celogeek <me\@celogeek.com>"
  ],
  "dist_name" => "App-KeePass2",
  "dist_version" => "0.04",
  "license" => "perl",
  "module_name" => "App::KeePass2",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Data::Printer" => 0,
    "File::KeePass" => 0,
    "IO::Prompt" => 0,
    "Moo" => 0,
    "Moo::Role" => 0,
    "MooX::Options" => 0,
    "feature" => 0,
    "perl" => "5.010",
    "strict" => 0,
    "utf8::all" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/keepass2-cli"
  ],
  "test_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Scalar::Util" => 0,
    "Test::More" => "0.94",
    "perl" => "5.004"
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
