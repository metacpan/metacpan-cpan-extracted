
use strict;
use warnings;

use Module::Build 0.3601;
use lib qw{inc}; use Module::Build::AlienLibJIT;

my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "your very own libjit for nefarious Perl purposes",
  "dist_author" => [
    "Mattia Barbon <mattia\@barbon.org>",
    "Steffen Mueller <smueller\@cpan.org>"
  ],
  "dist_name" => "Alien-LibJIT",
  "dist_version" => "0.03",
  "license" => "perl",
  "module_name" => "Alien::LibJIT",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "File::ShareDir" => 0
  },
  "script_files" => [],
  "test_requires" => {}
);


my %fallback_build_requires = (
  "Module::Build" => "0.3601"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build::AlienLibJIT->new(%module_build_args);

$build->create_build_script;
