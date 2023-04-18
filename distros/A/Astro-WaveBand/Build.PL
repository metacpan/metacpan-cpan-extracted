#!perl

use strict;
use warnings;
use Module::Build;
use File::Spec;

my $file = File::Spec->catfile( "lib", "Astro", "WaveBand.pm" );


# Set it up.
my $build = Module::Build->new
  (
   module_name => 'Astro::WaveBand',
   license  => 'perl',
   version_from => $file,
   dist_abstract => 'Transparently work in waveband, wavelength or filter',
   dist_author => [
                   'Tim Jenness <tjenness@cpan.org>',
                   'Brad Cavanagh <b.cavanagh@jach.hawaii.edu>',
                   'Alasdair Allan <aa@astro.ex.ac.uk>',
                   'Tim Lister <tlister@lcogt.net>',
                  ],
   meta_merge => {
               resources =>  {
                              repository => "https://github.com/timj/perl-Astro-WaveBand.git",
                              homepage => "https://github.com/timj/perl-Astro-WaveBand/tree/master",
                             },
                },
   build_requires => {
                      'Test::More' => 0,
                     },
   configure_requires => {
                          "Module::Build" => 0.30,
                         },
  );

$build->create_build_script;
