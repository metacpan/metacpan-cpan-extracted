#!/usr/bin/env perl
# Build.PL for Array::PrintCols.pm
#
#    Copyright (C) 1996-2013  Alan K. Stebbens <aks@stebbens.org>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

use Module::Build;
my $build = Module::Build->new
  ( 
    module_name        => 'Array::PrintCols',
    license	       => 'gpl',
    dist_author	       => ['Alan K. Stebbens <aks@stebbens.org>'],
    dist_version_from  => 'PrintCols.pm',
    dist_abstract      => <<ABSTRACT,
Format or print values from an array or hash in one or more sorted, vertical columns.
ABSTRACT
    share_dir	       => [ 'tests' ],
    create_makefile_pl => 'traditional',
    PL_Files	       => {},
    configure_requires => {
      'Module::Build'  => '>= 0.40'
    },
    requires	       => { 
      'Carp'	       => 0,
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/aks/array-printcols'
        }
    },
  );
  $build->create_build_script;
