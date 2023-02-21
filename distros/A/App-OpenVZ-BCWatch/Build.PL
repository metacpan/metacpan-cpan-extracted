# Note: this file has been initially created by Make::Build::Convert 0.20_01

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'App::OpenVZ::BCWatch',
   dist_author => 'Steven Schubiger <schubiger@cpan.org>',
   dist_version_from => 'lib/App/OpenVZ/BCWatch.pm',
   requires => {
                 'boolean' => 0,
                 'Carp' => 0,
                 'Config::File' => 0,
                 'Daemon::Generic' => 0,
                 'File::Basename' => 0,
                 'File::HomeDir' => 0,
                 'File::Spec' => 0,
                 'Mail::Sendmail' => 0,
                 'Storable' => 0,
                 'Sys::Hostname' => 0,
               },
   test_requires => {
                      'FindBin' => 0,
                      'File::Temp' => 0,
                      'Test::More' => 0,
                    },
   script_files => [ 'scripts/vzwatchd' ],
   license => 'perl',
   create_readme => 1,
   meta_merge => {
       resources => {
           repository => 'https://github.com/stsc/App-OpenVZ-BCWatch',
       },
   },
  );

$build->create_build_script;
