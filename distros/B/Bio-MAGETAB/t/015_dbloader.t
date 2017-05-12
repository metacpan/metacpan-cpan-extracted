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
# $Id: 015_dbloader.t 333 2010-06-02 16:41:31Z tfrayner $

# Basic tests for the DBLoader module.

use strict;
use warnings;

use Test::More tests => 34;
use Test::Exception;
use File::Spec;

my $dbfile = File::Spec->catfile('t','test_sqlite.db');
if ( -e $dbfile ) {
    unlink $dbfile or die("Error unlinking pre-existing test database file: $!");
}

my $dsn = "dbi:SQLite:$dbfile";

SKIP: {

    eval {
        require Bio::MAGETAB::Util::Persistence;
    };

    skip 'Tests require Bio::MAGETAB::Util::Persistence to be loadable',
	34 if $@;

    my $db = Bio::MAGETAB::Util::Persistence->new({ dbparams => [ $dsn ] });
    $db->deploy();
    $db->connect();

    require_ok('Bio::MAGETAB::Util::DBLoader');

    my $loader;
    lives_ok( sub { $loader = Bio::MAGETAB::Util::DBLoader->new({ database => $db }) },
               'Loader instantiates okay' );

    # Start by trying some simple CRU(notD) with TermSource, which has
    # no complications (see below).
    {
        my $ts;
        lives_ok( sub { $ts = $loader->create_term_source({ name => 'test_term_source' }) },
                  'TermSource created' );
        ok( UNIVERSAL::isa( $ts, 'Bio::MAGETAB::TermSource' ), 'of the correct class' );
    }

    my $oid;
    {
        my $ts;
        lives_ok( sub { $ts = $loader->get_term_source({ name => 'test_term_source' }) },
                  'TermSource retrieved' );
        ok( UNIVERSAL::isa( $ts, 'Bio::MAGETAB::TermSource' ), 'of the correct class' );        
        dies_ok( sub { $ts = $loader->get_term_source({ name => 'not_the_correct_name' }) },
                 'non-existent TermSource is not retrieved' );
        $oid = $loader->id( $ts );
    }

    {
        my $ts;
        lives_ok( sub { $ts = $loader->find_or_create_term_source({ name    => 'test_term_source',
                                                                    version => 0.9 }) },
                  'old TermSource find_or_created' );
        ok( UNIVERSAL::isa( $ts, 'Bio::MAGETAB::TermSource' ), 'of the correct class' );
        is( $oid, $loader->id( $ts ), 'and identical to the original' );
        is( $ts->get_version(), 0.9, 'but with updated version attribute' );
    }

    {
        my $ts;
        lives_ok( sub { $ts = $loader->find_or_create_term_source({ name => 'new_term_source' }) },
                  'new TermSource find_or_created' );
        ok( UNIVERSAL::isa( $ts, 'Bio::MAGETAB::TermSource' ), 'of the correct class' );
    }

    # Now we test with Edges, where the ID depends on linked objects
    # (rather than strings).
    my ($m1, $m2);
    {
        lives_ok( sub { $m1 = $loader->find_or_create_source({ name => 'test_source' }) },
                  'new Source find_or_created' );
        lives_ok( sub { $m2 = $loader->find_or_create_sample({ name => 'test_sample' }) },
                  'new Sample find_or_created' );
        my $e;
        lives_ok( sub { $e = $loader->find_or_create_edge({ inputNode  => $m1,
                                                            outputNode => $m2, }) },
                  'new Edge find_or_created' );
        ok( UNIVERSAL::isa( $e, 'Bio::MAGETAB::Edge' ), 'of the correct class' );
        $oid = $loader->id( $e );
    }
    {
        my $e;
        lives_ok( sub { $e = $loader->find_or_create_edge({ inputNode  => $m1,
                                                            outputNode => $m2, }) },
                  'old Edge find_or_created' );
        is( $oid, $loader->id( $e ), 'identical to the original' );
    }

    # Test for things where ID depends on aggregators.
    my ( $ad, $ad2, $oid2 );
    my $r = $loader->find_or_create_reporter({ name => 'test_reporter' });
    {
        lives_ok( sub { $ad = $loader->find_or_create_array_design({
            name => 'test_array_design' }) },
                  'ArrayDesign created' );
        my $f;
        lives_ok( sub { $f = $loader->find_or_create_feature({ blockCol => 1,
                                                               blockRow => 2,
                                                               col => 3,
                                                               row => 4,
                                                               reporter => $r,
                                                               array_design => $ad }) },
                  'new Feature (AD 1) find_or_created' );

        # FIXME wouldn't it be nicer to have the DBLoader do this for us?
        $ad->set_designElements( [ $f, $r ] );
        lives_ok( sub { $loader->update( $ad ) }, 'array design AD 1 updated' );
        
        ok( UNIVERSAL::isa( $f, 'Bio::MAGETAB::Feature' ), 'of the correct class' );
        $oid = $loader->id( $f );

        # Second array design, new feature.
        $ad2 = $loader->find_or_create_array_design({
            name => 'test_array_design 2' });
        lives_ok( sub { $f = $loader->find_or_create_feature({ blockCol => 1,
                                                               blockRow => 2,
                                                               col => 3,
                                                               row => 4,
                                                               reporter => $r,
                                                               array_design => $ad2 }) },
                  'new Feature (AD 2) find_or_created' );
        $ad2->set_designElements( [ $f, $r ] );
        lives_ok( sub { $loader->update( $ad2 ) }, 'array design AD 2 updated' );
        $oid2 = $loader->id( $f );
    }
    {
        my $f;
        lives_ok( sub { $f = $loader->get_feature({ blockCol => 1,
                                                    blockRow => 2,
                                                    col => 3,
                                                    row => 4,
                                                    reporter => $r,
                                                    array_design => $ad }) },
                  'retrieved Feature' );
        ok( UNIVERSAL::isa( $f, 'Bio::MAGETAB::Feature' ), 'of the correct class' );
        is( $oid, $loader->id( $f ),
            'identical to the original (AD 1)');
    }
    {
        my $f;
        lives_ok( sub { $f = $loader->get_feature({ blockCol => 1,
                                                    blockRow => 2,
                                                    col => 3,
                                                    row => 4,
                                                    reporter => $r,
                                                    array_design => $ad2 }) },
                  'retrieved Feature' );
        ok( UNIVERSAL::isa( $f, 'Bio::MAGETAB::Feature' ), 'of the correct class' );
        is( $oid2, $loader->id( $f ),
            'identical to the original (AD 2)');
    }

    # Test that there are two Features in the DB at this point.
    {
        my $rem = $loader->remote('Bio::MAGETAB::Feature');
        is( $loader->count( $rem->{ id } ), 2,
            'database contains the correct number of Features');
    }

    # Test for update of ArrayRef attributes.
    {
        my $design = $loader->find_or_create_controlled_term({
            category => 'DesignType',
            value    => 'test1',
        });
        $loader->find_or_create_investigation({
            title       => 'test_investigation',
            designTypes => [ $design ],
        });
        my $design2 = $loader->find_or_create_controlled_term({
            category => 'DesignType',
            value    => 'test2',
        });
        $loader->find_or_create_investigation({
            title       => 'test_investigation',
            designTypes => [ $design, $design2 ],
        });
    }
    {
        my $inv = $loader->find_or_create_investigation({ title => 'test_investigation' });
        my @types = $inv->get_designTypes();
        is ( scalar @types, 2, '1..N attribute updates successfully' );
        is_deeply( [ sort map { $_->get_value() } @types ],
                   [ qw( test1 test2 ) ],
                   'with the correct target values' );
    }


    # FIXME also test for creation and retrieval of DatabaseEntry with
    # TermSource and no namespace/authority.

    unlink $dbfile or die("Error unlinking test database file: $!");
}
