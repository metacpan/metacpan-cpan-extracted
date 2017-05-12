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
# $Id: 003_sample.t 333 2010-06-02 16:41:31Z tfrayner $

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN {
    use_ok( 'Bio::MAGETAB::Sample' );
}

INIT {
    use lib 't/testlib';
    use CommonTests qw(test_class);
}

use Bio::MAGETAB::ControlledTerm;
use Bio::MAGETAB::Measurement;

my $ct = Bio::MAGETAB::ControlledTerm->new( category => 'test', value => 'test' );
my $me = Bio::MAGETAB::Measurement->new( measurementType => 'test', value => 'test' );

my %required_attr = (
    name           => 'test',
);

my %optional_attr = (
    materialType    => $ct,
    characteristics => [ $ct ],
    measurements    => [ $me ],
);

my %bad_attr = (
    name            => [],
    materialType    => 'test',
    characteristics => [ 'test' ],
    measurements    => 'test',
);

my $ct2 = Bio::MAGETAB::ControlledTerm->new( category => 'test', value => 'test 2' );
my $me2 = Bio::MAGETAB::Measurement->new( measurementType => 'test', value => 'test' );

my %secondary_attr = (
    name            => 'test2',
    materialType    => $ct2,
    characteristics => [ $ct2 ],
    measurements    => [ $me2 ],
);

my $obj = test_class(
    'Bio::MAGETAB::Sample',
    \%required_attr,
    \%optional_attr,
    \%bad_attr,
    \%secondary_attr,
);

ok( $obj->isa('Bio::MAGETAB::Material'), 'object has correct superclass' );
