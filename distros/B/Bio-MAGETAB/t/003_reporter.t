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
# $Id: 003_reporter.t 333 2010-06-02 16:41:31Z tfrayner $

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN {
    use_ok( 'Bio::MAGETAB::Reporter' );
}

INIT {
    use lib 't/testlib';
    use CommonTests qw(test_class);
}

require Bio::MAGETAB::DatabaseEntry;
require Bio::MAGETAB::ControlledTerm;
require Bio::MAGETAB::CompositeElement;

my @db;
for ( 1..3 ) {
    push @db, Bio::MAGETAB::DatabaseEntry->new( accession => $_ );
}

my @ce;
for ( 1..3 ) {
    push @ce, Bio::MAGETAB::CompositeElement->new( name => 'test' );
}

my $ct = Bio::MAGETAB::ControlledTerm->new( category => 'test', value => 'test' );

my %required_attr = (
    name              => 'test',
);

my %optional_attr = (
    controlType       => $ct,
    groups            => [ $ct ],
    sequence          => 'atcg',
    databaseEntries   => \@db,
    compositeElements => \@ce,
    chromosome        => 'chr1',
    startPosition     => 100000,
    endPosition       => 100051,
);

my %bad_attr = (
    name              => [],
    controlType       => 'test',
    groups            => 'test',
    sequence          => [],
    databaseEntries   => \@ce,
    compositeElements => \@db,
    chromosome        => [],
    startPosition     => 'ten',
    endPosition       => [],
);

my $ct2 = Bio::MAGETAB::ControlledTerm->new( category => 'test', value => 'test 2' );

my %secondary_attr = (
    name              => 'test2',
    controlType       => $ct2,
    groups            => [ $ct2 ],
    sequence          => 'atcg',
    databaseEntries   => [ $db[0] ],
    compositeElements => [ $ce[1] ],
    chromosome        => 'chr12',
    startPosition     => 2100000,
    endPosition       => 2100051,
);

my $obj = test_class(
    'Bio::MAGETAB::Reporter',
    \%required_attr,
    \%optional_attr,
    \%bad_attr,
    \%secondary_attr,
);

ok( $obj->isa('Bio::MAGETAB::DesignElement'), 'object has correct superclass' );
