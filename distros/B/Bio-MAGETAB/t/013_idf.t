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
# $Id: 013_idf.t 380 2013-04-30 09:08:39Z tfrayner $

use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Exception;
use File::Temp qw(tempfile);

use lib 't/testlib';
use CommonTests qw( test_parse check_term );

BEGIN {
    use_ok( 'Bio::MAGETAB::Util::Reader::IDF' );
    use_ok( 'Bio::MAGETAB::Util::Writer::IDF' );
}

my $idf;

# Instantiate with none of the required attributes.
dies_ok( sub{ $idf = Bio::MAGETAB::Util::Reader::IDF->new() },
         'instantiation without attributes' );

# Populate our temporary test IDF file.
my ( $fh, $filename ) = tempfile( UNLINK => 1 );
while ( my $line = <DATA> ) {
    print $fh $line;
}

# Close the filehandle, since we'll be using the filename only.
close( $fh ) or die("Error closing filehandle: $!");

# Test parsing.
lives_ok( sub{ $idf = Bio::MAGETAB::Util::Reader::IDF->new( uri => $filename ) },
          'instantiation with uri attribute' );
is( $idf->get_document_version(), undef, 'document version is undef prior to parsing');
my $inv = test_parse( $idf );

# Check multi-comment parsing (not prohibited by spec, so we allow it).
my @comm = $inv->get_comments();
is( scalar @comm, 2, 'correct number of comments');
is( join(";", sort map { $_->get_value() } @comm), 'text1;text2', 'all comment values present');

# Test parsing into a supplied magetab_object.
use Bio::MAGETAB::Investigation;
my $inv2 = Bio::MAGETAB::Investigation->new( title => 'Dummy investigation for testing' );

lives_ok( sub{ $idf = Bio::MAGETAB::Util::Reader::IDF->new( uri            => $filename,
                                                            magetab_object => $inv2, ) },
          'instantiation uri and magetab_object attributes' );
test_parse( $idf );

is( $idf->get_document_version(), '1.1', 'correct MAGE-TAB document version');

# These really ought to look identical.
is_deeply( $inv, $inv2, 'investigation objects agree' );

# FIXME (IMPORTANT!) check the output against what we expect!
my $builder;
lives_ok( sub { $builder = $idf->get_builder(); }, 'IDF parser returns a Builder object' );
is( ref $builder, 'Bio::MAGETAB::Util::Builder', 'of the correct class' );

# Check that the term source was created.
my $ts;
lives_ok( sub { $ts = $builder->get_term_source({
    name => 'RO',
}) }, 'Builder returns a term source' );
is( $ts->get_name(),    'RO',  'with the correct name' );
is( $ts->get_version(), '0.1', 'and the correct version' );
is( $ts->get_uri(), 'http://www.random-ontology.org/file.obo', 'and the correct uri' );

# FIXME test with bad IDF input (unrecognized headers etc.)

# Brief test of the export code; this is nowhere near as thorough as it should be FIXME.
( $fh, $filename ) = tempfile( UNLINK => 1 );
my $idf_writer;

dies_ok( sub{ $idf_writer = Bio::MAGETAB::Util::Writer::IDF->new( filehandle     => $fh,
                                                                  magetab_object => $inv,
                                                                  export_version => '1.2' ) },
         'writer fails to instantiate with an invalid export version' );

foreach my $version ( qw( 1.0 1.1 ) ) {
    lives_ok( sub{ $idf_writer = Bio::MAGETAB::Util::Writer::IDF->new( filehandle     => $fh,
                                                                       magetab_object => $inv,
                                                                       export_version => $version ) },
              "writer instantiates with export version $version" );
}

lives_ok( sub{ $idf_writer->write() }, 'writer outputs IDF data without crashing' );


__DATA__
MAGE-TAB Version	1.1
Investigation Title	Dummy title
# This is a comment to be ignored.
Experimental Design	dummy_design	dummy_design2
Experimental Design Term Source REF	RO	RO
Experimental Design Term Accession Number	111	222
Experimental Factor Name	DUMMYFACTOR
Experimental Factor Type	dummy_factor
Experimental Factor Term Source REF	RO
Person Last Name	Bannister
Person First Name	Bruce
Person Mid Initials	B
Person Email	greenmeanie@bannister.com
Person Phone	01 234 5678
Person Fax	01 234 6789
Person Address	Arkansas, USA
Person Affiliation	Projects-R-Us
Person Roles	investigator
Person Roles Term Source REF	RO
Person Roles Term Accession Number	12345
Quality Control Type	poor
Quality Control Term Source REF	RO
Replicate Type	few
Replicate Term Source REF	RO
Normalization Type	none
Normalization Term Source REF	RO
Date of Experiment	2008-09-04
Public Release Date	2009-09-04
PubMed ID	1234567
Publication DOI	doi:10.1186/1471-2105-7-489
Publication Author List	Joe Schmoe, John Q. Public, Joseph Bloggs, Bruce Bannister
Publication Title	How to make friends and influence government officials
Publication Status	not published
Publication Status Term Source REF	RO
Experiment Description	not a real experiment
Protocol Name	how to extract DNA
Protocol Type	nucleic_acid_extraction
Protocol Description	blah blah blah
Protocol Parameters	strength; duration
Protocol Hardware	big expensive machine
Protocol Software	correspondingly expensive proprietary junk
Protocol Contact	random string here
Protocol Term Source REF	RO
SDRF File	dummy.txt
Term Source Name	RO
Term Source File	http://www.random-ontology.org/file.obo
Term Source Version	0.1  
Comment[here's a comment]	text1	text2
