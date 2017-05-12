#!/usr/bin/env perl
#
# Copyright 2008-2010 Tim Rayner
# 
# This file is part of Bio::MAGETAB.
# 
# Bio::MAGETAB is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# Bio::MAGETAB is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Bio::MAGETAB.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id: Makefile.PL 386 2014-04-11 14:54:54Z tfrayner $

use strict;
use warnings;

use inc::Module::Install;

all_from 'lib/Bio/MAGETAB.pm';

requires 'Moose'                       => '0.43';
requires 'MooseX::FollowPBP'           => '0.04';
requires 'MooseX::Types'               => '0.10';
requires 'Params::Coerce'              => '0.14';
requires 'URI'                         => '1.35';
requires 'Date::Manip'                 => '5.44';
requires 'DateTime'                    => '0.4302';
requires 'DateTime::Format::Flexible'  => '0.21';
requires 'Email::Valid'                => '0.179';
requires 'Parse::RecDescent'           => '1.965001';
requires 'Text::CSV_XS'                => '0.32';

test_requires 'Test::Exception'        => '0.26';

recommends 'LWP::UserAgent'            => '5.819';
recommends 'GraphViz'                  => '2.03';
recommends 'Tangram'                   => '2.10';
recommends 'DBI'                       => '';
recommends 'DBD::SQLite'               => '';

install_script glob('scripts/*.pl');
auto_install;
WriteAll;

