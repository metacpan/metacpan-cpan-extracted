use strict;
use warnings;
use Test::More tests => 27;
use Test::Exception;

BEGIN { 
	use_ok('Bio::Draw::FeatureStack'); 
	use_ok('Bio::DB::SeqFeature::Store'); 
	use_ok('Bio::Graphics::Glyph::decorated_gene'); 
	use_ok('Bio::Graphics::Glyph::decorated_transcript'); 
	use_ok('Bio::Graphics'); 
	use_ok('File::Basename'); 
};

my $gff = 't/data/gene_models_manuscript.gff3';

lives_ok { figure1() }  'Generation of manuscript figure 1';
lives_ok { figure2() }  'Generation of manuscript figure 2';
lives_ok { figure3() }  'Generation of manuscript figure 3';

sub figure1
{
	my $output_basename = "t/images/manuscript_figure1";

	my @gene_names = (qw (RFX3 RFX2 RFX1 dRFX ceDAF-19 Cbr-daf-19 cRFX1 RFX4 RFX6 cRFX2 RFX8 ACA1_270030 YLR176C RFX5 RFX7 dRFX1 AMAG_11601));
	#my @gene_names = (qw (dRFX dRFX1 ceDAF-19 YLR176C ACA1_270030 AMAG_10999 AMAG_11601 cRFX1 cRFX2));
	#my @gene_names = (qw (ceDAF-19));
	#my @gene_names = (qw (YLR176C));
	my @features = load_features(\@gene_names);

	my $feature_stack = new Bio::Draw::FeatureStack
	(
		-features => \@features,
		-glyph => 'decorated_gene',
		-flip_minus => 1,
		-ignore_utr => 1,
		-panel_params => {
							-width => 1024,
							-pad_left => 80,
							-pad_right => 20
		},
		-intron_size => 50,
		-verbose => 0,
		-feature_offsets => "DBD",
#		-feature_offsets => {
#			'daf-19' => 800,
#			'Cbr-daf-19' => 570,
#			'RFX1' => 190,
#			'RFX2' => 1060,
#			'RFX3' => 1160,
#			'RFX4' => 1500,
#			'RFX5' => 1450,
#			'RFX6' => 1400,
#			'RFX7' => 1400,
#			'RFX8' => 1750,
#			'dRFX1' => 950,
#			'YLR176C' => 1080,
#			'ACA1_270030' => 1480,
#			'AMAG_10999' => 1200,
#			'AMAG_11601' => 1200,
#			'cRFX1' => 950,
#			'cRFX2' => 640
#		},
		-glyph_params => {
							-bgcolor     => 'lightgrey',
							-fgcolor     => 'black',
							-fontcolor   => 'black',
							-font2color  => 'blue',
							-utr_color   => 'white',
#							-pad_bottom  => 10,
							-height      =>  12,
							-label_position => 'left',
							-label_transcripts => 1,
							-label => \&get_gene_label,
							-description => 0,
							-decoration_position => \&get_decoration_position,
							-decoration_color => \&get_decoration_color,
							-decoration_label => \&get_decoration_label,
							-decoration_label_color => "black",
							-decoration_visible => \&is_decoration_visible,
							-decoration_border => \&get_decoration_border,
							-decoration_level => \&get_decoration_level,
							-decoration_label_position => \&get_decoration_label_position,
							-decoration_height => \&get_decoration_height,
							-box_subparts => 3, # to create image maps for transcript decorations
							-title => '$name', # \&ChenLab::GFC::WebPageWriter::get_decoration_title,
							-link => " " # you could eg. link to Pfam URL here...
						 }
	);

	write_output_files($feature_stack, $output_basename);
}

