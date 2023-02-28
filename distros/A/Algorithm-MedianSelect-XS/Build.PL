# Note: this file has been initially created by Make::Build::Convert 0.20_05

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'Algorithm::MedianSelect::XS',
   dist_author => 'Steven Schubiger <schubiger@cpan.org>',
   dist_version_from => 'lib/Algorithm/MedianSelect/XS.pm',
   requires => {
                 'Carp' => 0,
                 'Exporter' => 0,
                 'XSLoader' => 0,
               },
   test_requires => { 'Test::More' => 0 },
   xs_files => { 'XS.xs' => 'lib/Algorithm/MedianSelect/XS.xs' },
   include_dirs => [ '.' ],
   license => 'perl',
   create_readme => 1,
   meta_merge => {
       resources => {
           repository => 'https://github.com/stsc/Algorithm-MedianSelect-XS',
       }
   }
  );

$build->create_build_script;
