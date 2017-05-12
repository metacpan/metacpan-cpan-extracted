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
# $Id: 003_contact.t 333 2010-06-02 16:41:31Z tfrayner $

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN {
    use_ok( 'Bio::MAGETAB::Contact' );
}

INIT {
    use lib 't/testlib';
    use CommonTests qw(test_class);
}

require Bio::MAGETAB::ControlledTerm;
require Bio::MAGETAB::Comment;

my @ct;
for ( 1..3 ) {
    push @ct, Bio::MAGETAB::ControlledTerm->new( category => 'test', value => $_ );
}

my @co;
for ( 1..3 ) {
    push @co, Bio::MAGETAB::Comment->new( name => 'test', value => $_ );
}

my %required_attr = (
    lastName       => 'rabbit',
);

my %optional_attr = (
    firstName    => 'roger',
    midInitials  => 't',
    email        => 'roger@dodger.com',
    organization => 'test',
    phone        => '001 1234356',
    fax          => '002 2737482',
    address      => 'somewhere, someplace',
    roles        => \@ct,
    comments     => \@co,
);

my %bad_attr = (
    lastName     => [],
    firstName    => [],
    midInitials  => [],
    email        => 'this is not an email address',
    organization => [],
    phone        => [],
    fax          => [],
    address      => [],
    roles        => 'test',
    comments     => 'test',
);

my @ct2 = Bio::MAGETAB::ControlledTerm->new( category => 'test', value => 'test 2' );
my @co2 = Bio::MAGETAB::Comment->new( name => 'test', value => 'test 2' );

my %secondary_attr = (
    lastName     => 'test 2',
    firstName    => 'test 2',
    midInitials  => 't 2',
    email        => 'roger2@dodger.com',
    organization => 'test 2',
    phone        => '001 134356',
    fax          => '002 237482',
    address      => 'somewhere, someplace else',
    roles        => \@ct2,
    comments     => \@co2,
);

my $obj = test_class(
    'Bio::MAGETAB::Contact',
    \%required_attr,
    \%optional_attr,
    \%bad_attr,
    \%secondary_attr,
);

ok( $obj->isa('Bio::MAGETAB::BaseClass'), 'object has correct superclass' );