sub figure2
{
	my $output_basename = "t/images/manuscript_figure2";
	
	my @gene_names = (qw (ceDAF-19 xbx-1 dylt-2 xbx-3 xbx-4 xbx-5 xbx-6 mks-1 ZK328.7 bbs-9 che-11 odr-4 osm-5 nhr-44 nphp-1 nud-1 dyf-2 osm-6 dyf-3 che-2 osm-1 bbs-1 bbs-2 bbs-5 osm-12 bbs-8 tub-1 dyf-5));
	my @features = load_features(\@gene_names);

	my $feature_stack = new Bio::Draw::FeatureStack
	(
		-features => \@features,
		-transcripts_to_skip => [qw(Transcript:F33H1.1b Transcript:F33H1.1c Transcript:F33H1.1d 
									Transcript:M04C9.5a Transcript:R148.1b 
									Transcript:F40F9.1b.1 Transcript:F40F9.1a.2 Transcript:F40F9.1b.2 Transcript:F40F9.1a.3 Transcript:F40F9.1b.3 Transcript:F40F9.1a.4 Transcript:F40F9.1b.4
									Transcript:ZK328.7b
									Transcript:Y102E9.1a.2 Transcript:Y102E9.1a.3 Transcript:Y102E9.1a.4 Transcript:Y102E9.1b Transcript:Y102E9.1c
									Transcript:F53A2.4.2
									Transcript:C04C3.5a Transcript:C04C3.5c
									Transcript:F38G1.1.2
									Transcript:ZK520.3b.1 Transcript:ZK520.3b.2)],
		-alt_feature_type => 'xbox:test',  # specifiy feature types that should be drawn in alternative track alongside gene models; could also be SNPs, indels, etc.
		-flip_minus => 1,
		-ignore_utr => 1,
		-panel_params => {
							-width => 1024,
							-pad_left => 180,
							-pad_right => 20,
							-grid => 1							
		},
		-span => 500,  # clips 3' end of gene models
		-verbose => 0,
		-feature_offsets => 'start_codon',
		-glyph => 'decorated_gene',  
		-glyph_params => {
							-bgcolor     => 'lightgrey',
							-fgcolor     => 'black',
							-fontcolor   => 'black',
							-font2color  => 'blue',
							-utr_color   => 'white',
							-height      =>  10,
							-label_position => 'left',
							-label_transcripts => 1,
							-pad_left => 200,
							-label => sub { my $f = shift; $f->primary_tag eq 'mRNA' ? $f->name : 0 },
							-description => 0 
						 },
		-alt_glyph => 'generic', 
		-alt_glyph_params => {
							-bgcolor     => 'red',
							-fgcolor     => 'black',
							-fontcolor   => 'black',
							-font2color  => 'blue',
							-bump        =>  +1,
							-height      =>  10,
							-label_position => 'left',
							-label => \&get_xbox_label,
							-description => 0
						 }
	);
	
	write_output_files($feature_stack, $output_basename);
}

sub figure3
{
	my $output_basename = "t/images/manuscript_figure3";

	my @gene_names = (qw (PF11_0023 PF10_0392 PFA0055c PFC1090w PFF0050c PFF1535w PFI0085c PF14_0743 PFD1205w PFB0950w PFB0953w));
	my @features = load_features(\@gene_names);

	my $feature_stack = new Bio::Draw::FeatureStack
	(
		-features => \@features,
		-glyph => 'decorated_gene',
		-flip_minus => 1,
		-ignore_utr => 1,
		-panel_params => {
							-width => 1024,
							-pad_left => 80,
							-pad_right => 20,
							-grid => 1
		},
		-verbose => 0,
		-glyph_params => {
							-bgcolor     => 'lightgrey',
							-fgcolor     => 'black',
							-fontcolor   => 'black',
							-font2color  => 'blue',
							-utr_color   => 'white',
#							-pad_bottom  => 5,
							-height      =>  12,
							-label_position => 'left',
							-label_transcripts => 1,
							-label => sub { my ($name) = shift->name =~ /(.*)-1$/; return $name ? "$name " : 0; },
							-description => 1,
							-decoration_visible => \&is_decoration_visible,
							-decoration_color => \&get_decoration_color,
#							-decoration_label => \&get_decoration_label,
							-decoration_label_color => \&get_decoration_label_color
						 }
	);

	write_output_files($feature_stack, $output_basename);
}

#--------------------------
# helper functions
#--------------------------

sub load_features
{
	my $gene_names = shift;
	
	my $store = Bio::DB::SeqFeature::Store->new
	(
	   	-adaptor => 'memory',
		-dsn => $gff 
	);    				

	my @features;
	foreach my $name (@$gene_names)
	{
		my ($f) = $store->features(-name => $name, -aliases => 1, -type => "gene:test");
		if (!defined $f)
		{
			die "could not load feature $name from gff file $gff";
			return ();
		}
		
		push(@features, $f);	
	}

	return @features;
}

sub write_output_files
{
	my $feature_stack = shift;
	my $output_basename = shift;
	
	my ($svg_file, $map);	
	
	# SVG output
	{
		(my $svg, $map) = $feature_stack->svg(-image_map => 1);

		ok ($svg, "SVG $output_basename" );
		ok ($map, "image map $output_basename");
		
		$svg_file = $output_basename.".svg";
		system("rm $svg_file") if (-e $svg_file);
		open(IMG,">$svg_file") or die "could not write to file $svg_file";
		print IMG $svg;
		close(IMG);		

		ok (-e $svg_file, "$svg_file" );
	}

	# PNG output
	{
		my $png = $feature_stack->png;
		ok ($png, "PNG $output_basename" );
		
		my $png_file = $output_basename.".png";
		system("rm $png_file") if (-e $png_file);
		open(IMG,">$png_file") or die "could not write to file $png_file";
		print IMG $png;
		close(IMG);		

		ok (-e $png_file, "$png_file" );
	}

	# HTML including image map
	{
		my $img_file_base = basename($svg_file);
		my $html_file =  $output_basename.".html";

		system("rm $html_file") if (-e $html_file);
		open(HTML, ">$html_file") or Bio::Root::Exception("could not write to file $html_file");
		print HTML "<html>\n<body>\n";
		print HTML "<img src=\"$img_file_base\" usemap=\"#map\" />\n";
		print HTML "$map";
		print HTML "</body>\n</html>\n";
		close(HTML);
	
		ok (-e $html_file, "$html_file" );		
	}			
}

