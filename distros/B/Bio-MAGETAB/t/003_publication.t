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
# $Id: 003_publication.t 333 2010-06-02 16:41:31Z tfrayner $

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN {
    use_ok( 'Bio::MAGETAB::Publication' );
}

INIT {
    use lib 't/testlib';
    use CommonTests qw(test_class);
}

use Bio::MAGETAB::ControlledTerm;

my $ct = Bio::MAGETAB::ControlledTerm->new( category => 1, value => 2 );

my %required_attr = (
    title      => 'test title',
);

my %optional_attr = (
    pubMedID   => '23998712',
    authorList => 'test authors',
    DOI        => '12342349o87',
    status     => $ct,
);

my %bad_attr = (
    pubMedID   => [],
    authorList => [],
    title      => [],
    DOI        => [],
    status     => 'test',
);

my $ct2 = Bio::MAGETAB::ControlledTerm->new( category => 1, value => 4 );

my %secondary_attr = (
    pubMedID   => '23912',
    authorList => 'test authors 2',
    title      => 'test title 2',
    DOI        => '12342349o872',
    status     => $ct2,
);

my $obj = test_class(
    'Bio::MAGETAB::Publication',
    \%required_attr,
    \%optional_attr,
    \%bad_attr,
    \%secondary_attr,
);

ok( $obj->isa('Bio::MAGETAB::BaseClass'), 'object has correct superclass' );
