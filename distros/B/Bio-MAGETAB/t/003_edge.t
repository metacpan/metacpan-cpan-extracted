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
# $Id: 003_edge.t 333 2010-06-02 16:41:31Z tfrayner $

use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Exception;

BEGIN {
    use_ok( 'Bio::MAGETAB::Edge' );
}

INIT {
    use lib 't/testlib';
    use CommonTests qw(test_class);
}

use Bio::MAGETAB::Source;
use Bio::MAGETAB::Sample;
use Bio::MAGETAB::Extract;
use Bio::MAGETAB::Protocol;
use Bio::MAGETAB::ProtocolApplication;

my $so = Bio::MAGETAB::Source->new(  name => 'test source'  );
my $sa = Bio::MAGETAB::Sample->new(  name => 'test sample'  );
my $ex = Bio::MAGETAB::Extract->new( name => 'test extract' );

my $pr = Bio::MAGETAB::Protocol->new( name => 'test protocol' );
my $pa = Bio::MAGETAB::ProtocolApplication->new(
    protocol => $pr,
    date     => '2008-01-01',
);

my %required_attr = (
    inputNode            => $so,
    outputNode           => $sa,
);

my %optional_attr = (
    protocolApplications => [ $pa ],
);

my %bad_attr = (
    inputNode            => [],
    outputNode           => 'test',
    protocolApplications => 'test',
);

my $pa2 = Bio::MAGETAB::ProtocolApplication->new(
    protocol => $pr,
    date     => '2008-01-02',
);

my %secondary_attr = (
    inputNode            => $sa,
    outputNode           => $ex,
    protocolApplications => [ $pa2 ],
);

my $obj = test_class(
    'Bio::MAGETAB::Edge',
    \%required_attr,
    \%optional_attr,
    \%bad_attr,
    \%secondary_attr,
);

ok( $obj->isa('Bio::MAGETAB::BaseClass'), 'object has correct superclass' );

my $ex2 = Bio::MAGETAB::Extract->new( name => 'test extract 2' );
my $ex3 = Bio::MAGETAB::Extract->new( name => 'test extract 3' );

# Test reciprocal relationship between nodes and edges.
is( $obj->get_outputNode(), $sa, 'initial state prior to reciprocity test' );
lives_ok( sub{ $obj->set_outputNode($ex2) }, 'setting outputNode via self' );
is_deeply( $ex2->get_inputEdges(), $obj, 'sets inputEdges in target node' );
lives_ok( sub{ $ex3->set_inputEdges( [ $obj ] ) }, 'setting inputEdges via target node' );
is( $obj->get_outputNode(), $ex3, 'sets outputNode in self' );

# Test for reciprocal relationship establishment on instantiation.
my $obj2;
lives_ok( sub{ $obj2 = Bio::MAGETAB::Edge->new( inputNode => $ex, outputNode => $ex2 ) },
          'edge instantiation with nodes' );
is( $obj2->get_inputNode(), $ex, 'sets inputNode' );
is( $obj2->get_outputNode(), $ex2, 'and outputNode' );
is_deeply( $ex->get_outputEdges(), $obj2, 'and outputEdges in target node' );
is_deeply( [ sort $ex2->get_inputEdges() ], [ sort $obj, $obj2 ], 'and inputEdges in target node' );

# Test implicit deletion upon setting. We've just tested $ex2->get_inputEdges and $ex->get_outputEdges...
lives_ok( sub { $obj2->set_outputNode( $ex3 ) }, 'resetting outputNode succeeds' );
is_deeply( [ sort $ex2->get_inputEdges() ], [ $obj ], 'and deletes the inputEdge on the old node' );
lives_ok( sub { $obj2->set_inputNode( $ex3 ) }, 'resetting inputNode succeeds' );
is_deeply( [ sort $ex->get_outputEdges() ], [ ], 'and deletes the outputEdge on the old node' );

# N.B. we don't bother testing the reciprocal deletion-on-set, because
# a node repointing to a new edge will break the old edge (since both
# input and output are required on an edge). This is a fairly bad
# state of affairs to get into, and it's assumed for now that any
# developer doing this must know what they're doing. FIXME we need a
# note in the docs to this effect (i.e. always update via Edge if
# you're remodelling your graph).

# This should live, and allow garbage collection to destroy both the
# edge and any protocol apps attached to it. The edge still references
# $ex2, but the ref is weakened. This is okay because edges don't have
# multiple outputNodes etc. and so aren't really reusable. FIXME
# consider removing the edge object from any Bio::MAGETAB container,
# though.
lives_ok( sub{ $ex2->clear_inputEdges() }, 'attempt to disconnect edges from node succeeds' );

