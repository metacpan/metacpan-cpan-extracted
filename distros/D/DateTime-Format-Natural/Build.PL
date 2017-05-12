# Note: this file has been initially created by Make::Build::Convert 0.20_01

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'DateTime::Format::Natural',
   dist_author => 'Steven Schubiger <schubiger@cpan.org>',
   dist_version_from => 'lib/DateTime/Format/Natural.pm',
   requires => {
                 'boolean' => 0,
                 'Carp' => 0,
                 'Clone' => 0,
                 'DateTime' => 0,
                 'DateTime::TimeZone' => 0,
                 'Exporter' => 0,
                 'Getopt::Long' => 0,
                 'List::MoreUtils' => 0,
                 'Params::Validate' => 0,
                 'Scalar::Util' => 0,
                 'Storable' => 0,
                 'Term::ReadLine' => 0,
               },
   build_requires => {
                       'Cwd' => 0,
                       'File::Find' => 0,
                       'File::Spec' => 0,
                       'FindBin' => 0,
                       'Module::Util' => 0,
                       'Test::MockTime' => 0,
                       'Test::More' => 0,
                     },
   recommends => { 'Date::Calc' => 0 },
   script_files => [ 'scripts/dateparse' ],
   license => 'perl',
   create_readme => 1,
   create_makefile_pl => 'traditional',
   meta_merge => {
      resources => {
         repository => 'https://github.com/stsc/DateTime-Format-Natural',
      },
   },
  );

$build->create_build_script;