#--------------------------
# glyph callback functions
#--------------------------

sub is_decoration_visible
{
	my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;	

	my $h = $glyph->active_decoration;
	my ($type, $name, $start, $end, $score) = ($h->type, $h->name, $h->start, $h->end, $h->score);

	return 0 if ("$name" eq "RFX_DNA_binding");  # do not show Pfam prediction for the DBD domain, because we annotated it using our own alignment
	return 0 if ("$type" eq "PfamA25" and $score > 1e-10); # do not show low-quality Pfam predictions
#	return 0 if ("$name" eq "RFX1_trans_act");
	
	return 1;
}

sub get_gene_label
{
	my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;	

	if ($feature->primary_tag eq 'mRNA')
	{
		my $label = $feature->name;
		$label =~ s/-1$//;
		return $label; 
	}
	return $feature->name if ($feature->name and $feature->name eq 'ceDAF-19');
	return 0;
}

sub get_xbox_label
{
	my $feature = shift;
	my ($desc) = $feature->get_tag_values("Note");
	my ($seq,$len,$score) = $desc =~ /(.*)-Length:(.*)-Score:(.*)/; 
	my ($dist) = $feature->get_tag_values('start_dist');  # dynamically computed by FeatureStack; no need to set in GFF file
	return $seq."(".$dist."bp, ".$score.")";
}

sub get_decoration_level
{
	my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;	
	my $h = $glyph->active_decoration;
	my ($type, $name) = ($h->type, $h->name);

	return "mRNA" if ("$type:$name" eq "hmmer3:Pox_D5");
#	return "mRNA" if ("$type:$name" eq "hmmer3:BCD-domain");
	return "CDS";
}

sub get_decoration_color
{
	my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;	
	my $h = $glyph->active_decoration;
	my ($type, $name) = ($h->type, $h->name);

	my %decoration_colors =
	(
		'SignalP4:SP' => 'yellow',
		'exportpred:VTS' => 'darkred',
		'TMHMM:TM' => 'black',
		'SEG:LCR' => 'white',
		'hmmer3:DBD' => 'black',
		'hmmer3:A-domain' => 'red',
		'hmmer3:B-domain' => 'yellow',
		'hmmer3:C-domain' => 'blue',
		'hmmer3:D-domain' => 'lawngreen',
		'hmmer3:BCD-domain' => 'darkgray',
		'hmmer3:RFX1_trans_act' => 'darkslateblue',
		'hmmer3:Pox_D5' => 'darkgreen'
	);

	return $decoration_colors{"$type:$name"} 
		if (exists $decoration_colors{"$type:$name"});

	return $decoration_colors{$name} 
		if (exists $decoration_colors{$name});

	return $decoration_colors{$type} 
		if (exists $decoration_colors{$type});		
}

sub get_decoration_border
{
	my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;	

	my $h = $glyph->active_decoration;
	my ($type, $name) = ($h->type, $h->name);

#	if ("$type:$name" eq "hmmer3:BCD-domain")
#	{
#		return "dashed";
#	}
	
	return "none";
}

sub get_decoration_height
{
	my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;	

	my $h = $glyph->active_decoration;
	my ($type, $name) = ($h->type, $h->name);

	return 5 if ("$type:$name" eq "hmmer3:Pox_D5");
	return 6 if ("$type:$name" =~ /hmmer3:[ABCD]-domain/);
}

sub get_decoration_position
{
	my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;	

	my $h = $glyph->active_decoration;
	my ($type, $name) = ($h->type, $h->name);

	if ("$type:$name" eq "hmmer3:Pox_D5")
	{
		return 14;
	}

	return "inside";
}

sub get_decoration_label_position
{
	my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;	

	my $h = $glyph->active_decoration;
	my ($type, $name) = ($h->type, $h->name);

#	return "above" if ("$type:$name" eq "hmmer3:BCD-domain");
	return "inside" if ($name eq "LCR");
	return "below";
}

sub get_decoration_label_color
{
	my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;	

	my $h = $glyph->active_decoration;
	my ($type, $name) = ($h->type, $h->name);

	return "white" if ("$type:$name" eq "TMHMM:TM");
	return "white" if ("$type:$name" eq "exportpred:VTS");
}

sub get_decoration_label
{
	my ($feature, $option_name, $part_no, $total_parts, $glyph) = @_;	

	my $h = $glyph->active_decoration;
	my ($type, $name) = ($h->type, $h->name);

	return 0 if ("$type:$name" eq "hmmer3:DBD"); # do not label this decoration
	return "A" if ("$type:$name" eq "hmmer3:A-domain");
	return "B" if ("$type:$name" eq "hmmer3:B-domain");
	return "C" if ("$type:$name" eq "hmmer3:C-domain");
	return "D" if ("$type:$name" eq "hmmer3:D-domain");
	return 0 if ("$type:$name" eq "hmmer3:BCD-domain");
	return 0 if ("$type:$name" eq "hmmer3:RFX1_trans_act");
	return 0 if ("$type:$name" eq "hmmer3:Pox_D5");
	
}
