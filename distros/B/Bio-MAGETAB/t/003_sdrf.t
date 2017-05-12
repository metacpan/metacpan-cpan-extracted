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
# $Id: 003_sdrf.t 369 2012-07-17 18:01:48Z tfrayner $

use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Exception;

BEGIN {
    use_ok( 'Bio::MAGETAB::SDRF' );
}

INIT {
    use lib 't/testlib';
    use CommonTests qw(test_class);
}

use Bio::MAGETAB::Normalization;
use Bio::MAGETAB::SDRFRow;
use Bio::MAGETAB::Source;
use Bio::MAGETAB::LabeledExtract;
use Bio::MAGETAB::Assay;
use Bio::MAGETAB::ControlledTerm;
use Bio::MAGETAB::Edge;

sub create_nodes {

    my @types = @_;

    my @nodes;
    foreach my $type ( @types ) {
        my $class = "Bio::MAGETAB::$type";
        my $object;
        if ( $type eq 'LabeledExtract' ) {
            my $cv = Bio::MAGETAB::ControlledTerm->new(
                category => 'Label', value => 'test label',
            );
            $object = $class->new( name => $type, label => $cv );
        }
        elsif ( $type eq 'Assay' ) {
            my $cv = Bio::MAGETAB::ControlledTerm->new(
                category => 'Tech', value => 'test tech',
            );
            $object = $class->new( name => $type, technologyType => $cv );
        }
        else {
            $object = $class->new( name => $type );
        }
        if ( scalar @nodes ) {
            Bio::MAGETAB::Edge->new(
                inputNode  => $nodes[-1],
                outputNode => $object,
            );
        }
        push @nodes, $object;
    }
    return @nodes;
}

my $norm = Bio::MAGETAB::Normalization->new( name => 'test norm' );
my $row  = Bio::MAGETAB::SDRFRow->new( nodes => [ $norm ] );

my %required_attr = (
    uri            => 'file://localhost/data/sdrf1.txt',
);

my %optional_attr = (
    sdrfRows       => [ $row ],
);

my %bad_attr = (
    sdrfRows       => 'test',
    uri            => [],
);

my $norm2 = Bio::MAGETAB::Normalization->new( name => 'test norm 2' );
my $row2  = Bio::MAGETAB::SDRFRow->new( nodes => [ $norm2 ] );

my %secondary_attr = (
    sdrfRows       => [ $row, $row2 ],
    uri            => 'file://localhost/data/sdrf2.txt',
);

my $obj = test_class(
    'Bio::MAGETAB::SDRF',
    \%required_attr,
    \%optional_attr,
    \%bad_attr,
    \%secondary_attr,
);

ok( $obj->isa('Bio::MAGETAB::BaseClass'), 'object has correct superclass' );

{
    # Test the add_nodes method with a valid chain of nodes.
    my @nodes = create_nodes( qw(Source LabeledExtract Assay Normalization) );
    my @branch = create_nodes( qw(Assay Normalization) );
    Bio::MAGETAB::Edge->new(
        inputNode  => $nodes[1],
        outputNode => $branch[0],
    );
    lives_ok( sub { $obj->clear_sdrfRows() }, 'we can clear the sdrfRows attribute' );
    ok( ! $obj->has_sdrfRows(), 'and has_sdrfRows agrees' );
    lives_ok( sub { $obj->add_nodes( \@nodes ) }, 'add_nodes is okay with valid node list' );
    ok( $obj->has_sdrfRows(), 'has_sdrfRows agrees' );
    my @rows = $obj->get_sdrfRows();
    is( scalar @rows, 2, 'and get_sdrfRows returns the correct number of rows' );
    my $channel = $rows[0]->get_channel();
    ok( defined $channel, 'with a defined channel' );
    is( $channel->get_value(), 'test label', 'having the right value' );
}

{
    # Try add_nodes with an invalid chain (multiple LEs).
    my @nodes2 = create_nodes( qw(LabeledExtract LabeledExtract) );
    dies_ok( sub{ $obj->add_nodes( \@nodes2 ) }, 'adding multiple chaines LEs fails' );
}

# Check that cycles are detected and handled.
{
    my @nodes3 = create_nodes( qw(Source LabeledExtract Assay) );
    Bio::MAGETAB::Edge->new(
        inputNode  => $nodes3[2],
        outputNode => $nodes3[0],
    );
    dies_ok( sub{ $obj->add_nodes( \@nodes3 ) },
             'adding chains with no starting nodes (all one cycle) fails' );
}
{
    my @nodes4 = create_nodes( qw(Source LabeledExtract Assay) );
    Bio::MAGETAB::Edge->new(
        inputNode  => $nodes4[2],
        outputNode => $nodes4[1],
    );
    dies_ok( sub{ $obj->add_nodes( \@nodes4 ) },
             'adding chains containing cycles fails' );
}

# Check that splitting and recombining is not flagged by the cycle check.
{
    my @nodes5 = create_nodes( qw(Source LabeledExtract Assay) );
    my $cv = Bio::MAGETAB::ControlledTerm->new(
        category => 'Label', value => 'test label',
    );
    my $le = Bio::MAGETAB::LabeledExtract->new( name => 'test branch', label => $cv );
    Bio::MAGETAB::Edge->new(
        inputNode  => $nodes5[0],
        outputNode => $le,
    );
    Bio::MAGETAB::Edge->new(
        inputNode  => $le,
        outputNode => $nodes5[2],
    );
    lives_ok( sub{ $obj->add_nodes( [ @nodes5, $le ] ) },
              'adding splitting followed by pooling succeeds' );
}
