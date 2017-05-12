#!/usr/bin/perl

use strict;
use warnings;

use Bio::Graphics;
use Bio::Graphics::Panel;
use Bio::Graphics::Glyph::decorated_transcript;
use Bio::DB::SeqFeature::Store;
use Bio::SeqFeature::Generic;
use Data::Dumper;

# load features
my $store = Bio::DB::SeqFeature::Store->new
(
	-adaptor => 'memory', 
	-dsn => 'data/decorated_transcript_t1.gff'
);
my ($gene1) =  $store->features(-name => 'PFA0680c');  	

#print Dumper($rna1);

# draw panel
my $panel = Bio::Graphics::Panel->new
(
	-length    => $gene1->end-$gene1->start+102,
	-offset     => $gene1->start-100,
	-key_style => 'between',
	-width     => 1024,
	-pad_left  => 100
);

# ruler
$panel->add_track
(
	Bio::SeqFeature::Generic->new(-start => $gene1->start-100, -end => $gene1->end),
	-glyph  => 'arrow',
	-bump   => 0,
	-double => 1,
	-tick   => 2
);

$panel->add_track
(
	$gene1,
	-glyph => 'decorated_gene',
	-label_transcripts => 1,
	-description => 'Signal peptide spans intron, isoform1 has extra callback decoration, isoform2 lacks TM domain',
	-label => 1,
	-height => 12,
	-decoration_visible => sub { 
			my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;	
			return 0 if ($glyph->active_decoration->name eq "TM" 
			             and $glyph->active_decoration->score < 8);
		},	
	-decoration_color => sub { 
			my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;	
			return 'black' if ($glyph->active_decoration->name eq "TM");
			return 'red' if ($glyph->active_decoration->name eq "VTS");
		},	
	-decoration_label_color => sub { 
			my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;	
			return 'white' if ($glyph->active_decoration->name eq "VTS");
		},	
	-additional_decorations => sub { 
			my $feature = shift;
			my ($id) = $feature->get_tag_values('load_id');			
			my %add_h = ( "rna_PFA0680c-1" => "test:callback:100:130:0" );
			return $add_h{$id};
		}	
);

# decoration outside transcript boundaries, transparent background 
my ($gene2) =  $store->features(-name => 'test1');
{  	
	$panel->add_track
	(
		$gene2,
		-glyph => 'decorated_gene',
		-description => sub { "Gene label and description do not bump with extended decoration boundaries" },
		-label => 1,
		-label_position => 'top',
		-height => 12,
		-decoration_visible => 1,
		-decoration_border => "dashed",
		-decoration_color => "transparent",
		-decoration_label_position => "above",
		-decoration_label => 1,
		-decoration_height => 17,
		-decoration_border_color => "blue"
	);
}

# use of decorated_transcript glyph directly, with mRNA feature
{
	my ($rna2) = $gene2->get_SeqFeatures('mRNA'); 
	$panel->add_track
	(
		$rna2,
		-glyph => 'decorated_transcript',
		-description => sub { "This text should not bump with decoration label" },
		-label => 1,
		-label_position => 'top',
		-height => 16,
		-decoration_visible => 1,
		-decoration_border => "solid",
		-decoration_color => "yellow",
		-decoration_label_position => sub {
				return "below" if ($_[4]->active_decoration->type eq "method1");
				return "inside";
			},
		-decoration_label =>  sub {
				return "another interesting region" 
					if ($_[4]->active_decoration->type eq "method1");
				return 1;  # return 1 to draw default label
			},
		-decoration_height => 20,
		-decoration_border_color => "red"
	);	
}

# gene with UTR
{
	my ($gene) = $store->features(-name => 'PVX_000640');  	
	$panel->add_track
	(
		$gene,
		-glyph => 'decorated_gene',
		-description => 1,
		-label => 1,
		-height => 12,
		-decoration_color => "yellow",
		-label_position => 'top',
		-decoration_visible => 1,
	);	
}

# write image
my $imgfile = "data/decorated_transcript_t1.png";
open(IMG,">$imgfile") or die "could not write to file $imgfile";
print IMG $panel->png;
close(IMG);

print "Image written to $imgfile\n";
