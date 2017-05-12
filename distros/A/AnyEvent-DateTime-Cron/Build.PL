
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
  "dist_abstract" => "AnyEvent crontab with DateTime::Event::Cron",
  "dist_author" => [
    "Clinton Gormley <drtech\@cpan.org>",
    "Andy Gorman <agorman\@cpan.org>"
  ],
  "dist_name" => "AnyEvent-DateTime-Cron",
  "dist_version" => "0.08",
  "license" => "perl",
  "module_name" => "AnyEvent::DateTime::Cron",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "AnyEvent" => 0,
    "DateTime" => 0,
    "DateTime::Event::Cron" => 0,
    "DateTime::Event::Cron::Quartz" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Test::More" => 0
  }
);


my %fallback_build_requires = (
  "Module::Build" => "0.3601",
  "Test::More" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
