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
# $Id: 003_assay.t 333 2010-06-02 16:41:31Z tfrayner $

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN {
    use_ok( 'Bio::MAGETAB::Assay' );
}

INIT {
    use lib 't/testlib';
    use CommonTests qw(test_class);
}

require Bio::MAGETAB::ControlledTerm;
require Bio::MAGETAB::ArrayDesign;

my $ct = Bio::MAGETAB::ControlledTerm->new( category => 1, value => 2 );
my $ad = Bio::MAGETAB::ArrayDesign->new( name => 1 );

my %required_attr = (
    name           => 'test',
    technologyType => $ct,
);

my %optional_attr = (
    arrayDesign    => $ad,
);

my %bad_attr = (
    name           => [],
    technologyType => 'test',
    arrayDesign    => 'test',
);

my $ct2 = Bio::MAGETAB::ControlledTerm->new( category => 1, value => 'test' );
my $ad2 = Bio::MAGETAB::ArrayDesign->new( name => 2 );

my %secondary_attr = (
    name           => 'test2',
    technologyType => $ct2,
    arrayDesign    => $ad2,
);

my $obj = test_class(
    'Bio::MAGETAB::Assay',
    \%required_attr,
    \%optional_attr,
    \%bad_attr,
    \%secondary_attr,
);

ok( $obj->isa('Bio::MAGETAB::Event'), 'object has correct superclass' );
