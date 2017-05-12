
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Daemon::Shutdown monitor plugin which checks for active transmission downloads",
  "dist_author" => [
    "Ioan Rogers <ioan.rogers\@gmail.com>"
  ],
  "dist_name" => "Daemon-Shutdown-Monitor-transmission",
  "dist_version" => "0.004",
  "license" => "artistic_2",
  "module_name" => "Daemon::Shutdown::Monitor::transmission",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Daemon::Shutdown" => "0.07",
    "Log::Log4perl" => 0,
    "Params::Validate" => 0,
    "Readonly" => 0,
    "Regexp::Common" => 0,
    "Transmission::Client" => 0,
    "Try::Tiny" => 0,
    "YAML::Any" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
