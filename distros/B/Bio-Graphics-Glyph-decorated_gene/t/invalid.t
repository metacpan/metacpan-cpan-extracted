# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Bio-Graphics-DecoratedGene.t'

#Test case for invalid decorations in gff file
#########################

use strict;
use warnings;

use Test::More tests => 21;
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
	-dsn => 't/data/invalid.gff'
);
isa_ok( $store, 'Bio::DB::SeqFeature::Store' );

can_ok('Bio::DB::SeqFeature::Store', qw(features));

my ($gene_plus) =  $store->features(-name => 'PFA0680c-plus');
is ($gene_plus->name, 'PFA0680c-plus' , "get features from store");  	
my ($test) =  $store->features(-name => 'test1');
my ($test2) =  $store->features(-name => 'test2');
# draw panel
can_ok('Bio::Graphics::Panel', qw(offset key_style width pad_left add_track));
my @args = (	-length    => $gene_plus->end-$gene_plus->start+102,
	-offset     => $gene_plus->start-100,
	-key_style => 'between',
	-width     => 1024,
	-pad_left  => 100);
my $panel = new_ok('Bio::Graphics::Panel' => \@args);

# ruler
can_ok($panel, qw(add_track));
$panel->add_track(
	Bio::Graphics::Feature->new(-start => $gene_plus->start-100, -end => $gene_plus->end),
	-glyph  => 'arrow',
	-bump   => 0,
	-double => 1,
	-tick   => 2
);
ok(1, 'ruler made');

{
	my $warn_ok = 0;
	local $SIG{__WARN__} = sub { $warn_ok = 1 if ($_[0] =~ /WARNING: could not map/); };
	$panel->add_track
	(
		$test,
		-label => 1,
		-glyph => 'decorated_gene',
		-decoration_visible => 1,	
		-height => 12,
		-decoration_color		=> 'white',
		-decoration_label_position => 'inside',
		-decoration_label_color => 'black',
		-description => 1
	);
	ok($warn_ok, 'expected warning');
	ok(1, 'track1 added');	
}

$panel->add_track
(
	$gene_plus,
	-label => 1,
	-glyph => 'decorated_gene',
	-decoration_visible => 1,	
	-height => 12,
	-decoration_color		=> 'white',
	-decoration_label_position => 'inside',
	-decoration_label_color => 'black',
	-description => 1
);
ok(1, 'track2 added');

{
	my $warn_ok = 0;
	local $SIG{__WARN__} = sub { $warn_ok = 1 if ($_[0] =~ /WARNING: invalid decoration data/); };
	$panel->add_track
	(
		$test2,
		-label => 1,
		-glyph => 'decorated_gene',
		-decoration_visible => 1,	
		-height => 12,
		-decoration_color		=> 'white',
		-decoration_label_position => 'inside',
		-decoration_label_color => 'black',
		-description => 1
	);
	ok($warn_ok, 'expected warning');
	ok(1, 'track3 added');
}

# write image
my $png;
{
	my $warn_ok = 0;
	local $SIG{__WARN__} = sub { $warn_ok = 1 if ($_[0] =~ /WARNING: could not map/); };
	
	$png = $panel->png;
	
	ok($warn_ok, 'expected warning');
	is($png,$panel->png,'png created');
}
my $imgfile = "t/data/invalid.png";
unlink($imgfile);
open(IMG,">$imgfile") or die "could not write to file $imgfile";
print IMG $png;
close(IMG);
ok(-e $imgfile, 'imgfile created');
my $filesize = -s $imgfile;
isnt($filesize,0, 'check nonzero filesize');

