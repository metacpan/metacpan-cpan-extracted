
use strict;
use warnings;
use Module::Build;

# Set it up.
my $build = Module::Build->new
  (
   module_name => 'Astro::FITS::Header',
   license  => 'gpl3',
   dist_abstract => 'Object-oriented interface to FITS HDUs',
   dist_author => [
                   'Alasdair Allan <aa@astro.ex.ac.uk>',
                   'Tim Jenness <tjenness@cpan.org>',
                   'Brad Cavanagh <b.cavanagh@jach.hawaii.edu>',
                   'Craig DeForest <deforest@boulder.swri.edu>',
                   'Jim Lewis <jrl@ast.cam.ac.uk>',
                  ],
   dist_version => '3.09',
   meta_merge => {
               'meta-spec' => {
                   version => 2,
               },
               resources =>  {
                              repository => {
                                  url => 'https://github.com/timj/perl-Astro-FITS-Header.git',
                                  web => 'https://github.com/timj/perl-Astro-FITS-Header/',
                                  type => 'git',
                              },
                              homepage => 'https://github.com/timj/perl-Astro-FITS-Header/',
                             },
               prereqs => {
                    runtime => {
                        suggests => {
                            'Starlink::AST' => 0,
                        },
                    },
               },
                },
   recommends => {
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
