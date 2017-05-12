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
# $Id: 003_array_design.t 333 2010-06-02 16:41:31Z tfrayner $

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN {
    use_ok( 'Bio::MAGETAB::ArrayDesign' );
}

INIT {
    use lib 't/testlib';
    use CommonTests qw(test_class);
}

require Bio::MAGETAB::ControlledTerm;
require Bio::MAGETAB::Comment;
require Bio::MAGETAB::Reporter;
require Bio::MAGETAB::CompositeElement;

my $ct = Bio::MAGETAB::ControlledTerm->new( category => 1, value => 2 );
my @co = Bio::MAGETAB::Comment->new( name => 1, value => 2 );
my @de;
for ( 1..3 ) {
    push @de, Bio::MAGETAB::Reporter->new( name => "test $_" );
}

use Bio::MAGETAB::TermSource;
my $ts = Bio::MAGETAB::TermSource->new( name => 'test term source' );

my %required_attr = (
    name        => 'test array design',
);

my %optional_attr = (
    accession           => 'A-TEST-1111',
    termSource          => $ts,
    version             => '1.21b',
    uri                 => 'http://dummy.com/array_design.txt',
    technologyType      => $ct,
    surfaceType         => $ct,
    substrateType       => $ct,
    sequencePolymerType => $ct,
    printingProtocol    => 'test text here',
    provider            => 'simple string provider',
    designElements      => \@de,
    comments            => \@co,
);

my %bad_attr = (
    name                => [],
    accession           => [],
    termSource          => 'test',
    version             => [],
    uri                 => [],
    technologyType      => 'test',
    surfaceType         => 'test',
    substrateType       => 'test',
    sequencePolymerType => 'test',
    printingProtocol    => [],
    provider            => [],
    designElements      => [qw(1 2 3)],
    comments            => 'test',
);

my $ct2 = Bio::MAGETAB::ControlledTerm->new( category => 2, value => 3 );
my @co2 = Bio::MAGETAB::Comment->new( name => 2, value => 3 );
my @de2;
for ( 1..3 ) {
    push @de2, Bio::MAGETAB::CompositeElement->new( name => "test 2 $_" );
}

my $ts2 = Bio::MAGETAB::TermSource->new( name => 'test term source 2' );
my %secondary_attr = (
    name                => 'test array design 2',
    accession           => 'A-TEST-1112',
    termSource          => $ts2,
    version             => '1.23b',
    uri                 => 'http://dummy.com/array_design2.txt',
    technologyType      => $ct2,
    surfaceType         => $ct2,
    substrateType       => $ct2,
    sequencePolymerType => $ct2,
    printingProtocol    => 'test text here 2',
    provider            => 'simple string provider 2',
    designElements      => \@de2,
    comments            => \@co2,
);

my $obj = test_class(
    'Bio::MAGETAB::ArrayDesign',
    \%required_attr,
    \%optional_attr,
    \%bad_attr,
    \%secondary_attr,
);

ok( $obj->isa('Bio::MAGETAB::DatabaseEntry'), 'object has correct superclass' );
