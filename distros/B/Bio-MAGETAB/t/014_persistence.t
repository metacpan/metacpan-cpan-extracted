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
# $Id: 014_persistence.t 333 2010-06-02 16:41:31Z tfrayner $

# Basic tests for the Persistence module. FIXME this needs to be
# extended to test insertion, update, retrieval and deletion of all
# instantiable Bio::MAGETAB classes.

use strict;
use warnings;

use Test::More tests => 21;
use Test::Exception;
use File::Spec;

use Bio::MAGETAB;

my $dbfile = File::Spec->catfile('t','test_sqlite.db');
if ( -e $dbfile ) {
    unlink $dbfile or die("Error unlinking pre-existing test database file: $!");
}

my $dsn    = "dbi:SQLite:$dbfile";

SKIP: {

    eval {
        require Tangram;
        require DBI;
        require DBD::SQLite;
    };

    skip 'Tests require Tangram, DBI and DBD::SQLite to be installed',
	21 if $@;

    require_ok( 'Bio::MAGETAB::Util::Persistence');

    my $db;
    lives_ok( sub{ $db = Bio::MAGETAB::Util::Persistence->new( dbparams => [ $dsn ] )},
              'Persistence object instantiates okay');

    lives_ok( sub{ $db->deploy() }, 'and deploys database schema');

    lives_ok( sub{ $db->connect() }, 'to which we can successfully connect');

    {
        my $cv = Bio::MAGETAB::ControlledTerm->new({ category => 'testcat',
                                                     value    => 'testval', });
        lives_ok( sub{ $db->insert( $cv ) }, 'and insert a ControlledTerm');
        $cv->set_accession( '12345' );
        lives_ok( sub{ $db->update( $cv ) }, 'update the ControlledTerm' );

        lives_ok( sub{ $db->insert(
            Bio::MAGETAB::Sample->new({ name         => 'test_sample',
                                        namespace    => 'me',
                                        materialType => $cv, }) ) },
                  'insert a Sample');
    }

    my $rem;
    lives_ok( sub{ $rem = $db->remote('Bio::MAGETAB::ControlledTerm') },
              'retrieve remote term');
    my @ncv;
    lives_ok( sub{ @ncv = $db->select( $rem, $rem->{category} eq 'testcat' & $rem->{value} eq 'testval') },
              'and use it to query the database');
    is( ref $ncv[0], 'Bio::MAGETAB::ControlledTerm', 'to retrieve an object with the desired class');
    is( $ncv[0]->get_accession(), '12345', 'with the correctly updated accession');

    lives_ok( sub{ $db->erase( $ncv[0] ) }, 'calls to erase live');
    lives_ok( sub{ @ncv = $db->select( $rem ) }, 'retrieval of all terms');
    is( scalar @ncv, 0, 'now gives an empty array' );
    
    lives_ok( sub{ $db->insert( Bio::MAGETAB::Source->new({
        name         => 'test_source',
        providers    => [ map { Bio::MAGETAB::Contact->new({ lastName => $_ }) } qw( me them others ) ]
    }))}, 'insert a Source');

    my $obj;
    lives_ok( sub{ $obj = $db->remote( 'Bio::MAGETAB::Source' ) },
              'we can retrieve a remote Source object');

    my @sources;
    lives_ok( sub{ @sources = $db->select( $obj, $obj->{name} eq 'test_source' )},
              'and use it to query the database');

    is( ref $sources[0], 'Bio::MAGETAB::Source', 'to retrieve an object with the desired class');

    dies_ok( sub{ $sources[0]->set_name(undef) }, 'which obeys the original Moose type constraints');

    is( $sources[0]->get_name(), 'test_source', 'and has the correct name attribute' );

    is_deeply( [ sort map { $_->get_lastName() } $sources[0]->get_providers() ],
               [ qw( me others them ) ],
               'and links to the correct provider Contacts');

    unlink $dbfile or die("Error unlinking test database file: $!");
}
