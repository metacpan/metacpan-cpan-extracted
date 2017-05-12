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
# $Id: 013_data_matrix.t 368 2012-05-28 15:49:02Z tfrayner $

use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Exception;
use File::Temp qw(tempfile);

use lib 't/testlib';
use CommonTests qw( test_parse check_term );

BEGIN {
    use_ok( 'Bio::MAGETAB::Util::Reader::DataMatrix' );
}

sub add_dummy_objects {

    my ( $builder ) = @_;

    my $tt = $builder->find_or_create_controlled_term({ category => 'TechnologyType',
                                                        value    => 'hybridization' });
    foreach my $assay ( qw( Hyb1 Hyb2 ) ) {
        $builder->create_assay({ name           => $assay,
                                 technologyType => $tt });
    }
    foreach my $rep ( qw( R1 R2 R3 ) ) {
        $builder->create_reporter({ name => $rep });
    }

    return;
}

my $dm_reader;

# Instantiate with none of the required attributes.
dies_ok( sub{ $dm_reader = Bio::MAGETAB::Util::Reader::DataMatrix->new() },
         'instantiation without attributes' );

# Populate our temporary test DataMatrix file.
my ( $fh, $filename ) = tempfile( UNLINK => 1 );
while ( my $line = <DATA> ) {
    print $fh $line;
}

# Close the filehandle, since we'll be using the filename only.
close( $fh ) or die("Error closing filehandle: $!");

# Test parsing. First, create a parser object.
lives_ok( sub{ $dm_reader = Bio::MAGETAB::Util::Reader::DataMatrix->new( uri => $filename ) },
          'instantiation with uri attribute' );

# Get the underlying Builder object.
my $builder;
lives_ok( sub { $builder = $dm_reader->get_builder(); }, 'DataMatrix parser returns a Builder object' );
is( ref $builder, 'Bio::MAGETAB::Util::Builder', 'of the correct class' );

# Add some dummy objects.
add_dummy_objects( $builder );

# Test that we can parse the DM.
my $dm = test_parse( $dm_reader );
is( scalar @{ $dm->get_matrixColumns() }, 4, 'Parser detects the correct number of columns');

# Test parsing into a supplied magetab_object.
use Bio::MAGETAB::DataMatrix;
use Bio::MAGETAB::ControlledTerm;
my $mtype = Bio::MAGETAB::ControlledTerm->new( category => 'DataType',
                                               value    => 'Dummy', );
my $dm2 = Bio::MAGETAB::DataMatrix->new( uri      => $filename,
                                         dataType => $mtype, );

lives_ok( sub{ $dm_reader = Bio::MAGETAB::Util::Reader::DataMatrix->new(
    uri            => $filename,
    magetab_object => $dm2, ) },
          'instantiation uri and magetab_object attributes' );

add_dummy_objects( $dm_reader->get_builder() );

# Confirm that we can parse the DM.
test_parse( $dm_reader );

# These really ought to look identical.
TODO: {
    local $TODO = 'designElements are unordered so this test fails.';
    is_deeply( $dm, $dm2, 'array design objects agree' );
}

# FIXME (IMPORTANT!) check the output against what we expect!


__DATA__
Hybridization REF	Hyb1	Hyb1	Hyb2	Hyb2
Reporter REF	intensity	stddev	intensity	stddev
R1	1	2	3	4
R2	1.1	2.2	3.3	4.4
R3	2.2	3.3	4.4	5.5
