
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
  "dist_abstract" => "CONVERT MRC TO TBX-BASIC",
  "dist_author" => [
    "Nathan Rasmussen, Nathan Glenn <garfieldnate\@gmail.com>"
  ],
  "dist_name" => "Convert-MRC",
  "dist_version" => "4.03",
  "license" => "perl",
  "module_name" => "Convert::MRC",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Data::Dumper" => 0,
    "English" => 0,
    "Exporter" => 0,
    "Log::Message::Simple" => 0,
    "base" => 0,
    "open" => 0,
    "perl" => "5.008",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/mrc2tbx"
  ],
  "test_requires" => {
    "Data::Section::Simple" => 0,
    "File::Find" => 0,
    "File::Slurp" => 0,
    "File::Spec::Functions" => 0,
    "File::Temp" => 0,
    "File::Touch" => 0,
    "FindBin" => 0,
    "Test::Base" => 0,
    "Test::Base::Filter" => 0,
    "Test::LongString" => 0,
    "Test::More" => "0.96",
    "Test::XML" => 0,
    "autodie" => 0
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
