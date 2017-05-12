#!/usr/bin/perl
package Bio::NEXUS::Tools::NexPlotter;
######################################################################
# Derived from nexplot.pl (was plottree.pl prior to 9/15/03; the complete revision 
#   log from plottree.pl is in the initial version of nexplot.pl)
######################################################################
#
# $Author: astoltzfus $
# $Date: 2008/06/16 19:53:41 $
# $Revision: 1.2 $
# $Id: NexPlotter.pm,v 1.2 2008/06/16 19:53:41 astoltzfus Exp $

use strict;

use Pod::Usage;
use Data::Dumper;
use Bio::NEXUS::Tools::GraphicsParams;
use Bio::NEXUS; our $VERSION = $Bio::NEXUS::VERSION;


## Class variables
my $main_dir ='.';

my $runtime_options;
my $nexusG       = new Bio::NEXUS::Tools::GraphicsParams();
my $my_data_obj  = new MyData;
my $nexusObject;
my $DEBUG;
my $ppp_param;

sub new {

my $self     = shift; 
my $inp_data = $_[0];

$inp_data = {@_} if (ref($inp_data) ne 'HASH') ;


my $object_data = {
	'parameters' => {
		'input_file'		=> 'test.nex',
		'output_file'		=> 'test.ps',
		'show_content'			=> 'Tree and Data',
		'character_data_type'		=> 'Protein',
		'species_tree'			=> 'off',
		'show_bootstrap_values'		=>  'on',
		'show_inode_label'		=>  undef,
		'colorintron'			=>  undef,
		'set_type'			=>  undef,
		'kingdom'			=> {
			'vertebrate'	=> undef,
			'invertebrate'	=> undef,
			'plant'		=> undef,
			'fungi'		=> undef,
			'protist'	=> undef
		},
		'right_justify_labels'		=> undef,
		'tree_width'			=> $Bio::NEXUS::Tools::GraphicsParams::DefaultTreeWidth,
		'char_label_block_size'		=> $Bio::NEXUS::Tools::GraphicsParams::DefaultCharLabelBlockWidth ,
		'show_border'			=> undef,
		'vertical_otu_spacing'		=> $Bio::NEXUS::Tools::GraphicsParams::DefaultVerticalOtuSpacing,
		'output_type'			=> 'ps',
		'show_cladogram'		=> undef,
		'cladogrom_mode'		=> "normal",
		'color_sub_tree'		=> [],
		'select_char_range'		=> [],
		'setsbyinode'			=> [],
		'customset'			=> [],
		'highlight_otus'		=> [],
		'highlight_chars'  		=> [],
		'ppp'				=>  undef,
		'reroot_node'			=> [],
		'exclude_sub_tree'		=> [],
		'swap_children'			=> [],
		'select_sub_tree'		=> [],
	},
	'data'    => {
			'nexus_obj'   => undef,
			'my_data'     => undef, 
			'gfx'         => undef,
	}
};

foreach my $field ( keys %{ $object_data->{'parameters'} } ) {
    my @field1 = grep(/^.?$field$/,keys %{$inp_data}) ;
	if ( scalar @field1 > 0 ){
		$object_data->{'parameters'}->{$field} = $inp_data->{$field1[0]};
	} 
}

#print Dumper $object_data;
my @column_nos;
foreach my $columns (@ {$object_data->{'parameters'}->{'select_char_range'} }) {
	push(@column_nos,@{&parse_number($columns)}) if $columns;
} 
$object_data->{'parameters'}->{'select_char_range'} = \@column_nos;

$self = bless ($object_data,$self);
#print Dumper $self;
$runtime_options = $object_data->{'parameters'};
$ppp_param       = $runtime_options->{'ppp'};


##  1. print Header and the top menu for CGI  
#print Dumper $runtime_options;

$nexusObject = &__read_nexus();	# Read in the NEXUS file and extract relevant information.

die "Error in loading the Plot module : $@\n" if ($@);

$my_data_obj->set_title($nexusObject->get_filename);
if ($runtime_options->{'species_tree'} ne 'on') {
	foreach my $block (@{$nexusObject->get_blocks()} ) {
		my $input_block_type = $runtime_options->{'character_data_type'};
		if ($block->get_type =~/characters/i && $block->get_title =~/$input_block_type/i){
			$my_data_obj->set_selected_char_block($block) ;
		}
	}
	$my_data_obj->set_selected_char_block( $nexusObject->get_block("character") ) if not defined $my_data_obj->get_selected_char_block;
	if (defined $my_data_obj->get_selected_char_block) { 
		my @selectchar_params  = @{ $runtime_options->{'select_char_range'} };	
		$nexusObject = $nexusObject->select_chars(\@selectchar_params,$my_data_obj->get_selected_char_block->get_title) if (@selectchar_params);
	}
	if ($nexusObject->get_block("trees")) {
		my $tree = $nexusObject->get_block("trees")->get_tree;
		$my_data_obj->set_selected_tree( $tree );
	}

} else {

	$my_data_obj->set_selected_tree( $nexusObject->get_block );
	my $hist_dup = $nexusObject->get_block('history','duplication_speciation');
	$my_data_obj->set_selected_char_block(undef); 
	$my_data_obj->set_selected_tree( $hist_dup->get_tree('species_tree') ); 
	$my_data_obj->set_gene_tree( $hist_dup->get_tree('gene_tree') ); 
	$my_data_obj->set_species_tree( $hist_dup->get_tree('species_tree') ); 

}

#### 4. Graphics Layout and pupulating my_data object - set all  size of the canvas and the panes based on the
####    CGI options and content of the NEXUS file.

#gdSmallFont->width
$nexusG->set_fontWidth(6);
$nexusG->set_fontHeight(13);
$nexusG->set_verticalOtuSpacing($runtime_options->{'vertical_otu_spacing'});
$nexusG->set_charLabelBlockWidth($runtime_options->{'char_label_block_size'});

my $taxlabels;
if ($my_data_obj->get_selected_tree) {
	$taxlabels = $my_data_obj->get_selected_tree->get_node_names();
} else {
	$taxlabels = $nexusObject->get_block('taxa')->get_taxlabels();
}
$nexusG->set_maxTaxLabelwidth($taxlabels);
$nexusG->set_paneHeight(scalar @$taxlabels);

if ($my_data_obj->get_selected_char_block && ( $runtime_options->{'show_content'} ne "Tree only")) {
	$nexusG->set_histogramHeight if $my_data_obj->get_char_block_wts;
	my $block = $my_data_obj->get_selected_char_block;
	$nexusG->set_charactersXwidth($block);
	my @col_labels = $my_data_obj->get_char_column_labels;
	$nexusG->set_longestCharLabelLength(@col_labels) if @col_labels;
}

#print "<PRE>";
#print "</PRE>";

$nexusG->set_lowerXbound;
$nexusG->set_lowerYbound;

if ($runtime_options->{'show_content'} ne 'Data only' && defined $my_data_obj->get_selected_tree) {
	$nexusG->set_TreeWidth($runtime_options->{'tree_width'}*72);
	&__set_node_coords($my_data_obj->get_selected_tree);
}
$nexusG->set_upperXbound;
$nexusG->set_upperYbound;
$nexusG->set_xsize;
$nexusG->set_ysize;

#print "<PRE>";
#print Dumper $nexusG;
#print "</PRE>";

### 5. Open the image handlers for drawing

## 5.a load the specific module 
if ($runtime_options->{'output_type'} eq "ps") {
    eval 'use PostScript::Simple';
} elsif ($runtime_options->{'output_type'} eq "pdf") {
	eval 'use PDF::API2::Lite';
} else {
	eval 'use GD::Simple';
}


## 5.b Initialize graphics module
if ($runtime_options->{'output_type'} eq "ps" ) {
	my $p = new PostScript::Simple(
		xsize		=> $nexusG->get_xsize,
		ysize		=> $nexusG->get_ysize,
		colour		=> 1,
		eps		=> 0,
		units		=> "pt",
		coordorigin 	=> "LeftTop",
		direction 	=> "RightDown");
	$p->newpage;
	$p->setfont("Courier",10);
	$my_data_obj->set_image_handler($p);
}
elsif ( $runtime_options->{'output_type'} eq "pdf" ) {
	my $p    = new PDF::API2::Lite;
	my $font = $p->corefont("Courier");
	$p->page($nexusG->get_xsize,$nexusG->get_ysize);
	$my_data_obj->set_image_handler($p);
	$my_data_obj->set_font($font);
}
else {
	my $im = new GD::Simple($nexusG->get_xsize,$nexusG->get_ysize);
# make the background transparent and interlaced
#$im->transparent($white);
	$im->interlaced('true');
	$my_data_obj->set_image_handler($im);
	$my_data_obj->allocate_colors;
	$my_data_obj->set_font(gdSmallFont());
}


##############################

# Assgn state to nodes by taxonomy
# PRINT TREE AND OTHER ELEMENTS IF PRESENT

my $tree = $my_data_obj->get_selected_tree;
# used taxlabels before from taxa block, now getting them from tree
$taxlabels = ($tree) ? $tree->get_node_names() : $nexusObject->get_block('taxa')->get_taxlabels();

##### 7. Coloring data and tree based on the NCBI Taxonomy option

if ($runtime_options->{'set_type'} eq 'Taxonomy') {
	&__assign_ncbi_taxonomy($my_data_obj,$taxlabels);
}


##### 8.  Custom set processing for taxa label colors #######
if ($runtime_options->{'set_type'} eq 'Custom') {
	my $taxlabels = $nexusObject->get_block('taxa')->get_taxlabels();
	for my $taxlabel (@$taxlabels) {
		$my_data_obj->set_node_color($taxlabel,'black');
	}
	if ($nexusObject->get_block('sets')) {
# redundant to subsequent code
# my $taxSets = $nexusObject->get_block('sets')->get_taxsets();

		my $block = $nexusObject->get_block('sets');
		warn("Grabbing sets block from NEXUS file...\n") if $DEBUG;
		my $taxSets = $block->get_taxsets();

		my %setsColors;
		my $count = 1;
		my @customset_params = @{ $runtime_options->{'customset'} };
		foreach my $key (sort keys %{$taxSets}) {
			$setsColors{$key} = $customset_params[$count-1];
			$count++;
		}
		for my $taxSetName (sort keys %{$taxSets}) {
			for my $taxon (@{$taxSets->{$taxSetName}}) {
				my $col_name = $setsColors{$taxSetName};
				$my_data_obj->set_node_color($taxon,$col_name) if $col_name =~/\S+/;
			}
		}
	}
}
##### 9. propagating coloring options on the tree 
	my @colornode_params             = @{ $runtime_options->{'color_sub_tree'} };    		# Color a node and its children
if (defined $tree) {
	my $root = $tree->get_rootnode(); 
	my $node = $tree->find($colornode_params[$#colornode_params]) if ($colornode_params[0] ne '');

	&AssignStateToNode( $my_data_obj->get_nodes_hash,$root,'black');

	my @highlight_params = @{ $runtime_options->{'highlight_otus'} };
	foreach my $highlight_param(@highlight_params) {
		my @nodes_list;
		&AssignStateToSuperNode($my_data_obj,$root,$highlight_param,\@nodes_list,'gold') if ($highlight_param);
	}
	&AssignStateToSubNode($my_data_obj,$node,'highlighter') if ($colornode_params[0] ne '' && $node);	
}


##### 10. Drawing the tree and character matrix data.

if (($runtime_options->{'show_content'} eq 'Data only') || (not defined $tree))  {
	&__print_matrix($my_data_obj,$nexusG->get_lowerXbound, $nexusG->get_lowerYbound,$taxlabels,1);
} else {
	&__print_tree($my_data_obj,$tree->get_rootnode, $nexusG->get_lowerXbound, $nexusG->get_lowerYbound) if defined $tree;
	&__print_matrix($my_data_obj,$nexusG->get_lowerXbound, $nexusG->get_lowerYbound,$taxlabels,0) if ($runtime_options->{'show_content'} eq 'Tree and Data');
	if (defined $nexusObject->get_block("history",'intron') && $ppp_param) {
		my $otus = $nexusObject->get_block("history",'intron')->get_otuset->get_otus;
		my $otu_seq_hash;
		%{$otu_seq_hash} = map {$_->get_name  => $_->get_seq} @{$otus};
		&__print_piechart($my_data_obj,$tree->get_rootnode, $otu_seq_hash);
	}
	&__print_inode_names($my_data_obj,$tree->get_nodes) if ($runtime_options->{'show_inode_label'} eq 'on') ;
	&__print_boot_strap($my_data_obj,$tree->get_nodes) if ($runtime_options->{'show_bootstrap_values'} eq 'on') ;
}
	if ($my_data_obj->get_selected_char_block && $runtime_options->{'show_content'} ne 'Tree only') {		# Character labels, weights
		my $block = $my_data_obj->get_selected_char_block;
		 if ($my_data_obj->get_char_column_labels) {
			 &__print_char_labels($my_data_obj,$block);
			 &__highlight_char($my_data_obj,$block);	
		}
		&__plot_wts($my_data_obj,$my_data_obj->get_char_block_wts) if ( $my_data_obj->get_char_block_wts ) ;
	}

&__plot_scale_border_title($my_data_obj);
#&__save_session($session);

#print "<pre>",Dumper($nexusObject),"</pre>";
# 11. Convert the image handler output to PNG, PS and PDF format based on the output option.  

if ($runtime_options->{'output_type'} eq "ps") {
	$my_data_obj->get_image_handler->output($runtime_options->{'output_file'})
}
elsif ($runtime_options->{'output_type'} eq "pdf") {
	$my_data_obj->get_image_handler->saveas($runtime_options->{'output_file'});
}
else {
	open(PNG,">$runtime_options->{'output_file'}") || die "cannot open file\n";   
	binmode PNG;
	print PNG $my_data_obj->get_image_handler->png() || die "DIED";
	close PNG;
}
$self->set_data($nexusObject,$my_data_obj,$nexusG);
return $self;
};

#################################################################### SUBROUTINES

=head2 get_data

 Title   : get_data
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub get_data {
	my $self = shift;
	return ($self->{'data'}->{'nexus_obj'},$self->{'data'}->{'my_data'},$self->{'data'}->{'gfx'} ) ; 
}

=head2 set_data

 Title   : set_data
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub set_data {
	my $self = shift;
	my ($nexus_obj,$my_data,$gfx) 	= @_;
	$self->{'data'}->{'nexus_obj'} 	= $nexus_obj; 
	$self->{'data'}->{'my_data'} 	= $my_data; 
	$self->{'data'}->{'gfx'} 	= $gfx; 
}

=head2 rgb2hex

 Title   : rgb2hex
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub rgb2hex {
	my $rgb_hash = shift;
	return "#". join "", map {sprintf "%2.2X",$_} @{$rgb_hash};
}

sub __draw_piechart {
	my ($my_data,$x, $y, $radius, $prob) = @_;
	my $im_h = $my_data->get_image_handler;
	if ($my_data->get_image_handler_type eq 'pdf') {
		$im_h->strokecolor($my_data->get_color('silver'));
		$im_h->circle($x, $nexusG->get_ysize-$y, $radius/2);
		$im_h->strokecolor($my_data->get_color('black'));
		$im_h->circle($x,$nexusG->get_ysize-$y,$radius/2);
		$im_h->stroke;
		$im_h->fillcolor($my_data->get_color('red'));
		$im_h->arc($x,$nexusG->get_ysize - $y,$radius/2,$radius/2,0,$prob*360 + 0.1,1);
		$im_h->fill;
	}elsif ($my_data->get_image_handler_type eq 'ps') {
		$im_h->setlinewidth(1);
		$im_h->setcolour(@{$my_data->get_color('silver')});
		$im_h->circle({filled => 1},$x,$y,$radius/2);
		$im_h->setcolour(@{$my_data->get_color('black')});
		$im_h->circle($x,$y,$radius/2);
		$im_h->setcolour(@{$my_data->get_color('red')});
		my $start = 0;
		if ($prob >= 0.5) {
			$start = 180;
			$prob -= 0.5;
			$im_h->arc({filled=>1}, $x, $y, $radius/2, 180, 0);
		}
		&__draw_pieslice($my_data,$x,$y,$radius,$prob,$start);
	} else {
		$im_h->moveTo($x,$y);
		$im_h->penSize(1,1);
#$im->bgcolor(undef);
		$im_h->bgcolor($my_data->get_color('silver'));
		$im_h->arc($radius,$radius,0,360,gdArc());
		$im_h->fgcolor($my_data->get_color('black'));
		$im_h->bgcolor($my_data->get_color('red'));
		$im_h->arc($radius,$radius,0,$prob*360,gdEdged()|gdArc());

		$im_h->moveTo($x,$y);
		$im_h->bgcolor(undef);
		$im_h->fgcolor('black');
		$im_h->ellipse($radius,$radius);
	}
}

sub __draw_pieslice {
	my ($my_data,$x,$y,$radius,$prob,$start) = @_;
	my $im_h = $my_data->get_image_handler;
	my $pi = 3.14159265;
	my $start_rad = $start/180 * $pi;
	my $prob_rad = $prob * 2 * $pi;
	$im_h->arc({filled=>1},$x,$y,$radius/2,360-($start+$prob*360),$start);
	$im_h->polygon({filled=>1},$x,$y,$x+$radius/2*cos($start_rad),$y+$radius/2*sin($start_rad),$x+$radius/2*cos($prob_rad+$start_rad),$y+$radius/2*sin($prob_rad+$start_rad));
}

sub __draw_line {
	my ($my_data,$x1, $y1, $x2, $y2, $color, $size) = @_;
	my $im_h = $my_data->get_image_handler;
	my $color_val = $my_data->get_color($color);
	if ($my_data->get_image_handler_type eq 'pdf') {
		$im_h->strokecolor($color_val);
		#$im_h->linewidth(1);
		$im_h->move($x1, $nexusG->get_ysize-$y1);
		$im_h->line($x2, $nexusG->get_ysize-$y2);
		$im_h->stroke;
	}elsif ($my_data->get_image_handler_type eq 'ps') {
		if ($size == 0.5) { $im_h->setlinewidth(0.5); }
		else { $im_h->setlinewidth(1.5); }
		$im_h->setcolour(@{$color_val});
		$im_h->line($x1,$y1,$x2,$y2);
	}
	else {
		$im_h->moveTo($x1,$y1);
		$im_h->penSize($size,1);
		$im_h->fgcolor($color_val);
		$im_h->lineTo($x2,$y2);
	}
}

sub __draw_text {
	my ($my_data, $x, $y, $string, $color) = @_;
	my $font = $my_data->get_font;
	my $im_h = $my_data->get_image_handler;
	my $color_val = $my_data->get_color($color);
	if ($my_data->get_image_handler_type eq 'pdf') {
		$im_h->fillcolor($color_val);
		$im_h->print($font,10,$x,$nexusG->get_ysize-$y,0,0,$string);
		$im_h->fill;
		
	}elsif ($my_data->get_image_handler_type eq 'ps') {
		$im_h->setcolour(@{$color_val});
		$im_h->text($x, $y + ($nexusG->get_fontHeight/4),$string);
	}
	else {
#$font="Courier";
		$im_h->moveTo($x,$y+($nexusG->get_fontHeight)/2);
		$im_h->font($font);
		$im_h->fontsize(14) if ($font eq 'Times');
		$im_h->fgcolor($color_val);
		$im_h->string($string);
	}
}


sub __draw_circle {
	my ($my_data,$x, $y, $radius, $color) = @_;
	my $im_h = $my_data->get_image_handler;
	my $color_val = $my_data->get_color($color);
	if ($my_data->get_image_handler_type eq 'pdf') {
		$im_h->strokecolor($color_val);
		#$im_h->linewidth(1);
		$im_h->circle($x,$nexusG->get_ysize - $y, $radius/2);
		$im_h->stroke;
	}elsif ($my_data->get_image_handler_type eq 'ps') {
		$im_h->setlinewidth(1);
		$im_h->setcolour(@{$color_val});
		$im_h->circle($x,$y,$radius/2);
	}else {
		$im_h->moveTo($x,$y);
		$im_h->fgcolor($color_val);
		$im_h->bgcolor($color_val);
		$im_h->arc($radius,$radius,0,360,gdEdged()|gdArc());
	}
}

sub __draw_filledRect {
	my ($my_data,$x1, $y1, $x2, $y2, $color,$transparency) = @_;
	my $color_val = $my_data->get_color($color);
	my $im_h = $my_data->get_image_handler;
	if ($my_data->get_image_handler_type eq 'pdf') {
		if (ref $color_val) {
			$im_h->fillcolor(&rgb2hex($color_val));
		}else {
			$im_h->fillcolor($color_val);
		}
		$im_h->rectxy($x1,$nexusG->get_ysize - $y1,$x2,$nexusG->get_ysize-$y2);
		$im_h->fill;
	} elsif ($my_data->get_image_handler_type eq 'ps') {
		$im_h->setcolour(map {$_*1} @{$color_val});
		$im_h->box({filled=>1},$x1,$y1,$x2,$y2);
	} else {
		if (ref $color_val) {
			$im_h->bgcolor(@{$color_val});
		}else {
			$im_h->bgcolor($color_val);
		}
		$im_h->rectangle($x1,$y1,$x2,$y2);
	}
}


=head2 checkNumber

 Title   : checkNumber
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub checkNumber {
	my $arg=$_[0];
	if ($arg =~ /(\d+\.?\d*|\.\d+)/) {
		return $arg;
	} else {
		return undef;
	}
}

=head2 isNumber

 Title   : isNumber
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub isNumber {
	my $arg=$_[0];
	my $var=$_[1];
	if ($arg =~ /(\d+\.?\d*|\.\d+)/) {
		return 1;
	} else {
		return 0;
	}
}

sub __read_nexus {
	my $mydata    = shift;
	my $inputFile = $runtime_options->{'input_file'};
	my $nexusObject;
	if($nexusG->get_isVerbose) {
		$DEBUG=1;
		$nexusObject = new Bio::NEXUS($inputFile,1);
	} else {
		$nexusObject = new Bio::NEXUS($inputFile);
	}

	if ($runtime_options->{'species_tree'} eq 'on') {
		return $nexusObject;
	}
# Read in NEXUS blocks from NEXUS object

	my @selectsub_params             = @{ $runtime_options->{'select_sub_tree'} };      # Select a subtree
	my @reroot_params                = @{ $runtime_options->{'reroot_node'} };       # Reroot a subtree
	my @swap_params                  = @{ $runtime_options->{'swap_children'} };          # Swap the children of the node
	my @excludesub_params            = @{ $runtime_options->{'exclude_sub_tree'} };    # Exclude a subtree
	my @setsbyinode_params 		 = @{ $runtime_options->{'setsbyinode'} };	
	my $tree;


	if ($nexusObject->get_block('trees')) {

		$nexusObject = $nexusObject->reroot($reroot_params[$#reroot_params]) if ($reroot_params[0] ne '');
		$nexusObject = $nexusObject->select_subtree($selectsub_params[$#selectsub_params]) if ( $selectsub_params[0] ne '' );

		foreach my $excludesub_param (@excludesub_params) {
			$nexusObject = $nexusObject->exclude_subtree($excludesub_param);
		}

		$tree = $nexusObject->get_block("trees")->get_tree();
		foreach my $swapnode(@swap_params){
			last if ($swapnode eq '');
			&swap_children($tree,$swapnode) if ($tree->find($swapnode));
		}
	} else {
		$nexusObject = $nexusObject->exclude_otus(\@excludesub_params);
	}

	if ($selectsub_params[0] ne '' || $excludesub_params[0] ne '') {
		my @intron_present_cols=();
		my @taxa = @{$nexusObject->get_block("characters")->get_taxlabels()} if $nexusObject->get_block("characters");
		my %intron_seqs = %{$nexusObject->get_block("characters","intron")->get_otuset->get_seq_string_hash} if $nexusObject->get_block("characters","intron");
		for (my $c=0; $c < length($intron_seqs{$taxa[0]}); $c++) {
			foreach my $taxon (@taxa) {
				my $sequence = $intron_seqs{$taxon};
				if (substr($sequence,$c,1) ne '0') {
					push @intron_present_cols, $c;
					last;
				}
			}
		}
		$nexusObject = $nexusObject->select_chars(\@intron_present_cols) if (lc($runtime_options->{'character_data_type'}) eq 'intron');
	}

#### Set by Inode ###
	if (defined $nexusObject->get_block("Trees") && $nexusObject->get_block("trees")->get_tree) {
		my $sets;
		my $setsblock;
		for my $inodename (@setsbyinode_params) {
			my $subtree = $nexusObject->select_subtree($inodename);
			my $otus = $subtree->get_otus();
			$$sets{$inodename} = $otus;
		}
		if ($nexusObject->get_block('Sets')) {
			$nexusObject->get_block('Sets')->add_taxsets($sets);
		} else {
			$setsblock = Bio::NEXUS::SetsBlock->new('Sets',[]);
			$setsblock->set_taxsets($sets);
			$nexusObject->add_block($setsblock);
		}

	}
#########


#my @trees = @{$block->get_trees()};		##### Get names of all trees in the file
#foreach my $myTree (@trees) {
# 	$myTreeName = $myTree->{name};
#	print "Tree: $myTreeName<br>";
#}

# EXTRACT TREE DATA
#die "No tree in file $inputFile\n" unless $tree;
return $nexusObject;
}

=head2 parse_number

 Title   : parse_number
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

# parse numbers in format "1-3, 4 6 8-10"
#Taken from nextool.pl

sub parse_number {
    my $s =  shift;
    
    if (! $s =~ /^\s*(\d+(-\d+)?)([,\s]\s*\d+(-\d+)?)*\s*$/ ) { 
        die "Invalid number format.  Use 1 or 1-3 or 1, 3, 5-8 or 1 3 5 6-10.\n"; 
    } 
    $s =~ s/^\s+|\s+$//g;
    $s =~ s/,?\s+/,/g;  # use ',' as separator
    my @cols = split(/,/, $s);
    
    my @arr;
    foreach my $item (@cols) {
        if ($item =~ /-/) { # eg 1-3
            $item =~ /([0-9]+)\s*-\s*([0-9]+)/;
            for (my $i = $1; $i <= $2; $i++) { push ( @arr, $i-1 ); }
        } elsif ($item =~ /^\d+$/) { # eg 4
            push ( @arr, $item-1 );
        } elsif ($item) {
            die "non-number was used for column number\n";
        }
    }

    @arr = sort {$a<=>$b} @arr;
    return \@arr;
}

=head2 AssignStateToNode

 Title   : AssignStateToNode
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub AssignStateToNode { 
# AssignStateToNode -- propagate colors or other states up a tree
#
# Technically, what we are doing here is reconstructing ancestral states 
# based on a transition model of infinite cost (zero rate), so that no 
# transitions are allowed.  Thus, an ancestor is assigned to a state 
# _i_ if and only if all of its descendants are assigned to state _i_.  
#
# this function 
#    * probably should be put in a library and named something like 
#      "AssignAncestralStatesByConsensus"; 
#    * maps states to the *names* of nodes, not to their object refs;
#    * allows for polytomies; 
#    * does not assume all OTUs have defined states, but note that 
#       any undefined states of OTUs *will remain undefined*
#$node          # node object
#$unknownState # state to assign when no other assignment can be made 
#$map           # hash with any available states
	my ($map, $node, $unknownState) = @_;
	my $name = $node->get_name; 
	my $lastState = undef; 
	my $assignable = 1; 

# return if state already exists OR if the node is an OTU
	return if (defined($map->{$name}) || $node->is_otu() ); 

# Go through children and make sure all children are the same state
	foreach my $child (@{$node->get_children()}) {
		my $childname = $child->get_name;
		&AssignStateToNode($map, $child, $unknownState) unless $map->{$childname};
		if ( defined($lastState) && $$map{$childname} ne $lastState ) { 
			$assignable = 0; 
		}
		$lastState = $map->{$childname}; 
	}
	return( $map->{ $name } = ( $assignable ? $lastState : $unknownState ) ); 
} 

=head2 AssignStateToSuperNode

 Title   : AssignStateToSuperNode
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub AssignStateToSuperNode {
# AssignStateToSuperNode -- propogate color up a tree to highlight a sequence's branch path
	my ($my_data, $node, $OTU, $nodesListRef, $color) = @_;
	my @nodesList = @$nodesListRef;
	my $name = $node->get_name;

	return if ($node && $node->is_otu() && ($name ne $OTU));
	if ($nodesList[$#nodesList] eq $OTU) {
		foreach my $node_name (@nodesList) {
			$my_data->set_node_color($node_name, $color);
		}
		return;
	}

	foreach my $child (@{$node->get_children()}) {
		my @newNodesList = @nodesList;
		push @newNodesList,$child->get_name;
		&AssignStateToSuperNode($my_data,$child,$OTU,\@newNodesList,$color);
	}

	return;
}

=head2 AssignStateToSubNode

 Title   : AssignStateToSubNode
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub AssignStateToSubNode { 
# AssignStateToNode -- propagate colors or other states down a tree once a node is selected
	my ($my_data, $node, $color) = @_;
	my $name = $node->get_name;
	return if (!$node || $node->is_otu());

	foreach my $child (@{$node->get_children()}) {
		$my_data->set_node_color($child->get_name,$color);
		&AssignStateToSubNode($my_data, $child, $color);
	}
	return;
} 

sub __print_piechart {
	my ($my_data, $node, $otu_seq_hash)  = @_;
	my $name 		= $node->get_name();
	my $x 			= $node->_get_xcoord;
	my $y 			= $node->_get_ycoord;
	my $seq 		= $otu_seq_hash->{$name}->[$ppp_param-1];
	my $prob 		= 0;
	$prob 			= ((ref $seq) eq 'ARRAY') ? $seq->[1] : $seq;
	&__draw_piechart($my_data,$x, $y, $nexusG->get_pieChartRadius, $prob);
	foreach my $child (@{$node->get_children()}) {
		&__print_piechart($my_data,$child,$otu_seq_hash);
	}
}

sub __print_tree {
	my ($my_data,$node, $x0, $y0,$otuseqs) = @_;
	my $name = $node->get_name();
	my $x1 = int($node->_get_xcoord);
	my $y1 = 0;
	my $color;
	my $prob_val = '';
	my $treeNodeRadius = $nexusG->get_treeNodeRadius;
	my $pieChartRadius = $nexusG->get_pieChartRadius;
	$color             = (!$runtime_options->{'set_type'} || $runtime_options->{'set_type'} eq 'None') ? $my_data->get_node_color($name)||'black' : $my_data->get_node_color($name)||'gray';
#$y1               +=  $nexusG->get_fontHeight;
	if ($ppp_param && $nexusObject->get_block('history','intron')) {
		my $seq = $otuseqs->{$name}->[$ppp_param-1];
		$prob_val = (ref $seq) ? $seq->[1] : $seq;
		$prob_val = ":p(1) = ". $prob_val;
		$y1 = int($node->_get_ycoord);
		&__draw_line($my_data,$x0, $y1, $x1, $y1, $color, 2);
		if ($y1 > $y0) {
			&__draw_line($my_data,$x0, $y1, $x0, $y0 + $pieChartRadius/2, $color, 2) unless $node->get_name eq 'root' ;
		}
		else {
			&__draw_line($my_data,$x0, $y1, $x0, $y0 - $pieChartRadius / 2, $color, 2) unless $node->get_name eq 'root' ;
		}
	}
	else {
		$y1 = int($node->_get_ycoord);
		&__draw_line($my_data,$x0, $y1, $x1, $y1, $color, 2);
		&__draw_line($my_data,$x0, $y0, $x0, $y1, $color, 2) unless $node->get_name eq 'root' ;
	}

	if ($node->is_otu()) {
		&__print_label($my_data, $x1+$pieChartRadius*.75, $y1,$node->get_name,$color) ;
	}
	my $x2 = int( $x1 + $treeNodeRadius );
	my $y2 = int( $y1 + $treeNodeRadius );
	if ( not $ppp_param ) {
		&__draw_circle($my_data,$x1, $y1,$treeNodeRadius,$color) if (!$node->is_otu); 
	}
	$my_data->set_tree_map_coord( $node->get_name, [$x1,$y1,$x2,$y2] ) if $runtime_options->{'output_type'} eq 'png';
	if ($node->{name} ne "root") {
#$query->delete("session") if ($runtime_options->{'session'});
		$node->_set_xcoord($x1);
		$node->_set_ycoord($y1);
		#$areaMap .= qq(<area shape=rect onMouseOver="showtip(this,event,'$node->{name} options $prob_val')" onMouseOut="PopUpMenu2_Hide();" coords=$x1,$y1,$x2,$y2 href="javascript:PopUpMenu2_Set(getParam(\'$qs\',\'$node->{name}\',\'$file_param\',\'$colornode_params[$#colornode_params]\'),'','','','','');">\n);
	}
	else {
		#$areaMap .= qq(<area shape=rect onMouseOver="showtip(this,event,'Root node options $prob_val')" onMouseOut="PopUpMenu2_Hide();" coords=$x1,$y1,$x2,$y2 href="javascript:PopUpMenu2_Set(getParamRoot(\'$qs\',\'$node->{name}\',\'$file_param\',\'$colornode_params[$#colornode_params]\'),'','','','','');">\n);
	}
	if (not $node->is_otu) {
		my @nodes = @{$node->get_children()};
			foreach my $child (@nodes) {
				&__print_tree($my_data,$child, $x1, $y1,$otuseqs);
			}
	}
}

sub __print_matrix {
	my ($my_data, $x0, $y0,$taxlabels,$is_print_labels) = @_;
	my $seqs = $my_data->get_char_block_seq;

	foreach my $taxa (@{$taxlabels}) {
		my $color = $my_data->get_node_color($taxa);
		&__print_label($my_data,$x0,$y0,$taxa,$color) if $is_print_labels;
		my $xPos = $nexusG->get_characterStartXpos;
		$color = 'gray' if ( (defined @{ $runtime_options->{'highlight_otus'} }) and ($color eq 'black') );
		&__print_sequence($my_data, $xPos,$y0,$seqs->{$taxa},$taxa, $color) if defined $seqs;
		$y0 += $nexusG->get_verticalOtuSpacing;
	}
}

sub __print_label {
	my ($my_data, $x, $y,$taxon_name, $color) = @_;
	my ($x1,$x2,$y1,$y2);
	$color = ( defined($color) ? $color : 'black' );
	my $tip = ($color ne 'gray') ? 'OTU options' : 'Taxonomy not identified for this sequence';

# Print either left justified or right justified names
	if ($runtime_options->{'right_justify_labels'} eq 'on') {
		$x1 = $x;
		$y1 = $y;
		$x2 = $nexusG->get_characterStartXpos - (length($taxon_name) * $nexusG->get_fontWidth) - $nexusG->get_labelMatrixGapWidth;
		$y2 = $y;
		&__draw_text($my_data,$x2,$y2,$taxon_name,$color);
		$my_data->set_label_map_coord( $taxon_name, [$x2,$y2,$x2+length($taxon_name)*$nexusG->get_fontWidth,$y2+$nexusG->get_fontHeight] ) if $runtime_options->{'output_type'} eq 'png';
		$x1 += $nexusG->get_fontWidth;
		$x2 -= $nexusG->get_fontWidth;
		&__draw_line($my_data,$x1,$y1,$x2,$y1,'gray',1) if (($x1 < $x2) && ($runtime_options->{'show_content'} ne 'Data only'));
	} else {
		$x1 = $x;
		$x2 = $nexusG->get_characterStartXpos  - $nexusG->get_labelMatrixGapWidth;
		$y1 = $y;
		#$y2 = $y-( $nexusG->get_fontHeight/2);
		$y2 = $y;
		&__draw_text($my_data,$x1,$y2,$taxon_name,$color);
		$my_data->set_label_map_coord( $taxon_name, [$x1,$y2,$x1+length($taxon_name)*$nexusG->get_fontWidth,$y2+$nexusG->get_fontHeight] ) if $runtime_options->{'output_type'} eq 'png';
		#$areaMap.= sprintf "<area shape=rect onMouseOver=\"showtip(this,event,\'$tip\')\" onMouseOut=\"PopUpMenu2_Hide();\" coords=%d,%d,%d,%d href=\"javascript:PopUpMenu2_Set(getParam2(\'$qs\',\'%s\',\'$file_param\',\'$dir_param\',\'$highlight_params[$#highlight_params]\'),'','','','','');\">\n",$x1,$y2,$x1+length($taxon_name)*$nexusG->get_fontWidth,$y2+$nexusG->get_fontHeight, $taxon_name if ($runtime_options->{'output_type'} ne "ps" && $runtime_options->{'output_type'} ne "pdf");
		$x1 += length($taxon_name) * $nexusG->get_fontWidth + $nexusG->get_fontWidth;
		&__draw_line($my_data,$x1,$y1,$x2,$y1,'gray',1) if (($x1 < $x2) && ($runtime_options->{'show_content'} ne 'Tree only') && $my_data->get_char_column_labels);
	}
}

sub __print_sequence() {
	my ($my_data, $x, $y, $sequence, $taxName, $color) = @_;
	my $block = $my_data->get_selected_char_block;
	$color = ( defined($color) ? $color : 'black' );
	my $data_type     = $block->get_format()->{'datatype'} if ($block->get_format());
	my $gap_val        = $block->get_format()->{'gap'} if ($block->get_format()->{'gap'});
	my $missing_val    = $block->get_format()->{'missing'} if ($block->get_format()->{'missing'});
	my $max_val        = $block->get_format()->{'max'} if ($block->get_format()->{'max'});
	$sequence         = uc (&__processSeqForDisplay($sequence)) if ($data_type ne 'continuous');

	my $fontWidth  = $nexusG->get_fontWidth;
	my $fontHeight = $nexusG->get_fontHeight;
	my $blockWidth = $nexusG->get_charLabelBlockWidth;
	my $xnew = $x;
	if ($data_type eq 'continuous') {
		my $continuousMax;			# Largest value in a continuous data matrix
			if (not $max_val) {		##Find largest value in continuous data
				my  @array = sort { $a <=>$b } split(' ',$my_data->get_char_block_seq->{$taxName}); 
				$continuousMax = pop @array;
			}
		my $max = $max_val || $continuousMax;
		my $xpos = $x;
		my $columnCount = 0;
		my $colorscale;
		my $color;
		my @states = split(' ',$sequence);
		my $im_h = $my_data->get_image_handler;
		for (1 .. scalar(@states)) {
			my $val = $states[$_-1];
			$my_data->add_contin_data_map_coord($taxName,[$xpos,$y,$xpos+$fontWidth,$y+$fontHeight]) if $runtime_options->{'output_type'} eq 'png';
			if ($gap_val eq $val) {
				#$floatMap .=sprintf "<area shape=\"rect\" coords=%d,%d,%d,%d onMouseOver=\"showtip(this,event,'Gap')\">\n",$xpos,$y,$xpos+$fontWidth,$y+$fontHeight;
			}
			elsif ($missing_val eq $val) {
				&__draw_text($my_data,$xpos,$y,'?','black');
				#$floatMap .=sprintf "<area shape=\"rect\" coords=%d,%d,%d,%d onMouseOver=\"showtip(this,event,'Missing')\">\n",$xpos,$y,$xpos+$fontWidth,$y+$fontHeight;	
			}
			else {
				$colorscale = ($max == 0) ? 0 :  $val/$max;
					if ($colorscale > 0.75) {
						$color = [255,(1-($colorscale-0.75)/0.25)*255,0];
					}
					elsif ($colorscale > 0.5) {
						$color = [($colorscale-0.5)/0.25*255,255,0];
					}
					elsif ($colorscale > 0.25) {
						$color = [0,255,(1-($colorscale-0.25)/0.25)*255];
					}
					else {
						$color = [0,$colorscale/.25*255,255];
					}

				&__draw_filledRect($my_data,$xpos,$y+$fontHeight-($fontHeight*$colorscale),$xpos+$fontWidth,$y+$fontHeight,$color);
				&__draw_line($my_data,$xpos,$y+$fontHeight-($fontHeight*$colorscale),$xpos,$y+$fontHeight,'black',0.5);						# Left border
				&__draw_line($my_data,$xpos+$fontWidth,$y+$fontHeight-($fontHeight*$colorscale),$xpos+$fontWidth,$y+$fontHeight,'black',0.5); # Right border
				&__draw_line($my_data,$xpos,$y+$fontHeight-($fontHeight*$colorscale),$xpos+$fontWidth,$y+$fontHeight-($fontHeight*$colorscale),'black',0.5);	# Top border
				&__draw_line($my_data,$xpos,$y+$fontHeight,$xpos+$fontWidth,$y+$fontHeight,'black',0.5);		# Bottom border
				#$floatMap .=sprintf "<area shape=\"rect\" coords=%d,%d,%d,%d onMouseOver=\"showtip(this,event,'$val')\">\n",$xpos,$y,$xpos+$fontWidth,$y+$fontHeight;
			}

			$xpos += $fontWidth;
			$columnCount++;
			$xpos += $fontWidth if ($columnCount% ($blockWidth) == 0);
		}
	}
	elsif (($runtime_options->{'colorintron'}) ne '' && (lc($runtime_options->{'character_data_type'}) ne 'intron')) {

		my %intronSequences      = %{$nexusObject->get_block("characters","intron")->get_otuset->get_seq_string_hash};
		my $intronSeq            = $intronSequences{$taxName};
		my @intronLabels         = @{$nexusObject->get_block("characters","intron")->get_charlabels};
		my @intron_present_pos   = ();

		for (my $c = 0,my $index = 0; $c < length($intronSeq); $c++, $index++) {			# Get positions only where introns are present
			$index = index($intronSeq,'1',$index);
			last if ($index == -1);
			push @intron_present_pos, $intronLabels[$index];
		}
		#print "<PRE> $taxName ";print Dumper \@intron_present_pos;print"</PRE>";
		my $frontPos   = 0;
		my $aaNum      = 0;
		my @phaseColor = ('red','blue','darkgreen');
		if (lc($runtime_options->{'character_data_type'}) eq 'protein') {
			$frontPos = 0;
			$aaNum    = 0;
			my $numBlanks;
			foreach my $intron_pos (@intron_present_pos) {
				($aaNum = $intron_pos) =~ s/(-.)//;
				$aaNum -= $runtime_options->{'select_char_range'}->[0] if defined @{$runtime_options->{'select_char_range'}};
				(my $phaseNum  = $intron_pos) =~ s/(.*-)//;
				my $phaseColor = $phaseColor[$phaseNum];
				$numBlanks  = int($aaNum/$blockWidth)-int($frontPos/$blockWidth);
				my $frontPx    = ($frontPos+int($frontPos/$blockWidth))*$fontWidth;

				next if $aaNum < 1;
				if ($aaNum <= length($sequence)) {
					&__draw_text($my_data,$xnew+$frontPx,$y,uc(substr($sequence,$frontPos+int($frontPos/$blockWidth),$aaNum-1-$frontPos+$numBlanks)),$color);
					$frontPx += ($aaNum-1-$frontPos+$numBlanks)*$fontWidth;
					$frontPx -= $fontWidth if ($aaNum%$blockWidth == 0);
					&__draw_text($my_data,$xnew+$frontPx,$y,uc(substr($sequence,$aaNum-1+int(($aaNum-1)/$blockWidth),1)),$phaseColor);
					$frontPos = $aaNum;
				}
			}
			$numBlanks  = $aaNum < 0 ? 0 : int($aaNum/$blockWidth)-int($frontPos/$blockWidth);
			my $frontPx = ($frontPos + int($frontPos/$blockWidth)) * $fontWidth;
			&__draw_text( $my_data,$xnew + $frontPx, $y, uc( substr( $sequence,$frontPos + int ( $frontPos/$blockWidth), length($sequence) - $frontPos + $numBlanks) ), $color);
		}
		elsif (lc ($runtime_options->{'character_data_type'}) eq 'dna') {
			$frontPos = 0;
			$aaNum    = 0;
			foreach my $intron_pos (@intron_present_pos) {
				($aaNum = $intron_pos) =~ s/(-.)//;
				$aaNum -= 3 * $runtime_options->{'select_char_range'}->[0] if defined @{$runtime_options->{'select_char_range'}};
				(my $phaseNum = $intron_pos) =~ s/(.*-)//;
				my $dnaNum = ($aaNum-1)*3;
				next if $dnaNum < 0;
				my $phaseColor = $phaseColor[$phaseNum];
				my $numBlanks = int(($dnaNum-1)/$blockWidth)-int(($frontPos-1)/$blockWidth);
				my $frontPx = ($frontPos+int(($frontPos-1)/$blockWidth))*$fontWidth;
				if ($dnaNum+$phaseNum < length($sequence)) {
					&__draw_text($my_data,$xnew+$frontPx,$y,uc(substr($sequence,$frontPos+int(($frontPos-1)/$blockWidth),$dnaNum-$frontPos+$numBlanks)),$color);
					$frontPx += ($dnaNum-$frontPos+$numBlanks)*$fontWidth;
					my $length = 1 if (int($dnaNum+1)/$blockWidth > int($dnaNum-1)/$blockWidth);
					&__draw_text($my_data,$xnew+$frontPx,$y,uc(substr($sequence,$dnaNum+int(($dnaNum-1)/$blockWidth),3+$length)),$phaseColor);
					$frontPos = $dnaNum+3;
				}
			}
			my $frontPx = ($frontPos+int($frontPos/$blockWidth))*$fontWidth;
			&__draw_text($my_data,$xnew+$frontPx,$y,uc(substr($sequence,$frontPos+int($frontPos/$blockWidth),length($sequence)-$frontPos+int($aaNum/$blockWidth)-int($frontPos/$blockWidth))),$color);

		}
	}
	else {
		&__draw_text($my_data,$xnew,$y,uc($sequence),$color);
	}
}


sub __processSeqForDisplay() {
	my $string = shift;
	$string =~ tr/01/.+/;
	my @tmp = split (//, $string);
	my $tmp_string = "";
	my $char_block_width = $nexusG->get_charLabelBlockWidth;
	$string =~ s/(.{$char_block_width})/$1 /g;
	return $string;
}


sub __print_char_labels {
	my ($my_data, $block) = @_;
	warn("Grabbing characters block from NEXUS file...\n") if $DEBUG;
	my @columnLabels    = $my_data->get_char_column_labels;

	my @columnLabelsAll = @{$nexusObject->get_block("characters","intron")->get_charlabels} if $nexusObject->get_block("characters","intron");
	warn "WARNING: No labels\n" unless @columnLabels;
	my $blank           = 0;
	my $longestLabel    = $nexusG->get_longestCharLabelLength();
	my $yPosition       = $nexusG->get_lowerYMargin ;
	my $highlightcol    = $columnLabelsAll[$ppp_param-1];

	for (my $i = 0; $i <= $#columnLabels; $i++) {
		if ( $i && ($i % ($nexusG->get_charLabelBlockWidth) == 0) ) { # char #11, #21, etc.
			$blank += $nexusG ->get_fontWidth;
		}
		my $label=$columnLabels[$i];
		my $x = $nexusG->get_characterStartXpos + $blank + $i * $nexusG->get_fontWidth;

		my $colpos = 0;

		for (1 .. scalar(@columnLabelsAll)) {
#print "$highlightcol , $columnLabelsAll[$_-1]<br>";
#print "@columnLabels<br>";
			if ($highlightcol eq $columnLabels[$_-1]) {
				$colpos = $_;
				last;
			}
		}

		my $color = ($ppp_param && ($colpos==($i+1))) ? 'darkgreen': 'darkred';
		$my_data->set_label_map_coord($label,[$x,$yPosition,$x+$nexusG->get_fontWidth,$nexusG->get_lowerYbound-$nexusG->get_fontHeight]) if $runtime_options->{'output_type'} eq 'png';

		$label =~ s/-|_/\|/;
		substr($label,0,0) = ' ' x (($longestLabel/$nexusG->get_fontHeight)-length($label));
		&__print_vertical_label($my_data, $x, $yPosition, $label, $color, @columnLabelsAll);
	}
}
sub __highlight_char{
	my ($my_data, $block) = @_;
	warn("Grabbing characters block from NEXUS file...\n") if $DEBUG;
	my @columnLabels    = $my_data->get_char_column_labels;

	warn "WARNING: No labels\n" unless @columnLabels;
	my $blank           = 0;
	for (my $i = 0; $i <= $#columnLabels; $i++) {
		if ( $i && ($i % ($nexusG->get_charLabelBlockWidth) == 0) ) { # char #11, #21, etc.
			$blank += $nexusG ->get_fontWidth;
		}
		my $label=$columnLabels[$i];
		my $x = $nexusG->get_characterStartXpos + $blank + $i * $nexusG->get_fontWidth;

		if (my $char_highlight_pos  = grep /^$columnLabels[$i]$/ , @{$runtime_options->{'highlight_chars'} } ) {
			&__draw_filledRect($my_data,$x,1,$x+$nexusG->get_fontWidth,$nexusG->get_lowerYMargin,'pink');
			&__draw_filledRect($my_data,$x,$nexusG->get_upperYbound,$x+$nexusG->get_fontWidth,$nexusG->get_ysize-1,'pink');
		}
	}
}

sub __print_vertical_label {
	my ($my_data, $x, $y, $label, $color,@columnLabelsAll) = @_;
	foreach my $letter (split(//,$label)) {
		&__draw_text($my_data,$x,$y,$letter,$color);
		$y += $nexusG->get_fontHeight;
	}
	$label =~ s/\|/-/;
	$label =~ s/\s//g;
	&__print_intron_history($my_data,$x,$y,$label,$color,@columnLabelsAll) if ( (lc $runtime_options->{'character_data_type'}) eq 'intron') && ($nexusObject->get_block('history','intron'));
}

sub __print_intron_history {
	my ($my_data, $x, $y, $label,$color,@columnLabelsAll) = @_;
	&__draw_text($my_data,$x,$y,'H','blue');
	$my_data->set_intron_map_coord($label,[$x,$y,$x+$nexusG->get_fontWidth,$y+$nexusG->get_fontHeight]) if $runtime_options->{'output_type'} eq 'png';
#$labelAreaMap .=sprintf "<area shape=\"rect\" onMouseOver=\"showtip(this,event,'Intron history options for $label')\" onMouseOut=\"PopUpMenu2_Hide();\" coords=%d,%d,%d,%d href=\"javascript:PopUpMenu2_Set(getParam3(\'$qs\',\'$charnum\'),'','','','','');\">\n",$x, $y, $x + $nexusG->get_fontWidth, $y + $nexusG->get_fontHeight if ($runtime_options->{'output_type'} ne "ps" && $runtime_options->{'output_type'} ne "pdf");
}

sub __plot_wts {
	my ($my_data, @weights) = @_;
	my $blank   = 0;
	my $is_weights;
	for (my $i = 0; $i <= $#weights; $i++) {
		my $height = $weights[$i] * $nexusG->get_histogramHeight ;
		if ( $i && ($i % ($nexusG->get_charLabelBlockWidth)) == 0 ) { # char #11, #21, etc.
			$blank += $nexusG->get_fontWidth;
		}
		my $x1  =  $nexusG->get_characterStartXpos  + $blank + $i * $nexusG->get_fontWidth + (0.25 * $nexusG->get_fontWidth);
		my $x2  =  $x1 + ($nexusG->get_fontWidth/2);
		my $y1  =  $nexusG->get_lowerYbound - $height - $nexusG->get_charLabelMatrixGapWidth;
		my $y2  =  $nexusG->get_lowerYbound - $nexusG->get_charLabelMatrixGapWidth;
		&__draw_filledRect($my_data,$x1,$y1,$x2,$y2,'darkgreen');
	}
}

sub __set_node_coords {
	my $tree = shift; 
	my $treeName =  $tree->get_name() || "unnamed";
	my $cladogram_type = $runtime_options->{'cladogram_mode'} if $runtime_options->{'show_cladogram'};
	$tree->_set_xcoord($nexusG->get_TreeWidth,$cladogram_type);
	$tree->_set_ycoord(0,$nexusG->get_verticalOtuSpacing);
	my @nodes = @{$tree->get_nodes()};
	my $root = $tree->get_rootnode();
	warn("Getting names of OTUs in tree...\n") if ( $DEBUG );
	my @sorted;
	for my $node (@nodes) {
		push @sorted, $node->_get_xcoord();
	}
	@sorted = sort { $a <=> $b } @sorted;
	my $sortedNum = pop @sorted;
	my $amp = $nexusG->get_TreeWidth / $sortedNum if ($sortedNum != 0); # unit of branch length
		foreach my $node (@nodes) {
			$node->_set_xcoord(($node->_get_xcoord* $amp) + $nexusG->get_lowerXbound);
			$node->_set_ycoord($node->_get_ycoord + $nexusG->get_lowerYbound);
		}
}

sub __print_inode_names() {
	my ($my_data, $nodes) = @_;
	my ($xnew,$x1, $y1);
	foreach my $node (@{$nodes}) {
		next if $node->is_otu;
		$x1 = int($node->_get_xcoord);
		$y1 = int($node->_get_ycoord);
		$xnew = $x1 + $nexusG->get_fontWidth/2;
		$xnew  += $nexusG->get_pieChartRadius* 0.5 if ($ppp_param);
		&__draw_text($my_data,$xnew, $y1,$node->get_name, 'darkgray');
	}
}
sub __print_boot_strap() {
	my ($my_data, $nodes) = @_;
	foreach my $node (@{$nodes}) {
		my $name = $node->get_name();
		next unless $node->get_support_value; # print only non-zero values and only if defined in the tree
			&__draw_text($my_data,$node->_get_xcoord - ($nexusG->get_fontWidth * 4),$node->_get_ycoord + ($nexusG->get_fontHeight)/2,$node->get_support_value,'red');
	}
}

sub __plot_scale_border_title {
	my ($my_data) = @_;
# PRINT SCALE
	my $cladogram_type = $runtime_options->{'cladogram_mode'} if $runtime_options->{'show_cladogram'};
	if ( ($runtime_options->{'show_content'} ne 'Data only') && $nexusObject->get_block('trees') && (not  $cladogram_type)) {
#$lowerYbound -= $nexusG->get_histogramHeight/2 if (!($runtimeOptions{t}) && &__get_column_labels);
#$lowerYbound -= $nexusGi->get_fontHeight if ($runtimeOptions{t});
#&__print_line($lowerXbound, $lowerYbound, $lowerXbound + $amp / 10, $lowerYbound, 2);
#&__print_line($lowerXbound, $lowerYbound+5, $lowerXbound, $lowerYbound, 2);
#&__print_line($lowerXbound + $amp / 10, $lowerYbound+5, $lowerXbound + $amp / 10, $lowerYbound, 2);
	}

# PRINT TITLE	
	#my $file_param = $my_data->get_title;
	my $file_param = 'Test';
	&__draw_text($my_data,$nexusG->get_lowerXbound, $nexusG->get_fontHeight+5, uc($file_param), 'black');

# PRINT BORDER
	if ($runtime_options->{'show_border'} eq 'on' ){ # draw a box around what Postscript has determined is the plot
		my $lowerXBorder = $nexusG->get_lowerXMargin/2;
		my $lowerYBorder = $nexusG->get_lowerYMargin/2;
		my $upperXBorder = $nexusG->get_xsize - ($nexusG->get_upperXMargin/2);
		my $upperYBorder = $nexusG->get_ysize - ($nexusG->get_upperYMargin/2);
		&__draw_line($my_data,$lowerXBorder,$lowerYBorder,$upperXBorder,$lowerYBorder,'black',2);
		&__draw_line($my_data,$upperXBorder,$lowerYBorder,$upperXBorder,$upperYBorder,'black',2);
		&__draw_line($my_data,$upperXBorder,$upperYBorder,$lowerXBorder,$upperYBorder,'black',2);
		&__draw_line($my_data,$lowerXBorder,$upperYBorder,$lowerXBorder,$lowerYBorder,'black',2);
	}
}

sub __assign_ncbi_taxonomy {

	use DBI;

	my ($my_data , $taxlabels) = @_;
	my $dbh = DBI->connect("dbi:mysql:taxonomy", "root", "") || die "Can't connect to taxonomy: $DBI::errstr"; 
	my $dir_param = $runtime_options->{'directory_param'};	
	my $table_name = ($dir_param eq 'pandit') ? 'sptr_taxa' : 'cds';
	my $field_name = ($dir_param eq 'pandit') ? 'sptr_id' : 'prot_id';
	my $search_cond=($dir_param eq 'pandit') ? "= ?" : "like ?";
	my $sql_statement; 

	if($dir_param eq 'uploads') {
		$sql_statement=qq{ 
			SELECT kingdom,name
				from taxon_name 
				where name_class='scientific name' and
				taxon_id= ? limit 10};
	}else {
		$sql_statement=qq{ 
			SELECT kingdom,name
				from $table_name,taxon_name 
				where $table_name.taxon_id=taxon_name.taxon_id and 
				name_class='scientific name' and
				$table_name.$field_name $search_cond limit 10};
	}
	my $kingdom = {     	
		vertebrata	   => lc $runtime_options->{'kingdom'}->{'vertebrate'},
		invertebrata	   => lc $runtime_options->{'kingdom'}->{'invertebrate'},
		plants		   => lc $runtime_options->{'kingdom'}->{'plant'},
		fungi		   => lc $runtime_options->{'kingdom'}->{'fungi'},
		protist		   => lc $runtime_options->{'kingdom'}->{'protist'}
	};
	for my $taxlabel (@$taxlabels) {
		my $taxlabel_tmp=(split(/\//,$taxlabel))[0];
		(my $id=$taxlabel_tmp)=~s/^.*_//g;
		if ($dir_param eq 'uploads') {
## some conditions
		}else {
			chop($id) if ($dir_param eq 'NEXUS' or  $dir_param eq 'uploads');
			chop($id) if ($dir_param eq 'NEXUS' or $dir_param eq 'uploads');
			$id = ($dir_param eq 'pandit') ? $id : "$id%";
		}
		my $sth 	= $dbh->prepare($sql_statement) || die "Can't prepare statement: $DBI::errstr"; 
		my $rc 		= $sth->execute($id) || die "Can't execute statement: $DBI::errstr";
		my $num_of_rows = $sth->rows;
		my $matrix_ref  = $sth->fetchall_arrayref;
		for (my $rowNo  = 0;$rowNo < $num_of_rows;$rowNo++) {
			$my_data->set_node_color($taxlabel,$kingdom->{$$matrix_ref[0][$rowNo]});
		}	
	}

	$dbh->disconnect;
}

=head2 swap_children

 Title   : swap_children
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub swap_children {
	my ($self,$nodename) = @_;
	my $treename     = $self->get_name();
	my $tree         = $self->clone();
	my $swapnode     = $tree->find($nodename);
	$swapnode or die "ERROR: Node $nodename not found in $treename\n";
	my $childcount   = scalar(@{$swapnode->get_children()});
	my $tempnode     =  $swapnode->get_children()->[$childcount-1];
	for (my $index	 = $childcount-1; $index > 0; $index--) {
		print $index, " ";
		$swapnode->get_children()->[$index] = $swapnode->get_children()->[$index-1];
	}
	$swapnode->get_children()->[0] = $tempnode;
	$self = $tree->clone;
}

package MyData;
use Data::Dumper;

=head2 new

 Title   : new
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub new () {

	my $self = shift;
	my $RGBcolorHash = {
		white	 	=> [250,250,250],
		red		=> [250,0,0],
		green		=> [0,150,0],
		blue		=> [0,0,250],
		forest		=> [34,139,34],
		aqua		=> [152,245,255],
		gold		=> [255,185,15],
		gray		=> [130,130,130],
		pink		=> [255,34,179],
		brown		=> [139,69,19],
		black		=> [0,0,0],
		purple		=> [111,0,111],
		orange		=> [255,120,0],
		darkgray 	=> [110,110,110],
		darkpurple 	=> [111,0,111],
		darkred 	=> [170,0,0],
		darkgreen 	=> [0,140,0],
		silver 		=> [230,232,250],
		yellow 		=> [255,255,0],
		highlighter 	=> [51,184,215],
		tranparent_pink => [255,34,179]
	};
	my $data = {
		'selected_character_block'	=> undef,
		'title'				=> undef,
		'selected_tree' 		=> undef,
		'species_tree' 			=> undef,
		'char_block_seq'		=> undef,
		'char_block_wts' 		=> [],
		'char_column_labels' 		=> [],
		'nodes_color_hash' 		=> {},
		'ps_color_hash'			=> $RGBcolorHash,
		'gd_color_hash'			=> {},
		'gd_tree_map_coord'		=> undef, 
		'gd_label_map_coord'		=> undef,
		'gd_intron_map_coord'		=> undef,
		'gd_contin_data_map_coord'	=> undef,
	};
	bless ($data,$self);
	return $data;
}

sub set_title {
	my ($self,$title) = @_;
	$self->{'title'} = $title;
}
sub get_title {
	my ($self) = @_;
	return $self->{'title'};
}
sub set_tree_map_coord {
	my ($self,$node_name,$coord) = @_;
	$self->{'gd_tree_map_coord'}->{$node_name} = $coord;
}

sub get_tree_map_coord {
	my ($self, $node_name)  = @_;
	return $self->{'gd_tree_map_coord'}->{$node_name}; ## black
}

sub set_contin_data_map_coord {
	my ($self,$node_name,$coord) = @_;
	$self->{'gd_contin_data_map_coord'}->{$node_name} = $coord;
}

sub get_contin_data_map_coord {
	my ($self, $node_name)  = @_;
	return $self->{'gd_contin_data_map_coord'}->{$node_name}; ## black
}
sub add_contin_data_map_coord {
	my ($self, $node_name,$coord)  = @_;
	push (@{ $self->{'gd_contin_data_map_coord'}->{$node_name} }, $coord); ## black
}


sub set_label_map_coord {
	my ($self,$col_label,$coord) = @_;
	$self->{'gd_label_map_coord'}->{$col_label} = $coord;
}

sub get_label_map_coord {
	my ($self, $col_label)  = @_;
	return $self->{'gd_label_map_coord'}->{$col_label}; ## black
}
sub set_intron_map_coord {
	my ($self,$col_label,$coord) = @_;
	$self->{'gd_intron_map_coord'}->{$col_label} = $coord;
}

sub get_intron_map_coord {
	my ($self, $col_label)  = @_;
	return $self->{'gd_intron_map_coord'}->{$col_label}; ## black
}

sub set_selected_char_block {
	my $self = shift;
	$self->{'selected_character_block'} = shift; 
}

sub get_selected_char_block {
	my $self = shift;
	return $self->{'selected_character_block'}; 
}
sub set_image_handler {
	my $self = shift;
	$self->{'image_handle'} = shift;
}

sub get_image_handler {
	my $self = shift;
	return $self->{'image_handle'};
}
sub set_font {
	my $self = shift;
	$self->{'font'} = shift;
}

sub get_font {
	my $self = shift;
	return $self->{'font'};
}

sub get_image_handler_type {
	my $self = shift;
	return if not defined $self->{'image_handle'};
	if ((ref $self->{'image_handle'}) =~/GD/i) {
		return 'gd';
	} elsif ((ref $self->{'image_handle'}) =~/Post/i) {
		return 'ps';
	} else {
		return 'pdf';
	}
}
sub allocate_colors {
	my $self     = shift;
	my $img_h = $self->{'image_handle'};
	foreach my $color_val (keys %{ $self->{'ps_color_hash'} }) { 
		if ((ref $img_h) =~/GD/i) {
			if ($color_val eq 'tranparent_pink'){
				$self->{'gd_color_hash'}->{$color_val} = $img_h->colorAllocateAlpha( @{ $self->{'ps_color_hash'}->{$color_val} },120); 
			}else {
				$self->{'gd_color_hash'}->{$color_val} = $img_h->colorAllocate( @{ $self->{'ps_color_hash'}->{$color_val} } );
			}
		}
	}
}
sub get_color {
	my $self     = shift;
	my $name     = shift || 'black';
	my $img_h = $self->{'image_handle'};
	my $color;
	if ((ref $img_h) =~ /GD/i) {
		$color =  $self->{'gd_color_hash'}->{lc $name}; 
	}elsif ((ref $img_h) =~/Postscript/i)  {
		$color = $self->{'ps_color_hash'}->{lc $name};
	}else {
		$color = "#". join "", map {sprintf "%2.2X",$_} @{ $self->{'ps_color_hash'}->{lc $name} } if $self->{'ps_color_hash'}->{lc $name};
	}
	return $color || $name; 
}

sub get_char_block_seq {
	my $self = shift;
	my $taxon_name  = shift;
	my $block = $self->{'selected_character_block'};
	my $data_type;
	if ( not defined $self->{'char_block_seq'} and defined $block) {
		if ($block->get_format()) {
			$data_type  = $block->get_format()->{'datatype'} ;
		}
		if ($data_type eq 'continuous') {
			$self->{'char_block_seq'} = $block->get_otuset->get_seq_string_hash(' ');
		}
		else { 
			$self->{'char_block_seq'} = $block->get_otuset->get_seq_string_hash;
		}
	}
	return 	$self->{'char_block_seq'};
}

sub get_char_column_labels {
	my $self = shift;
	my $block = $self->{'selected_character_block'};
	my @columnLabels;
	if (defined $block && (not @{$self->{'char_column_labels'}})){
		my $characterLabels = $block->get_charlabels;
		my $seqLength = $block->get_nchar;
		if ($characterLabels && @$characterLabels) { 
			@columnLabels = @$characterLabels; 
		} elsif ($seqLength) { # not labeled, e.g., typical dna or aa seq alignment
			for (1 .. $seqLength) {push @columnLabels, $_;}
		}
		$self->{'char_column_labels'}  = \@columnLabels;
	}
	return @{$self->{'char_column_labels'}};
}

sub set_node_color {
	my ($self,$node_name,$color) = @_;
	$self->{'nodes_color_hash'}->{$node_name} = $color;
}

sub get_node_color {
	my ($self, $node_name)  = @_;
	return $self->{'nodes_color_hash'}->{$node_name} || 'black'; ## black
}
sub get_nodes_hash {
	my ($self,$name,$color)  = @_;
	return $self->{'nodes_color_hash'};
}

sub get_char_block_wts {
	my $self = shift;
	my $block = $self->{'selected_character_block'};
	my $is_weights = 0;
	my @assumptions_blocks = @{ $nexusObject->get_blocks('assumptions') };
	if (not @{$self->{'char_block_wts'}}) {
		my @weights;
		for my $asmpt_block (@assumptions_blocks) {
			if ($asmpt_block->get_link( 'characters' ) eq $block->get_title()) {
				warn("Grabbing assumptions block from NEXUS file...\n") if $DEBUG;
				foreach my $assumption(@{$asmpt_block->get_assumptions()}) {
					if( $assumption->is_wt() ) {
						@weights = @{ $assumption->get_weights() };
						my $max_wt;
						$max_wt = $nexusG->get_maximumWtvalue;
#foreach my $weight(@weights) {
#	$max_wt = $weight if ($weight > $max_wt) 
#}
						foreach my $weight(@weights) {
							if ($weight eq '-') {
								$weight = 0;
							}else {
								$weight = ($max_wt != 0 ) ? ($weight/$max_wt) : 0;
							}
							$is_weights = 0;
						}
						if ( $DEBUG ) {
							warn("No weights found in this file\n") unless $is_weights;
							warn("Weights have been found in this file\n") if $is_weights;
						}
					}
				}
			}
		}
		$self->{'char_block_wts'} = \@weights;
	}
	return @{$self->{'char_block_wts'}};
}
sub set_selected_tree {
	my $self = shift;
	$self->{'selected_tree'} = shift; 
}
sub set_species_tree {
	my ($self,$tree) = @_;
	$self->{'species_tree'} = $tree;
}
sub set_gene_tree{
	my ($self,$tree) = @_;
	$self->{'gene_tree'} = $tree;
}
sub get_species_tree {
	my ($self,$tree) = @_;
	return $self->{'species_tree'};
}
sub get_gene_tree {
	my ($self) = @_;
	return $self->{'gene_tree'};
}

sub get_nodename_from_gene_tree {
	my ($self,$species_node_name) = @_;
	my $gene_tree = $self->get_gene_tree;
	my $species_tree = $self->get_species_tree;
	my @gene_nodelist = @{ $gene_tree->get_nodes};
	my $comment;
	my $species_name;
	for my $gene_node (@gene_nodelist) {
		$comment = $gene_node->get_support_value;
		my ($species_name) = $comment =~ /:?S=([^:]*)/g;
		return $gene_node->get_name if $species_name eq $species_node_name;
	}
	return undef;

}
sub get_selected_tree {
	my $self = shift;
	return $self->{'selected_tree'}; 
}

1;

################# POD Documentation ##################


__END__

=head1 NAME

nexplot.pl - PostScript plot of tree + data table (from NEXUS infile)

	=head1 SYNOPSIS

	nexplot.pl [options] foo.nex [tree_name] > foo.ps 

	=head1 OPTIONS

	-h		Brief help message
	-d		Full documentation
	-v		Verbose mode
	-V		Print version information and quit

-f		Specify output file (default: STDOUT)

	INFORMATION TO DISPLAY
	-b		Turn on bootstrap values, if any
	-i		Turn on internal node labeling
-t		Tree only (ignore any characters)
	-I		Specify character block (by "Title") to be used in matrix 
	(e.g. "dna", "protein", "intron")
-m		Matrix only (ignore any trees)
	-c		Cladogram mode:
(auto if no branch lengths present in tree)
	normal: all branch lengths equal
	accelerated: same as normal except OTUs are aligned at end
	-U		Display taxa sets in color (-U "set1 color1 [set2 color2 ...]")
	Color options are red, orange, green, forest, aqua, blue, 
	purple, pink, brown, gray, black 

	PLOT FORMATTING
	-r		Right-justify labels (default: left-justified)
-C		Columns of characters per block (default = 10)
	-T		Specify tree width (longest branch; default: 10")
	-S		Spacing (vertically) between OTUs (default: .25")
	-R		Ratio of font height to Spacing (default: 0.8; rec: 0.5-1)
	-F		Font to use for labels and titles
	-B		Draw a box indicating postscript\'s bounds of the plot area
	-g		Include gray lines after OTU labels, 
	even if -t (tree only) option is used

	PAGE SETUP
	-s		Print on multiple pages, but shrink to page height
	-o		Print on multiple pages at actual size
	-W		Specify output page width (default: 8.5")
	-H		Specify output page height (default: 11")
	-a		Change page dimensions to fit plot

	=head1 DESCRIPTION

	B<This program> will read a NEXUS file and output a PostScript display of trees (one file for each tree
			in the tree block), as well as any character matrix (e.g. sequences) if present in the file.

	=head1 FILES

	=over 4

	=back
	=head1 VERSION

	$Id: NexPlotter.pm,v 1.2 2008/06/16 19:53:41 astoltzfus Exp $

=head1 REQUIRES

	Perl 5.004, Getopt::Std, Pod::Usage, NEXUS.pm

=head1 SEE ALSO

      perl(1)

=head1 AUTHOR

      Vivek Gopalan, Micheal Cheng, Weigang Qiu (with Peter Yang, Brendan O'Brien, and Arlin Stoltzfus)

=cut

##################### End ##########################
