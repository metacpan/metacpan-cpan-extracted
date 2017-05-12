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
# $Id: 003_parameter_value.t 361 2011-04-18 20:01:51Z tfrayner $

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN {
    use_ok( 'Bio::MAGETAB::ParameterValue' );
}

INIT {
    use lib 't/testlib';
    use CommonTests qw(test_class);
}

use Bio::MAGETAB::Protocol;
use Bio::MAGETAB::ProtocolParameter;
use Bio::MAGETAB::Measurement;
use Bio::MAGETAB::ControlledTerm;
use Bio::MAGETAB::Comment;

my $prot = Bio::MAGETAB::Protocol->new( name => 'test protocol' );
my $parm = Bio::MAGETAB::ProtocolParameter->new( name => 'test param', protocol => $prot );
my $meas = Bio::MAGETAB::Measurement->new( measurementType => 'test measurement', value => 'value' );
my $term = Bio::MAGETAB::ControlledTerm->new( category => 'test category', value => 'test value' );
my $comm = Bio::MAGETAB::Comment->new( name => 'test comment', value => 'of interest' );

my %required_attr = (
    parameter   => $parm,
);

my %optional_attr = (
    comments    => [ $comm ],
    measurement => $meas,
    term        => $term,
);

my %bad_attr = (
    measurement => 'test',
    parameter   => 'test',
    comments    => 'test',
    term        => 'test',
);

my $prot2 = Bio::MAGETAB::Protocol->new( name => 'test protocol' );
my $parm2 = Bio::MAGETAB::ProtocolParameter->new( name => 'test param', protocol => $prot2 );
my $meas2 = Bio::MAGETAB::Measurement->new( measurementType => 'test measurement', value => 'value' );
my $term2 = Bio::MAGETAB::ControlledTerm->new( category => 'test category 2', value => 'test value' );
my $comm2 = Bio::MAGETAB::Comment->new( name => 'test comment', value => 'of interest' );

my %secondary_attr = (
    measurement => $meas2,
    parameter   => $parm2,
    term        => $term2,
    comments    => [ $comm2 ],
);

my $obj = test_class(
    'Bio::MAGETAB::ParameterValue',
    \%required_attr,
    \%optional_attr,
    \%bad_attr,
    \%secondary_attr,
);

ok( $obj->isa('Bio::MAGETAB::BaseClass'), 'object has correct superclass' );
