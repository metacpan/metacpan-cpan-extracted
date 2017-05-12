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
# $Id: 003_factor_value.t 333 2010-06-02 16:41:31Z tfrayner $

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN {
    use_ok( 'Bio::MAGETAB::FactorValue' );
}

INIT {
    use lib 't/testlib';
    use CommonTests qw(test_class);
}

use Bio::MAGETAB::Factor;
use Bio::MAGETAB::ControlledTerm;
use Bio::MAGETAB::Measurement;

my $fa = Bio::MAGETAB::Factor->new( name => 'test factor' );
my $ct = Bio::MAGETAB::ControlledTerm->new( category => 'test', value => 'test controlled term' );
my $me = Bio::MAGETAB::Measurement->new( measurementType => 'test measurement', value => 'test' );

my %required_attr = (
    factor      => $fa,
);

my %optional_attr = (
    measurement => $me,
    term        => $ct,
);

my %bad_attr = (
    factor      => 'test',
    measurement => 'test',
    term        => 'test',
);

my $fa2 = Bio::MAGETAB::Factor->new( name => 'test factor2' );
my $ct2 = Bio::MAGETAB::ControlledTerm->new( category => 'test2', value => 'test controlled term' );
my $me2 = Bio::MAGETAB::Measurement->new( measurementType => 'test measurement2', value => 'test' );

my %secondary_attr = (
    factor      => $fa2,
    measurement => $me2,
    term        => $ct2,
);

my $obj = test_class(
    'Bio::MAGETAB::FactorValue',
    \%required_attr,
    \%optional_attr,
    \%bad_attr,
    \%secondary_attr,
);

ok( $obj->isa('Bio::MAGETAB::BaseClass'), 'object has correct superclass' );
