
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
  "dist_abstract" => "Bash completion for perlbrew",
  "dist_author" => [
    "Rob Hoelz <rob\@hoelz.ro>"
  ],
  "dist_name" => "Bash-Completion-Plugins-perlbrew",
  "dist_version" => "0.10",
  "license" => "perl",
  "module_name" => "Bash::Completion::Plugins::perlbrew",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Bash::Completion" => "0.001",
    "perl" => "v5.8.0"
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
