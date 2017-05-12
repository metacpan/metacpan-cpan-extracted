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
# $Id: 003_composite_element.t 333 2010-06-02 16:41:31Z tfrayner $

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN {
    use_ok( 'Bio::MAGETAB::CompositeElement' );
}

INIT {
    use lib 't/testlib';
    use CommonTests qw(test_class);
}

require Bio::MAGETAB::DatabaseEntry;
require Bio::MAGETAB::Comment;

my @db;
for ( 1..3 ) {
    push @db, Bio::MAGETAB::DatabaseEntry->new( accession => $_ );
}

my @co;
for ( 1..3 ) {
    push @co, Bio::MAGETAB::Comment->new( name => 'test', value => $_ );
}


my %required_attr = (
    name           => 'test',
);

my %optional_attr = (
    comments          => \@co,
    databaseEntries   => \@db,
    chromosome        => 'chr10',
    startPosition     => 100000,
    endPosition       => 1000510,
);

my %bad_attr = (
    name              => [],
    comments          => 'test',
    databaseEntries   => 'test',
    chromosome        => [],
    startPosition     => 'eleven',
    endPosition       => [],
);

my @db2 = Bio::MAGETAB::DatabaseEntry->new( accession => 'test 2' );
my @co2 = Bio::MAGETAB::Comment->new( name => 'test', value => 'test 2' );

my %secondary_attr = (
    name              => 'test2',
    comments          => \@co2,
    databaseEntries   => \@db2,
    chromosome        => 'chr21',
    startPosition     => 100030,
    endPosition       => 105051,
);

my $obj = test_class(
    'Bio::MAGETAB::CompositeElement',
    \%required_attr,
    \%optional_attr,
    \%bad_attr,
    \%secondary_attr,
);

ok( $obj->isa('Bio::MAGETAB::DesignElement'), 'object has correct superclass' );
