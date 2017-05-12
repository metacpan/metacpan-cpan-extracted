
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "CGI" => 0,
    "Chart::Lines" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0,
    "YAML::Any" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "provide CGI support to webservers which don't have it",
  "dist_author" => [
    "Ioan Rogers <ioan.rogers\@gmail.com>"
  ],
  "dist_name" => "App-FastishCGI",
  "dist_version" => "0.002",
  "license" => "artistic_2",
  "module_name" => "App::FastishCGI",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "AnyEvent" => 0,
    "AnyEvent::FCGI" => 0,
    "AnyEvent::Handle" => 0,
    "Carp" => 0,
    "Data::Dumper" => 0,
    "File::Basename" => 0,
    "Getopt::Long" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Pod::Usage" => 0,
    "Sys::Syslog" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/fastishcgi"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
