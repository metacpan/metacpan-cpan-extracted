#!/usr/bin/perl -w

use lib './lib','../lib','./blib/lib','../blib/lib';
use strict;

use Bio::Graphics::Panel;
use Bio::Graphics::Feature;

my $ftr = 'Bio::Graphics::Feature';

my $segment = $ftr->new(-start=>1,-end=>1000,-name=>'ZK154',-type=>'clone');
my $zk154_1 = $ftr->new(-start=>-50,-end=>800,-name=>'ZK154.1',-type=>'gene');
my $zk154_2 = $ftr->new(-start=>380,-end=>500,-name=>'ZK154.2',-type=>'gene');

my $zed_27 = $ftr->new(-segments=>[[400,500],[550,600],[800,950]],
		   -name=>'zed-27',
		   -subtype=>'exon',-type=>'transcript');
my $abc3 = $ftr->new(-segments=>[[100,200],[350,400],[500,550]],
		    -name=>'abc3',
		   -strand => -1,
		    -subtype=>'exon',-type=>'transcript');
my $xyz4 = $ftr->new(-segments=>[[40,80],[100,120],[200,280],[300,320]],
		     -name=>'xyz4',
		     -subtype=>'predicted',-type=>'alignment');

my $m3 = $ftr->new(-segments=>[[20,40],[30,60],[90,270],[290,300]],
		   -name=>'M3',
		   -subtype=>'predicted',-type=>'alignment');

my $fred_12 = $ftr->new(-segments=>[$xyz4,$zed_27],
			-type => 'group',
			-name =>'fred-12');

my $confirmed_exon1 = $ftr->new(-start=>1,-stop=>20,
				-type=>'exon',-source=>'confirmed');
my $predicted_exon1 = $ftr->new(-start=>30,-stop=>50,
				-type=>'exon',-source=>'predicted');
my $predicted_exon2 = $ftr->new(-start=>60,-stop=>100,
				-type=>'exon',-source=>'predicted');

my $confirmed_exon3 = $ftr->new(-start=>150,-stop=>190,
				-type=>'exon',-source=>'confirmed');
my $partial_gene = $ftr->new(-segments=>[$confirmed_exon1,$predicted_exon1,$predicted_exon2,$confirmed_exon3],
			     -name => 'partial_gene');

my $panel = Bio::Graphics::Panel->new(
				      -segment => $segment,
#				      -offset => 300,
#				      -length  => 1000,
				      -spacing => 15,
				      -width   => 600,
				      -pad_top  => 20,
				      -pad_bottom  => 20,
				      -pad_left => 20,
				      -pad_right=> 20,
				      -key_style => 'between',
				     );
$panel->add_track(
		  [$abc3,$zed_27,$partial_gene],
		  -bgcolor   => sub { shift->source_tag eq 'predicted' ? 'green' : 'blue'},
 		  -glyph   => sub { my $feature = shift; 
 				  return $feature->source_tag eq 'predicted'
 				    ? 'ellipse' : 'transcript'},
		  -label => 1,
		  -bump => 1,
		  -key => 'portents',
		 );
#print $panel->png;

my $gd    = $panel->gd;
my @boxes = $panel->boxes;
my $red   = $panel->translate_color('red');
for my $box (@boxes) {
  my ($feature,@points) = @$box;
#  $gd->rectangle(@points,$red);
}
#$gd->filledRectangle(0,0,20,200,1);
#$gd->filledRectangle(600-20,0,600,200,1);
print $gd->png;

