
use strict;
use warnings;

use Module::Build 0.3601;
use lib qw{inc}; use Alien::Base::ModuleBuild;

my %module_build_args = (
  "alien_name" => "mpg123",
  "alien_repository" => {
    "host" => "www.mpg123.de:80",
    "location" => "/download",
    "pattern" => qr/(?^:^mpg123-([\d\.]+)\.tar\.bz2$)/,
    "protocol" => "http"
  },
  "build_requires" => {
    "Test::LoadAllModules" => "0.021",
    "Test::More" => "0.96"
  },
  "configure_requires" => {
    "Alien::Base" => "0.002",
    "File::ShareDir" => "1.03",
    "Path::Class" => "0.013"
  },
  "dist_abstract" => "mpg123 music player",
  "dist_author" => [
    "Torsten Raudssus <torsten\@raudss.us>"
  ],
  "dist_name" => "Alien-mpg123",
  "dist_version" => "0.002",
  "license" => "perl",
  "module_name" => "Alien::mpg123",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Alien::Base" => "0.002",
    "File::ShareDir" => "1.03",
    "Path::Class" => "0.013"
  },
  "script_files" => [
    "bin/mpg123"
  ]
);


my $build = Alien::Base::ModuleBuild->new(%module_build_args);

$build->create_build_script;
