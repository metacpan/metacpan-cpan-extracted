#!perl

use strict;
use warnings;
use Module::Build;
use File::Spec;

# Copyright (C) 2010-2012 Science and Technology Facilities Council.
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

my $file = File::Spec->catfile(File::Spec->curdir, "lib", "Astro",
			       "Coords.pm");

# Set it up.
my $build = Module::Build->new
  (
   module_name => 'Astro::Coords',
   abstract_from => $file,
   license  => 'gpl',
   author => [
              'Tim Jenness <t.jenness@jach.hawaii.edu>',
             ],
   dist_version => '0.18',
   meta_merge => {
               resources =>  {
                              repository => "git://github.com/timj/perl-Astro-Coords.git",
                              homepage => "http://github.com/timj/perl-Astro-Coords/tree/master",
                             },
                },
   requires => {
                'Scalar::Util' => 1.13,
                'Astro::PAL' => 0,
                'Time::Piece' => 1.02,
                'Astro::Telescope' => 0.71,
                'DateTime' => 0.76,
               },
   configure_requires => {
                          "Module::Build" => 0.30,
                         },
   build_requires => {
                      'Test::More' => 0,
                      'Test::Number::Delta' => 0,
                      'Test::Pod' => 1.00,
                     },
  );

$build->create_build_script;
