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
# $Id: 003_data_matrix.t 333 2010-06-02 16:41:31Z tfrayner $

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN {
    use_ok( 'Bio::MAGETAB::DataMatrix' );
}

INIT {
    use lib 't/testlib';
    use CommonTests qw(test_class);
}

use Bio::MAGETAB::ControlledTerm;
use Bio::MAGETAB::Normalization;
use Bio::MAGETAB::Reporter;
use Bio::MAGETAB::MatrixColumn;
use Bio::MAGETAB::MatrixRow;

my $ct = Bio::MAGETAB::ControlledTerm->new( category => 'qt', value => 'test' );
my $no = Bio::MAGETAB::Normalization->new( name => 'test' );
my $rp = Bio::MAGETAB::Reporter->new( name => 'test' );
my $ty = Bio::MAGETAB::ControlledTerm->new( category => 'type', value => 'test' );

my $mc = Bio::MAGETAB::MatrixColumn->new(
    columnNumber     => 20,
    quantitationType => $ct,
    referencedNodes  => [ $no ],
);

my $mr = Bio::MAGETAB::MatrixRow->new(
    rowNumber        => 21,
    designElement    => $rp,
);

my %required_attr = (
    uri               => 'http://www.madeupdatafiles.org/mydata.txt',
    dataType          => $ty,
);

my %optional_attr = (
    rowIdentifierType => 'Reporter',
    matrixRows        => [ $mr ],
    matrixColumns     => [ $mc ],
);

my %bad_attr = (
    uri               => [],
    rowIdentifierType => [],
    matrixRows        => [ 'test' ],
    matrixColumns     => 'test',
    dataType          => 'test',
);

my $ct2 = Bio::MAGETAB::ControlledTerm->new( category => 'qt', value => 'test2' );
my $no2 = Bio::MAGETAB::Normalization->new( name => 'test2' );
my $rp2 = Bio::MAGETAB::Reporter->new( name => 'test2' );
my $ty2 = Bio::MAGETAB::ControlledTerm->new( category => 'type', value => 'test2' );

my $mc2 = Bio::MAGETAB::MatrixColumn->new(
    columnNumber     => 202,
    quantitationType => $ct2,
    referencedNodes  => [ $no2 ],
);

my $mr2 = Bio::MAGETAB::MatrixRow->new(
    rowNumber        => 212,
    designElement    => $rp2,
);

my %secondary_attr = (
    uri               => 'http://www.madeupdatafiles.org/mydata2.txt',
    rowIdentifierType => 'CompositeElement',
    matrixRows        => [ $mr, $mr2 ],
    matrixColumns     => [ $mc, $mc2 ],
    dataType          => $ty2,
);

my $obj = test_class(
    'Bio::MAGETAB::DataMatrix',
    \%required_attr,
    \%optional_attr,
    \%bad_attr,
    \%secondary_attr,
);

ok( $obj->isa('Bio::MAGETAB::Data'), 'object has correct superclass' );
