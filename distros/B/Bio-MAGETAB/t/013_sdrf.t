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
# $Id: 013_sdrf.t 384 2014-04-04 16:15:47Z tfrayner $

use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Exception;
use File::Temp qw(tempfile);

use lib 't/testlib';
use CommonTests qw( test_parse check_term );

BEGIN {
    use_ok( 'Bio::MAGETAB::Util::Reader::SDRF' );
    use_ok( 'Bio::MAGETAB::Util::Writer::SDRF' );
}

sub add_dummy_objects {

    my ( $builder ) = @_;

    foreach my $tsname ( 'NCI META', 'MO', 'ArrayExpress' ) {
        $builder->find_or_create_term_source({ name => $tsname });
    }
    foreach my $adname ( 'A-TEST-1' ) {
        $builder->find_or_create_array_design({ name => $adname });
    }
    foreach my $efname ( 'EF1', 'EF2' ) {
        $builder->find_or_create_factor({ name => $efname });
    }
    my %proto = (
        'EXTPRTCL10654'  => 'Extracted Product',
        'TRANPRTCL10656' => '',
    );
    while ( my ( $protoname, $param ) = each %proto ) {
        my $p = $builder->find_or_create_protocol({ name => $protoname });
        $builder->find_or_create_protocol_parameter({ name => $param, protocol => $p }) if $param;
    }

    return;
}

my $sdrf_reader;

# Instantiate with none of the required attributes.
dies_ok( sub{ $sdrf_reader = Bio::MAGETAB::Util::Reader::SDRF->new() },
         'instantiation without attributes' );

# Populate our temporary test SDRF file.
my ( $fh, $filename ) = tempfile( UNLINK => 1 );
while ( my $line = <DATA> ) {
    print $fh $line;
}

# Close the filehandle, since we'll be using the filename only.
close( $fh ) or die("Error closing filehandle: $!");

# Test parsing.
lives_ok( sub{ $sdrf_reader = Bio::MAGETAB::Util::Reader::SDRF->new( uri => $filename ) },
          'instantiation with uri attribute' );
my $builder;
lives_ok( sub { $builder = $sdrf_reader->get_builder(); }, 'SDRF parser returns a Builder object' );
is( ref $builder, 'Bio::MAGETAB::Util::Builder', 'of the correct class' );

add_dummy_objects( $builder );

my $sdrf;
lives_ok( sub { $sdrf = test_parse( $sdrf_reader ) }, 'parsing completes without exceptions' );

# Check that FV->measurement creation is behaving more or less correctly.
my @fvs = grep { $_->get_factor()->get_name() eq 'EF2' } $sdrf->get_ClassContainer->get_factorValues();
is( scalar @fvs, 3, 'recognising the correct number of Measurement FVs');

my @fv_vals = sort map { int($_->get_measurement()->get_value()) } @fvs;
is_deeply(\@fv_vals, [0, 10, 10],  'with the correct values');

my @fv_units = sort map { $_->get_measurement()->get_unit()->get_value() } @fvs;
is_deeply(\@fv_units, ['mM', 'mg_per_mL', 'mg_per_mL'],  'and the correct units');

# Test parsing into a supplied magetab_object.
use Bio::MAGETAB::SDRF;
my $sdrf2 = Bio::MAGETAB::SDRF->new( uri => $filename );

lives_ok( sub{ $sdrf_reader = Bio::MAGETAB::Util::Reader::SDRF->new( uri            => $filename,
                                                                     magetab_object => $sdrf2, ) },
          'parser instantiates with uri and magetab_object attributes' );

# Brief test of the export code; this is nowhere near as thorough as it should be FIXME.
( $fh, $filename ) = tempfile( UNLINK => 1 );
my $sdrf_writer;

dies_ok( sub{ $sdrf_writer = Bio::MAGETAB::Util::Writer::SDRF->new( filehandle     => $fh,
                                                                    magetab_object => $sdrf,
                                                                    export_version => '1.2' ) },
         'writer fails to instantiate with an invalid export version' );

foreach my $version ( qw( 1.0 1.1 ) ) {
    lives_ok( sub{ $sdrf_writer = Bio::MAGETAB::Util::Writer::SDRF->new( filehandle     => $fh,
                                                                         magetab_object => $sdrf,
                                                                         export_version => $version ) },
              "writer instantiates with export version $version" );
}

lives_ok( sub{ $sdrf_writer->write() }, 'writer outputs SDRF data without crashing' );


#########
# These tests take a long time to run and don't really contribute much.
#add_dummy_objects( $sdrf_reader->get_builder() );
#test_parse( $sdrf_reader );

# These two sets of parse results really ought to look identical.
#is_deeply( $sdrf, $sdrf2, 'SDRF objects agree' );
#########

# FIXME (IMPORTANT!) check the output against what we expect!

# FIXME test with bad SDRF input (unrecognized headers etc.)

# Check that assay comments are being processed correctly.
( $fh, $filename ) = tempfile( UNLINK => 1 );
print $fh join("\t", ('Assay Name', 'Comment[com3]','Technology Type', 'Comment[com1]', 'Comment[com2]')) . "\n";
print $fh join("\t", ('Assay 1', 'com text 3','high throughput seq', 'com text 1', 'com text 2')) . "\n";
close( $fh ) or die("Error closing filehandle: $!");

