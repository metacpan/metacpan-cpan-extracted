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
# $Id: 004_magetab.t 333 2010-06-02 16:41:31Z tfrayner $

use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Exception;

BEGIN {
    use_ok( 'Bio::MAGETAB' );
}

# Test that we've loaded at least one subclass of
# Bio::MAGETAB::BaseClass (should really do them all, FIXME?).
my $db1;
lives_ok( sub{ $db1 = Bio::MAGETAB::DatabaseEntry->new( accession => 1234 ) },
          'knows how to create a DatabaseEntry object' );
ok( $db1->isa('Bio::MAGETAB::DatabaseEntry'), 'of the correct class' );

# Confirm that there's no container set for this instance.
ok( ! defined $db1->get_ClassContainer(), 'and with no container object set' );

# Create our MAGETAB container object.
dies_ok( sub{ Bio::MAGETAB->new( not_a_real_attribute => 1 ) },
         'object instantiation with unrecognised attribute fails' ); 
my $obj;
lives_ok( sub{ $obj = Bio::MAGETAB->new() }, 'can create a MAGETAB object' );
ok( $obj->isa('Bio::MAGETAB'), 'of the correct class' );
ok( ! $obj->has_databaseEntries(), 'with no associated DatabaseEntry objects' );

# Evaluated in scalar context, this gives zero for an empty array..
is( $obj->get_databaseEntries(), 0, 'and get_databaseEntries agrees' );

# Now create a new object that will associate with this container automatically.
my $db2;
lives_ok( sub{ $db2 = Bio::MAGETAB::DatabaseEntry->new( accession => 4321 ) },
          'creates a contained DatabaseEntry object' );
ok( $db2->isa('Bio::MAGETAB::DatabaseEntry'), 'of the correct class' );

# Confirm that the container is now set for these instances.
is( $db2->get_ClassContainer(), $obj, 'which points to our container object' );
is( $db2->get_ClassContainer(), $obj, 'as does the original DatabaseEntry object' );

# Check that we can list the objects:
ok( $obj->has_databaseEntries(), 'container has associated DatabaseEntry objects' );
is_deeply( $obj->get_databaseEntries(), $db2, 'container object lists one DatabaseEntry' );

# We can add objects to the container:
lives_ok( sub { $obj->add_objects( $db1 ) }, 'Can add objects to the container' );
is_deeply( [ sort $obj->get_databaseEntries() ], [ sort $db2, $db1 ],
           'container object lists two DatabaseEntries' );

# But not duplicates:
lives_ok( sub { $obj->add_objects( $db2 ) }, 'Can try adding duplicate objects to the container' );
is_deeply( [ sort $obj->get_databaseEntries() ], [ sort $db2, $db1 ],
           'but container object still only lists two DatabaseEntries' );

# Full listing of objects.
my $norm;
lives_ok( sub { $norm = Bio::MAGETAB::Normalization->new( name => "test normalization" ) },
          'instantiates a Normalization object' );
is_deeply( [ sort $obj->get_objects() ], [ sort $db2, $db1, $norm ],
           'container object now lists objects from both classes' );

# Check the return values for accessors listing objects from superclasses. 
my $mat;
lives_ok( sub { $mat = Bio::MAGETAB::Sample->new( name => "test sample" ) },
          'instantiates a Sample object' );
is_deeply( $obj->get_normalizations(), $norm,
           'get_normalizations returns all normalizations' );
is_deeply( $obj->get_events(), $norm,
           'get_events returns all events' );
is_deeply( $obj->get_samples(), $mat,
           'get_samples returns all samples' );
is_deeply( $obj->get_materials(), $mat,
           'get_materials returns all materials' );
is_deeply( [ sort $obj->get_nodes() ], [ sort $mat, $norm ],
           'get_nodes returns all nodes' );

# Check that we can delete objects.
lives_ok( sub { $obj->delete_objects( $db2 ) }, 'can delete objects from the container' );
is_deeply( $obj->get_databaseEntries(), $db1,
           'and get_databaseEntries reflects this' );
is_deeply( [ sort $obj->get_objects() ], [ sort $db1, $norm, $mat ],
           'as does get_objects' );
