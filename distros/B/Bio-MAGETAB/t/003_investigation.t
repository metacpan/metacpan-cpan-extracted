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
# $Id: 003_investigation.t 333 2010-06-02 16:41:31Z tfrayner $

use strict;
use warnings;

use Test::More qw(no_plan);

use DateTime;

BEGIN {
    use_ok( 'Bio::MAGETAB::Investigation' );
}

INIT {
    use lib 't/testlib';
    use CommonTests qw(test_class);
}

my %required_attr = (
    title               => 'test',
);

use Bio::MAGETAB::Publication;
use Bio::MAGETAB::Protocol;
use Bio::MAGETAB::Contact;
use Bio::MAGETAB::ControlledTerm;
use Bio::MAGETAB::Factor;
use Bio::MAGETAB::TermSource;
use Bio::MAGETAB::Comment;
use Bio::MAGETAB::SDRF;
use Bio::MAGETAB::SDRFRow;
use Bio::MAGETAB::Normalization;

my $publ = Bio::MAGETAB::Publication->new( title => 'test publication' );
my $prot = Bio::MAGETAB::Protocol->new( name => 'test protocol' );
my $cont = Bio::MAGETAB::Contact->new( lastName => 'test contact' );
my $cote = Bio::MAGETAB::ControlledTerm->new( category => 'test', value => 'test' );
my $fact = Bio::MAGETAB::Factor->new( name => 'test factor' );
my $teso = Bio::MAGETAB::TermSource->new( name => 'test termsource' );
my $comm = Bio::MAGETAB::Comment->new( name => 'test comment', value => 'value' );
my $norm = Bio::MAGETAB::Normalization->new( name => 'test norm' );
my $srow = Bio::MAGETAB::SDRFRow->new( nodes => [ $norm ] );
my $sdrf = Bio::MAGETAB::SDRF->new( sdrfRows => [ $srow ], uri => 'http://test.com' );

# Dates can be flexibly expressed as anything Date::Manip will
# understand.
my %optional_attr = (
    publications        => [ $publ ],
    protocols           => [ $prot ],
    contacts            => [ $cont ],
    date                => '2008-01-01T00:00:00',
    publicReleaseDate   => '2009-01-01T00:00:00',
    description         => 'test description',
    designTypes         => [ $cote ],
    replicateTypes      => [ $cote ],
    qualityControlTypes => [ $cote ],
    normalizationTypes  => [ $cote ],
    factors             => [ $fact ],
    termSources         => [ $teso ],
    comments            => [ $comm ],
    sdrfs               => [ $sdrf ],
);

my %bad_attr = (
    title               => [],
    publications        => 'test',
    protocols           => 'test',
    contacts            => 'test',
    date                => [],
    publicReleaseDate   => [],
    description         => [],
    designTypes         => 'test',
    replicateTypes      => 'test',
    qualityControlTypes => 'test',
    normalizationTypes  => 'test',
    factors             => 'test',
    termSources         => 'test',
    comments            => 'test',
    sdrfs               => 'test',
);

my $publ2 = Bio::MAGETAB::Publication->new( pubMedID => '12345678', title => 'test title 2' );
my $prot2 = Bio::MAGETAB::Protocol->new( name => 'test protocol 2' );
my $cont2 = Bio::MAGETAB::Contact->new( lastName => 'test contact 2' );
my $cote2 = Bio::MAGETAB::ControlledTerm->new( category => 'test', value => 'test 2' );
my $fact2 = Bio::MAGETAB::Factor->new( name => 'test factor 2' );
my $teso2 = Bio::MAGETAB::TermSource->new( name => 'test termsource 2' );
my $comm2 = Bio::MAGETAB::Comment->new( name => 'test comment', value => 'value 2' );
my $norm2 = Bio::MAGETAB::Normalization->new( name => 'test norm 2' );
my $srow2 = Bio::MAGETAB::SDRFRow->new( nodes => [ $norm2 ] );
my $sdrf2 = Bio::MAGETAB::SDRF->new( sdrfRows => [ $srow, $srow2 ], uri => 'file:///~/test.txt' );

# N.B. dates may also be expressed as a hashref to be passed to
# DateTime->new(), but we don't test that here.
my %secondary_attr = (
    title               => 'test2',
    publications        => [ $publ2 ],
    protocols           => [ $prot2 ],
    contacts            => [ $cont2 ],
    date                => DateTime->new( year => 2008, month=> 01, day=> 02 ),
    publicReleaseDate   => DateTime->new( year => 2009, month=> 01, day=> 02 ),
    description         => 'test description 2',
    designTypes         => [ $cote2 ],
    replicateTypes      => [ $cote2 ],
    qualityControlTypes => [ $cote2 ],
    normalizationTypes  => [ $cote2 ],
    factors             => [ $fact2 ],
    termSources         => [ $teso2 ],
    comments            => [ $comm2 ],
    sdrfs               => [ $sdrf2 ],
);

# We need to specify UTC as the time zone, since Date::Manip returns
# UTC times by default.
$ENV{'TZ'} = 'UTC';

my $obj = test_class(
    'Bio::MAGETAB::Investigation',
    \%required_attr,
    \%optional_attr,
    \%bad_attr,
    \%secondary_attr,
);

ok( $obj->isa('Bio::MAGETAB::BaseClass'), 'object has correct superclass' );