$sdrf_reader = Bio::MAGETAB::Util::Reader::SDRF->new( uri => $filename );
$sdrf = test_parse( $sdrf_reader );

my $tt = join(";", map { $_->get_value }
                  $sdrf_reader->get_builder()->get_assay({ name => 'Assay 1' })->get_comments());
is( $tt, 'com text 3;com text 1;com text 2', 'Assay comments parsing correctly');

# Check that Array Design REF can be attached to Assay Name.
( $fh, $filename ) = tempfile( UNLINK => 1 );
print $fh join("\t", ('Assay Name', 'Array Design REF','Comment[com1]','Technology Type')) . "\n";
print $fh join("\t", ('Assay 1', 'Design 1','Comment 1', 'tt')) . "\n";
close( $fh ) or die("Error closing filehandle: $!");

$sdrf_reader = Bio::MAGETAB::Util::Reader::SDRF->new( uri => $filename );
$sdrf_reader->get_builder->create_array_design({name => 'Design 1'});
$sdrf = test_parse( $sdrf_reader );

my $assay = $sdrf_reader->get_builder()->get_assay({ name => 'Assay 1' });
my $ad = $assay->get_arrayDesign();
is( $ad->get_name(), 'Design 1', 'Assay Array Design correctly linked' );
is( join(";", map { $_->get_value } $ad->get_comments()), 'Comment 1',
    'Array Design commented correctly');

__DATA__
Source Name	Provider	Characteristics[ OrganismPart ]	Characteristics[DiseaseState]	Term Source REF:test namespace	Term Accession Number	Material Type	Description	Comment[MyNVT]	Sample Name	Characteristics[Age]	Unit[TimeUnit]	Term Source REF	Material Type	Comment[sample comment]	Protocol REF	Performer	Parameter Value[Extracted Product]	Date	Comment[P_COMM]	Extract Name	Material Type	LabeledExtract Name	MaterialType	Term Source REF	Label	Term Source REF	Protocol REF	Term Source REF	Hybridization Name	Comment[some comment about the hyb]	Array Design REF	Comment[some comment about the array]	Protocol REF:made-up namespace:	Scan Name	Image File	Comment [scan comment here]	Array Data File	Comment[raw data comment]	Protocol REF	Normalization Name	Comment[data smoothness]	Derived Array Data File	Factor Value [EF1](Prognosis)	Term Source REF	Term Accession Number	Factor Value [EF2]	Unit[ConcentrationUnit]	Term Source REF
my source	the guy in the next room	root	hemophilia	NCI META	CL:111111	organism_part	description_text	mycomment	my sample	6	hours	MO	cell	sample comment value	EXTPRTCL10654	the guy in the next room	total RNA	2007-02-21	This did not happen. I was not here.	my extract	not_a_MO_term	my LE1	total_RNA	MO	Cy3	MO	P-XMPL-7	ArrayExpress	my hybridization	hyb conditions were suboptimal	A-TEST-1	My favourite array design	scanning protocol	my scan	imagefile1.TIFF	this was a great picture	Data1.txt		TRANPRTCL10656	my norm	high	NormData1.txt	ill	NCI META	CL:0123345	10	mg_per_mL	MO
my source	the guy in the next room	root	hemophilia	NCI META	CL:111111	organism_part	description_text	mycomment	my sample	6	hours	MO	cell	sample comment value	EXTPRTCL10654	the guy in the next room	total RNA	2007-02-21	This did not happen. I was not here.	my extract	not_a_MO_term	my LE2	total_RNA	MO	Cy5	MO	P-XMPL-7	ArrayExpress	my hybridization	hyb conditions were suboptimal	A-TEST-1	My favourite array design	scanning protocol	my scan	imagefile1.TIFF	this was a great picture	Data2.txt	not as good as the picture	TRANPRTCL10656	my norm	low	NormData2.txt	healthy	NCI META	CL:2347689	0	mg_per_mL	MO
sparse source 1			normal		blah blah ignore me										EXTPRTCL10654		polyA RNA					sparse LE Cy5			Cy5		P-XMPL-11	ArrayExpress	sparse hyb		A-TEST-1			sparse scan1	testing.jpg		Data3.txt		TRANPRTCL10656	norm 3		NormData3.txt	pained expression			10	mM	MO
sparse source 2			normal												EXTPRTCL10654		polyA RNA					sparse LE Cy3			Cy3		P-XMPL-11	ArrayExpress	sparse hyb		A-TEST-1			sparse scan2			Data4.txt		TRANPRTCL10656	norm 3		NormData3.txt	pregnant pause					
sparse source 3			normal												EXTPRTCL10654		polyA RNA					sparse LE biotin			biotin		P-XMPL-11	ArrayExpress	sparse hyb b		A-TEST-1		scanning protocol	sparse scan3	imagefile2.TIFF	a bit blurry			TRANPRTCL10656	norm 4		NormData4.txt	preternatural calm					
