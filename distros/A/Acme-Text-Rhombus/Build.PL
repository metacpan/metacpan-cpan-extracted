# Note: this file has been initially created by Make::Build::Convert 0.20_04

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'Acme::Text::Rhombus',
   dist_author => 'Steven Schubiger <schubiger@cpan.org>',
   dist_version_from => 'lib/Acme/Text/Rhombus.pm',
   requires => { 'Exporter' => 0 },
   test_requires => { 'Test::More' => 0 },
   license => 'perl',
   create_readme => 1,
   meta_merge => {
       resources => {
           repository => 'https://github.com/stsc/Acme-Text-Rhombus',
       },
   },
  );

$build->create_build_script;
