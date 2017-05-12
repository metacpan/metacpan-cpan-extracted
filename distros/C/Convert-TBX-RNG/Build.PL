
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "File::ShareDir::Install" => "0.03",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Create an RNG to validate a TBX dialect\r",
  "dist_author" => [
    "Nathan Glenn <garfieldnate\@gmail.com>"
  ],
  "dist_name" => "Convert-TBX-RNG",
  "dist_version" => "0.04",
  "license" => "perl",
  "module_name" => "Convert::TBX::RNG",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Data::Dumper" => 0,
    "Exporter::Easy" => 0,
    "File::ShareDir" => 0,
    "File::Slurp" => 0,
    "Path::Tiny" => 0,
    "TBX::XCS" => 0,
    "TBX::XCS::JSON" => 0,
    "XML::Twig" => 0,
    "autodie" => 0,
    "feature" => 0,
    "perl" => "5.010",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/xcs2rng.pl"
  ],
  "share_dir" => {
    "dist" => "share"
  },
  "test_requires" => {
    "Data::Section::Simple" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "TBX::Checker" => 0,
    "Test::Base" => 0,
    "Test::Base::Filter" => 0,
    "Test::More" => "0.88",
    "Test::NoWarnings" => 0,
    "Try::Tiny" => 0,
    "XML::LibXML" => 0
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
