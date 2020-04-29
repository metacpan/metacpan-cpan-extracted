#!perl

use strict;
use warnings;
use Module::Build;
use File::Spec;
use Config;

# Copyright (C) 2012-2013 Science and Technology Facilities Council.
# All Rights Reserved.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA 02111-1307,
# USA

# Set it up.
my $build = Module::Build->new
  (
   module_name => 'Astro::Catalog',
   dist_abstract => "A generic astronomical catalogue class",
   license  => 'gpl2',
   author => [
              'Alasdair Allan <aa@astro.ex.ac.uk>',
              'Tim Jenness <tjenness@cpan.org>',
             ],
   dist_version => '4.35',
   meta_merge => {
               resources =>  {
                              repository => "git://github.com/timj/perl-Astro-Catalog.git",
                              homepage => "http://github.com/timj/perl-Astro-Catalog/tree/master",
                             },
                },
   requires => {
                'LWP'                 => 5.53,
                'Net::Domain'         => 2.13,
                'Pod::Usage'          => 1.14,
                'Astro::Coords'       => 0.12,
                'File::Spec'          => 0.84,
                'Astro::Telescope'    => 0.50,
                'Time::Piece'         => 1.08,
                'SOAP::Lite'          => 0.00,
                'Carp'                => 1.01,
                'Data::Dumper'        => 2.12,
                'Scalar::Util'        => 1.14,
                'File::Temp'          => 0.14,
                'Class::Struct'       => 0.63,
                'Number::Uncertainty' => 0.01,
                'Misc::Quality'       => 0.01,
                'DateTime'            => 0,
                'DateTime::Format::ISO8601' => 0,
                'Astro::Flux'         => 0.01
               },
   recommends => {
                  'Astro::FITS::CFITSIO'=> 1.03,
                  'Astro::VO::VOTable' => 0.90,
                  'Tk' => 804.029,
                 },
   configure_requires => {
                          "Module::Build" => 0.30,
                         },
   build_requires => {
                      'Test::More' => 0,
                     },
   etc_files => {
                 'etc/skycat.cfg' => 'etc/skycat.cfg',
                 'etc/sss.cfg' => 'etc/sss.cfg',
                },
   install_path => {
                    'etc' => File::Spec->catdir($Config{installprefix}, 'etc'),
                   },
  );

$build->add_build_element('etc');
$build->create_build_script;
