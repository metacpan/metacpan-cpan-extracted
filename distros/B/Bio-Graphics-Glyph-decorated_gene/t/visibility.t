# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Bio-Graphics-DecoratedGene.t'

#Test for visible decorations
#########################

use strict;
use warnings;

use Test::More tests => 26;
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
isa_ok( $store, 'Bio::DB::SeqFeature::Store' );

can_ok('Bio::DB::SeqFeature::Store', qw(features));

my ($gene_minus) =  $store->features(-name => 'PFA0680c-minus');
is ($gene_minus->name, 'PFA0680c-minus' , "get features from store");  	

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
    skip "GD::SVG not installed", 6 if $@;

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

sub add_tracks{
my $panel = shift;

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
	-description => sub { "visible"},
	-glyph => 'decorated_gene',
	-decoration_visible => 1,	
	-height => 12,
	-decoration_color		=> 'yellow'
);
ok(1,'track1 added');

$panel->add_track
(
	$gene_minus,
	-description => sub { "not visible"},
	-glyph => 'decorated_gene',
	-decoration_visible => 0,	
	-height => 12,
	-decoration_color		=> 'yellow'
);
ok(1,'track2 added');

$panel->add_track
(
	$gene_minus,
	-description => sub {"visible as callback, TM:not visible"},
	-glyph => 'decorated_gene',
	-decoration_visible => sub { 
			my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;	
			return '0' if ($glyph->active_decoration->name eq "TM");
			return '1' if ($glyph->active_decoration->type eq "SignalP4");
			return '1';
	},	
	-height => 12,
	-decoration_color		=> 'yellow'
);
ok(1,'track3 added');

};
# write image
my $png = $panel->png;
is($png,$panel->png,'png created');
my $imgfile = "t/data/visibility.png";
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
	my $svgfile = "t/data/visibility.svg";
	system("rm $svgfile") if (-e $svgfile);
	open(IMG,">$svgfile") or die "could not write to file $svgfile";
	print IMG $svg;
	close(IMG);
	ok(-e $svgfile, 'svgfile created');
	$filesize = -s $svgfile;
	isnt($filesize,0, 'check nonzero filesize');
}