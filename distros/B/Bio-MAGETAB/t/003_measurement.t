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
# $Id: 003_measurement.t 333 2010-06-02 16:41:31Z tfrayner $

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN {
    use_ok( 'Bio::MAGETAB::Measurement' );
}

INIT {
    use lib 't/testlib';
    use CommonTests qw(test_class);
}

use Bio::MAGETAB::ControlledTerm;

my $ct = Bio::MAGETAB::ControlledTerm->new( category => 'unit', value => 'name' );

my %required_attr = (
    measurementType => 'test',
);

my %optional_attr = (
    unit     => $ct,
    value    => 0,
    minValue => 1,
    maxValue => 'two',
);

my %bad_attr = (
    measurementType => [],
    unit     => '',
    value    => [],
    minValue => [],
    maxValue => [],
);

my $ct2 = Bio::MAGETAB::ControlledTerm->new( category => 'unit', value => 'name 2' );

my %secondary_attr = (
    measurementType => 'test2',
    unit     => $ct2,
    value    => 'zero',
    minValue => 1_000_000_000,
    maxValue => -0.02,
);

my $obj = test_class(
    'Bio::MAGETAB::Measurement',
    \%required_attr,
    \%optional_attr,
    \%bad_attr,
    \%secondary_attr,
);

ok( $obj->isa('Bio::MAGETAB::BaseClass'), 'object has correct superclass' );
