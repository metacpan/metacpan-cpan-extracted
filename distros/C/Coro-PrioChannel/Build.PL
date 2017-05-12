
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "AnyEvent::Loop" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Priority message queues for Coro",
  "dist_author" => [
    "Darin McBride <dmcbride\@cpan.org>"
  ],
  "dist_name" => "Coro-PrioChannel",
  "dist_version" => "0.005",
  "license" => "perl",
  "module_name" => "Coro::PrioChannel",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "AnyEvent" => 0,
    "Coro" => 0,
    "Coro::Semaphore" => 0,
    "List::Util" => 0,
    "Scalar::Util" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
