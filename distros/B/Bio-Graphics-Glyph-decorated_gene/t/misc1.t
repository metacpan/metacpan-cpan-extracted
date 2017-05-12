# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Bio-Graphics-DecoratedGene.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 8;
BEGIN { 
	use_ok('Bio::Graphics::Glyph::decorated_transcript'); 
	use_ok('Bio::Graphics'); 
	use_ok('Bio::Graphics::Panel'); 
	use_ok('Bio::DB::SeqFeature::Store'); 
	use_ok('Bio::Graphics::Feature'); 
};

#########################

# load features
my $store = Bio::DB::SeqFeature::Store->new
(
	-adaptor => 'memory', 
	-dsn => 't/data/decorated_transcript_t1.gff'
);
my ($gene_minus) =  $store->features(-name => 'PFA0680c-minus');  	
my ($gene_plus) =  $store->features(-name => 'PFA0680c-plus');  	

#print Dumper($rna1);

# draw panel
my $panel = Bio::Graphics::Panel->new(

	-length    => $gene_minus->end-$gene_minus->start+202,
	-offset     => $gene_minus->start-100,
	-key_style => 'between',
	-width     => 1024,
	-pad_left  => 100
);
  isa_ok($panel,      "Bio::Graphics::Panel",  "Panel");
# ruler
$panel->add_track
(
	Bio::Graphics::Feature->new(-start => $gene_minus->start-100, -end => $gene_minus->end),
	-glyph  => 'arrow',
	-bump   => 0,
	-double => 1,
	-tick   => 2
);


$panel->add_track
(
	[$gene_minus, $gene_plus],
	-glyph => 'decorated_gene',
	-label_transcripts => 1,
	-description => 1,
	-label => 1,
	-height => 12,
	-link => '$name',
	-decoration_image_map => 1,
	-box_subparts => 2,
	-decoration_visible => sub { 
			my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;	
			return 0 if ($glyph->active_decoration->name eq "TM" 
			             and $glyph->active_decoration->score < 8);
		},	
	-decoration_color => sub { 
			my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;	
			return 'green' if ($glyph->active_decoration->name eq "TM");
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

# png output
my $png = $panel->png;

my $imgfile = "t/data/misc1.png";
system("rm $imgfile") if (-e $imgfile);
open(IMG,">$imgfile") or die "could not write to file $imgfile";
print IMG $png;
close(IMG);
ok(-e $imgfile, 'imgfile created');
my $filesize = -s $imgfile;
isnt($filesize,0, 'check nonzero filesize');

