# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Bio-Graphics-DecoratedGene.t'

#Testing alignment of description and other
#########################

use strict;
use warnings;

use Test::More tests => 31;
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
	-dsn => 't/data/misc2.gff'
);
isa_ok( $store, 'Bio::DB::SeqFeature::Store' );

can_ok('Bio::DB::SeqFeature::Store', qw(features));
my ($gene_minus) =  $store->features(-name => 'PFA0680c-minus');
is ($gene_minus->name, 'PFA0680c-minus' , "get features from store");  	
my ($gene_plus) =  $store->features(-name => 'PFA0680c-plus');  	
is ($gene_plus->name, 'PFA0680c-plus' , "get features from store");

# draw panel
can_ok('Bio::Graphics::Panel', qw(offset key_style width pad_left add_track));
my @args = (	-length    => $gene_minus->end-$gene_minus->start+102,
	-offset     => $gene_minus->start-100,
	-key_style => 'between',
	-width     => 1024,
	-pad_left  => 100);

my $panel = new_ok('Bio::Graphics::Panel' => \@args);
can_ok($panel, qw(add_track));
add_tracks($panel);

my $panel2;
SKIP: {
    eval{ require GD::SVG };
    skip "GD::SVG not installed", 8 if $@;

	my @args2 = (	-length    => $gene_minus->end-$gene_minus->start+102,
		-offset     => $gene_minus->start-100,
		-key_style => 'between',
		-width     => 1024,
		-pad_left  => 100,
		-image_class=>'GD::SVG');
	$panel2 = new_ok('Bio::Graphics::Panel' => \@args2);
	
	can_ok($panel2, qw(add_track));
	add_tracks($panel2);
}

sub add_tracks
{
	my $panel = shift;
	
	# ruler
	can_ok($panel, qw(add_track));
	$panel->add_track(
		Bio::Graphics::Feature->new(-start => $gene_minus->start-100, -end => $gene_minus->end),
		-glyph  => 'arrow',
		-bump   => 0,
		-double => 1,
		-tick   => 2
	);
	ok(1, 'ruler made');
	
	$panel->add_track
	(
		$gene_minus,
		-glyph => 'decorated_gene',
		-label_transcripts => 1,
		-description => 1,
		-label => 1,
		-height => 12,
		-decoration_image_map => 1,
		-box_subparts => 2,
		-decoration_visible => 1,	
		-decoration_color => sub { 
				my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;	
				return 'black' if ($glyph->active_decoration->name eq "TM");
				return 'yellow' if ($glyph->active_decoration->type eq "SignalP4")
			},
		-additional_decorations => sub { 
				my $feature = shift;
				my ($id) = $feature->get_tag_values('load_id');			
				my %add_h = ( "rna_PFA0680c-1" => "test:callback:100:130:0" );
				return $add_h{$id};
		},
			-decoration_position  => sub {
				my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;
				return '12' if ($glyph->active_decoration->name eq "VTS"); 
				return '-10'if ($glyph->active_decoration->name eq "TM"); 
				return '1';
		}	
	);
	ok(1, 'track1 added');
	
	my ($gene2) =  $store->features(-name => 'test1'); 	
	
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
			-decoration_border_color => "blue",
			-decoration_height  => sub {
				my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;
				return '24' if ($glyph->active_decoration->name eq "very interesting region"); 
				return '10';}
	
		);
	ok(1, 'track2 added');
	
	$panel->add_track
		(
			$gene2,
			-glyph => 'decorated_gene',
			-description => sub { "Gene label and description do not bump with extended decoration boundaries" },
			-label => 1,
			-label_position => 'below',
			-height => 12,
			-decoration_visible => sub {
				my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;
				return '0' if ($glyph->active_decoration->name eq "very interesting region"); 
				return '1';},
			-decoration_border => "dashed",
			-decoration_color => "yellow",
			-decoration_label_position => 'below',
			-decoration_label => 1,
			-decoration_level        => 'mRNA',
			-decoration_border_color => "blue",
			-decoration_height  => 12,
			-decoration_position  => sub {
				my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;
				return '12' if ($glyph->active_decoration->name eq "SP"); 
				return '12';}
		);
	ok(1, 'track3 added');
	
	$panel->add_track
		(
			$gene2,
			-glyph => 'decorated_gene',
			-description => sub { "Gene label and description do not bump with extended decoration boundaries" },
			-label => 1,
			-label_position => 'below',
			-height => 12,
			-decoration_visible => sub {
				my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;
				return '0' if ($glyph->active_decoration->name eq "very interesting region" || $glyph->active_decoration->name eq "SP"); 
				return '1';},
			-decoration_border => "dashed",
			-decoration_color => "yellow",
			-decoration_label_position => 'below',
			-decoration_label => 1,
			-decoration_border_color => "blue",
			-decoration_height  => 12,
			-additional_decorations =>  'TMHMM:TM:25:45:24',
			-decoration_level        => 'mRNA',
			-decoration_position  => sub {
				my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;
				return '12' if ($glyph->active_decoration->name eq "TM"); 
				return '1';},
	
	);
	ok(1, 'track4 added');
}

# write image
my $png = $panel->png;
is($png,$panel->png,'png created');
my $imgfile = "t/data/misc2.png";
system("rm $imgfile") if (-e $imgfile);
open(IMG,">$imgfile") or die "could not write to file $imgfile";
print IMG $png;
close(IMG);
ok(-e $imgfile, 'imgfile created');
my $filesize = -s $imgfile;
isnt($filesize,0, 'check nonzero filesize');

SKIP: {
    eval{ require GD::SVG };
    skip "GD::SVG not installed", 2 if $@;

	my $svg = $panel2->svg;
	#is($svg,$panel2->svg,'svg created');
	my $svgfile = "t/data/misc2.svg";
	system("rm $svgfile") if (-e $svgfile);
	open(IMG,">$svgfile") or die "could not write to file $svgfile";
	print IMG $svg;
	close(IMG);
	ok(-e $svgfile, 'svgfile created');
	$filesize = -s $svgfile;
	isnt($filesize,0, 'check nonzero filesize');
}
