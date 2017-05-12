
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
  "dist_abstract" => "We are Danish CPAN authors",
  "dist_author" => [
    "Kaare Rasmussen <kaare\@cpan.org>"
  ],
  "dist_name" => "Acme-CPANAuthors-Danish",
  "dist_version" => "0.03",
  "license" => "perl",
  "module_name" => "Acme::CPANAuthors::Danish",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Acme::CPANAuthors::Register" => 0,
    "perl" => "5.008",
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Acme::CPANAuthors" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::More" => 0
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
