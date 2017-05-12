
use strict;
use warnings;
use Module::Build;

# Set it up.
my $build = Module::Build->new
  (
   module_name => 'Astro::FITS::Header',
   license  => 'gpl',
   dist_abstract => 'Object-oriented interface to FITS HDUs',
   dist_author => [
                   'Alasdair Allan <aa@astro.ex.ac.uk>',
                   'Tim Jenness <tjenness@cpan.org>',
                   'Brad Cavanagh <b.cavanagh@jach.hawaii.edu>',
                   'Craig DeForest <deforest@boulder.swri.edu>',
                   'Jim Lewis <jrl@ast.cam.ac.uk>',
                  ],
   dist_version => '3.07',
   meta_merge => {
               resources =>  {
                              repository => "git://github.com/timj/perl-Astro-FITS-Header.git",
                              homepage => "http://github.com/timj/perl-Astro-FITS-Header/tree/master",
                             },
                },
   recommends => {
                  'Starlink::AST' => 0,
                  'Astro::FITS::CFITSIO' => 0,
                 },
   build_requires => {
                      'Test::More' => 0,
                     },
   configure_requires => {
                          "Module::Build" => 0.30,
                         },
  );

$build->create_build_script;
