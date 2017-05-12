
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
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Real life web performance testing tool",
  "dist_author" => [
    "Alex J. G. Burzy\305\204ski <ajgb\@cpan.org>"
  ],
  "dist_name" => "App-livehttperf",
  "dist_version" => "0.03",
  "license" => "perl",
  "module_name" => "App::livehttperf",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Excel::Writer::XLSX" => 0,
    "Getopt::Long" => 0,
    "HTTP::Request" => 0,
    "HTTP::Response" => 0,
    "LWP::UserAgent" => 0,
    "List::Util" => 0,
    "Number::Bytes::Human" => 0,
    "Parallel::ForkManager" => 0,
    "Statistics::Descriptive" => 0,
    "Text::TabularDisplay" => 0,
    "Time::Elapsed" => 0,
    "Time::HiRes" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/livehttperf"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
