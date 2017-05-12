
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
  "dist_abstract" => "is given() too much typing for you?",
  "dist_author" => [
    "Ben Hengst <ben.hengst\@gmail.com>"
  ],
  "dist_name" => "Acme-Given-Hash",
  "dist_version" => "0.007",
  "license" => "perl",
  "module_name" => "Acme::Given::Hash",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Exporter" => 0,
    "List::MoreUtils" => "0.33",
    "Test::More" => "0.98",
    "perl" => "5.014"
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
