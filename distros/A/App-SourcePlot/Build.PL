#!perl

use strict;
use warnings;
use Module::Build;

# Copyright (C) 2012-2014 Science and Technology Facilities Council.
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

my $build = Module::Build->new
  (
   module_name => 'App::SourcePlot',
   dist_abstract => "A simple astronomical source plotter",
   license  => 'gpl3',
   dist_author => [
              'Graham Bell <g.bell@eaobservatory.org>',
              'Tim Jenness <tjenness@cpan.org>',
              'Remo Tilanus <r.tilanus@jach.hawaii.edu>',
              'Pam Shimek <pshimek@uvic.ca>',
              'Casey Best <cbest@uvic.ca>',
             ],
   dist_version => '1.31',
   meta_merge => {
               resources =>  {
                              repository => "https://github.com/eaobservatory/perl-App-SourcePlot.git",
                              homepage => "https://github.com/eaobservatory/perl-App-SourcePlot/tree/master",
                             },
                },
   requires => {
                'Tk'                  => '804.0',
                'Astro::PAL'          => '1.00',
                'Astro::Catalog'      => 2.01,
                'Tk::AstroCatalog'    => 0.12,
                'Astro::Coords'       => 0.13,
                'Astro::Coords::Planet' => 0.05,
                'Astro::Telescope'    => 0.71,
                'Config::IniFiles'    => 2.62,
                'DateTime'            => 0,
                'File::HomeDir'       => 0,
                'File::ShareDir'      => 1.03,
                'File::Spec'          => 0,
               },
   configure_requires => {
                          "Module::Build" => 0.30,
                         },
   build_requires => {
                      'Test::More' => 0,
                      'Test::Number::Delta' => 0,
                     },
   script_files => [ qw|
                         bin/sourceplot
                       |],
   share_dir => 'share',
  );

$build->create_build_script;
