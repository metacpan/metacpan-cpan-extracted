package Bio::Graphics::Glyph::decorated_transcript;

use strict;
use warnings;

use Bio::Graphics::Panel;
use List::Util qw[min max];
use vars qw($VERSION);

$VERSION = '0.02';

use constant DECORATION_TAG_NAME => 'protein_decorations';
use constant DEBUG              => 0;

my @color_names = Bio::Graphics::Panel::color_names;

use base
  qw(Bio::Graphics::Glyph::processed_transcript);

sub my_descripton {
  return <<END;
This glyph extends the functionality of the Bio::Graphics::Glyph::processed_transcript glyph 
and allows protein decorations (e.g., signal peptides, transmembrane domains, protein domains)
to be drawn on top of gene models. Currently, the glyph can draw decorations in form of colored or outlined boxes 
inside or around CDS segments. Protein decorations are specified at the 'mRNA' transcript level 
in protein coordinates. Protein coordinates are automatically mapped to nucleotide coordinates by the glyph. 
Decorations are allowed to span exon-exon junctions, in which case decorations are split between exons. 
By default, the glyph automatically assigns different colors to different types of protein decorations, whereas 
decorations of the same type are always assigned the same color. 

Protein decorations are provided either with mRNA features inside GFF files (see example below) or 
dynamically via callback function using the B<additional_decorations> option (see glyph options).
The following line is an example of an mRNA feature in a GFF file that contains two protein decorations, 
one signal peptide predicted by SignalP and one transmembrane domain predicted by TMHMM:

chr1   my_source   mRNA  74796  75599   .  +  .  ID=rna_gene-1;protein_decorations=SignalP40:SP:1:23:0:my_comment,TMHMM:TM:187:209:0

Each protein decoration consists of six fields separated by a colon:

1) Type. For example used to specify decoration source (e.g. 'SignalP40')
2) Name. Decoration name. Used as decoration label by default (e.g. 'SP' for signal peptide)
3) Start. Start coordinate at the protein-level (1-based coordinate)
4) End. End coordinate at the protein-level
5) Score. Optional. Score associated with a decoration (e.g. Pfam E-value). This score can be used 
   to dynamically filter or color decorations via callbacks (see glyph options).
6) Description. Optional. User-defined description of decoration. The glyph ignores this description, 
   but it will be made available to callback functions for inspection. Special characters 
   like ':' or ',' that might interfere with the GFF tag parser should be avoided. 

If callback functions are used as glyph parameters (see below), the callback is called for each
decoration separately. That is, the callback can get called multiple times for the same CDS feature,
but each time with a different active decoration. The currently drawn (active) decoration is made available 
to the callback via the glyph method 'active_decoration'. The active decoration is returned in form
of a Bio::Graphics::Feature object, with decoration data fields mapped to corresponding feature
attributes in the following way:

  type --> \$glyph->active_decoration->type
  name --> \$glyph->active_decoration->name
  nucleotide start coordinate --> \$glyph->active_decoration->start
  nucleotide end coordinate --> \$glyph->active_decoration->end
  protein start coordinate --> \$glyph->active_decoration->get_tag_values('p_start')
  protein end coordinate --> \$glyph->active_decoration->get_tag_values('p_end')
  score --> \$glyph->active_decoration->score
  description --> \$glyph->active_decoration->desc

In addition, the glyph passed to the callback allows access to the parent glyph and
parent feature if required (use \$glyph->parent or \$glyph->parent->feature). 

NOTE: This glyph works only with GFF3 compliant features. In particular, make sure that
every feature has a valid unique ID and that all child features have a valid parent id.

END
}

sub my_options {
    return {
	decoration_visible => [
	    'boolean',
	    'false',
	    'Specifies whether decorations should be visible or not. For selective display of individual', 
        'decorations, specify a callback function and return 1 or 0 after inspecting the active',
        'decoration of the glyph. '],
	decoration_color => [
	    'color',
	    undef,
	    'Decoration background color. If no color is specified, colors are assigned automatically',
	    'by decoration type and name, whereas decorations of identical type and name are assigned',
	    'the same color. A special color \'transparent\' can be used here in combination with',
	    'the option \'decoration_border\' to draw decorations as outlines.'],
	decoration_border => [
	    ['none', 'solid', 'dashed'],
	    'none',
	    'Decoration border style. By default, decorations are drawn without border (\'none\' or',
	    '0). Other valid options here include \'solid\' or \'dashed\'.'],
	decoration_border_color => [
	    'color',
	    'black',
	    'Color of decoration border.'],
	decoration_label => [
	    'string',
	    undef,
	    'Decoration label. If not specified, the second data field of the decoration is used',
	    'as label. Set this option to 0 to get unlabeled decorations. If the label text',
	    'extends beyond the size of the decorated segment, the label will be clipped. Clipping',
	    'does not occur for SVG output.'],
	decoration_label_position => [
	    ['inside', 'above', 'below'],
	    'inside',
	    'Position of decoration label. Labels can be drawn \'inside\' decorations (default)',
	    'or \'above\' and \'below\' decorations.'],
	decoration_label_color => [
	    'color',
	    'undef',
	    'Decoration label color. If not specified, this color is complementary to',
	    'decoration_color (e.g., yellow text on blue background, white on black, etc.). If the', 
        'decoration background color is transparent and no decoration label color is specified,',
        'the foreground color of the underlying transcript glyph is used as default.'],
	additional_decorations => [
	    'string',
	    undef,
	    'Additional decorations to those specified in the GFF file. Expected is a',
	    'comma-separated string in the same format as described above for GFF files.',
	    'Example string: "SignalP40:SP:1:23:0:my_comment,TMHMM:TM:187:209:0"',
	    'This parameter is intended',
	    'to be used as callback function, which inspects the currently processed transcript',
	    'feature (first parameter to callback) and returns additional protein decorations',
	    'that should be drawn. Alternatively, decorations not specified in the GFF file can', 
	    'also be added dynamically to feature objects before rendering using the',
	    'add_tag_value() method of the feature object.'],
	decoration_height => [
	    'integer',
	    undef,
	    'Decoration height. Unless specified otherwise, the height of the decoration is the',
	    'height of the underlying transcript glyph minus 2, such that the decoration is drawn',
	    'within transcript boundaries.'],
	decoration_position => [
	    ['inside', 'stacked_bottom', '<integer value>'],
	    'inside',
	    'Vertical position of the decoration. If \'inside\' is specified',
        '(default), decorations are drawn inside CDS segments.', 
        'Alternatively, a positive or negative integer value can be',
        'specified, which will vertically offset the decoration by',
        'the specified amount (in pixels) relative to the CDS segment.',
        'Specifying \'stacked_bottom\' will stack decorations below',
        'CDS segments in a non-overlapping manner (experimental).'],
	decoration_position => [
	    ['CDS', 'mRNA'],
	    'CDS',
        'Feature level at which decoration is drawn (\'CDS\' or \'mRNA\').',
        'By default, decorations are drawn at the \'CDS\'',
        'level, which means the decoration is only visible where it',
        'overlaps with a coding sequence, skipping introns.',
        'Under some circumstances decorations should span introns,',
        'which can be achieved by specifying \'mRNA\' here.'],
	box_subparts => [
	    'integer',
	    '0',
	    'Same functionality as for basic glyph. Enables mouse-over effects',
	    '(tooltips and hyperlinks) for decorations via generation of image maps.', 
	    'Image maps for decorations will be generated if the level specified here exceeds',
	    'the level of the underlying glyph part. For example, if you specify level 3,', 
	    'image maps will be generated for decorations of part level 1 (mRNA)', 
	    'and part level 2 (CDS). Note that this option must be used in combination with', 
	    '-link and -title.']
    }
}

sub new {
	my ( $class, @args ) = @_;
	my %param = @args;

	warn "new(): " . join( ",", @args ) . "\n" if (DEBUG == 2);

	my $feature = $param{'-feature'};
	my $factory = $param{'-factory'};
	
	my $self = $class->Bio::Graphics::Glyph::processed_transcript::new(@args);

	$self->{'parent'} = undef;
	$self->{'additional_decorations'} = undef;
	$self->{'active_decoration'} = undef;

	# give sub-glyphs access to parent glyph's decorations
	if ($self->decorations_visible)
	{
		foreach my $sub_glyph ( $self->parts ) {
			$sub_glyph->{'parent'} = $self;
		}		
	}

	bless( $self, $class );

	return $self;
}

sub finished {
	my $self = shift;

	warn "finished(): ".$self->feature->primary_tag." ".$self->feature."\n" if (DEBUG == 2);

	foreach my $sub_glyph ( $self->parts ) {
		$sub_glyph->{'parent'} = undef;
	}

	$self->Bio::Graphics::Glyph::processed_transcript::finished(@_);
}


sub parent {
	my $self = shift;
	return $self->{'parent'};
}

sub get_feature_decorations {
	my $feature = shift;

	return $feature->get_tag_values(DECORATION_TAG_NAME);
}

# allows to retrieve additional decorations via callback
sub additional_decorations {
	my $self    = shift;
	my $feature = $self->feature;

	return $self->{'parent'}->additional_decorations(@_)
		if ($self->{'parent'} and $feature->primary_tag ne "mRNA");

	return $self->{'additional_decorations'}
		if (defined $self->{'additional_decorations'});
		
	my @additional_decorations;
	my $additional_decorations_str = $self->option('additional_decorations');
	if ($additional_decorations_str)
	{
		push(@additional_decorations, split(",", $additional_decorations_str));
	}
	
	$self->{'additional_decorations'} = \@additional_decorations;
	
	return \@additional_decorations;
}

# returns stack offset of decoration (only used if decoration is drawn stacked)
sub stack_offset_bottom {
	my $self = shift;

	return $self->{'parent'}->stack_offset_bottom(@_)
		if ($self->{'parent'} and $self->feature->primary_tag ne "mRNA");

	my $decoration = shift;
	return $self->{'stack_offset_bottom'}{$decoration};
}

sub active_decoration {
	my $self = shift;	
	return $self->{'active_decoration'};
}

sub mapped_decorations {
	my $self    = shift;
	my $feature = $self->feature;

	# no decorations at gene level
	return []
		if ($self->feature->primary_tag eq "gene");

	# forward request to parent feature if not at transcript level
	return $self->{'parent'}->mapped_decorations(@_)
		if ($self->{'parent'} and $feature->primary_tag ne "mRNA");

	if (!defined $self->{'mapped_decorations'})
	{
		my $cds_tag_name = $self->option('sub_part');
		$self->{'mapped_decorations'} = get_decorations_as_features($feature, $self->additional_decorations, $cds_tag_name);

		# on first call, init stack offset for stacked decorations
		foreach my $d (@{$self->{'mapped_decorations'}})
		{	
			if ($self->decoration_position($d) eq 'stacked_bottom')
			{			
				if (!defined $self->{'stack_offset_bottom'}{$d})
				{				
					$self->{'cur_stack_offset_bottom'} = 2 
						if (!defined $self->{'cur_stack_offset_bottom'});
						
					$self->{'stack_offset_bottom'}{$d} = $self->{'cur_stack_offset_bottom'};
					$self->{'cur_stack_offset_bottom'} += $self->decoration_height($d);
	
					warn "$self: stack offset ".$d->name."($d): ".$self->{'stack_offset_bottom'}{$d}."\n"
						if (DEBUG);
				}
			}
		}
	}

	return $self->{'mapped_decorations'};
}

# get all mapped decorations, as sorted by user call-back (if provided)
# by default, decorations are sorted by length, causing shorter decorations
#   to be drawn on top of longer decorations
# TODO: document this new feature
sub sorted_decorations {
	my $self = shift;
	my $large_first = shift;

	# forward request to mRNA parent glyph; 
	# allows CDS child glyphs to retrieve decoration information from mRNA
	return $self->{'parent'}->sorted_decorations(@_)
		if ($self->{'parent'} and $self->feature->primary_tag ne "mRNA");

	# cache for faster access
	return $self->{'sorted_decorations'}
		if (defined $self->{'sorted_decorations'});
	
	# try to get sorted decorations from callback
	my $sorted_decorations = $self->option('sorted_decorations');
	
	# if no callback or bad return value, sort by length by default (causes longer 
	# decorations to be drawn first)
	if (!$sorted_decorations or ref($sorted_decorations) ne 'ARRAY')
	{
		my @sorted = reverse sort { $a->length <=> $b->length } (@{$self->mapped_decorations});
		$sorted_decorations = \@sorted;

		if (DEBUG)
		{
			print STDERR "sorted decorations: ";
			foreach my $sd (@$sorted_decorations) { print STDERR $sd->name."(".$sd->length.") "; }
			print STDERR "\n";
		}
	}

	$self->{'sorted_decorations'} = $sorted_decorations;
	
	return $sorted_decorations;
}

# returns decorations of feature as Bio::Graphics::Feature array, with coordinates mapped to nucleotide space
sub get_decorations_as_features
{
	my $feature = shift;
	my $additional_decorations = shift;  # optional
	my $cds_tag_name = shift;  # optional; default: "CDS"
	
	my @features;
	my $map = _get_coordinate_map($feature, $cds_tag_name);
	
	my @decorations = get_feature_decorations($feature);
	push(@decorations, @$additional_decorations) if ($additional_decorations);
	
	# map coordinates and encapsulate in Bio::Graphics::Feature objects
	foreach my $decoration (@decorations)
	{
		my ( $type, $name, $p_start, $p_end, $score, $desc ) = split( ":", $decoration );

		if (!defined $p_end)
		{
			warn "get_decorations_as_features(): WARNING: invalid decoration data for feature $feature(".$feature->primary_tag."):\n$decoration\n";
			next;
		}

		my $nt_start =$map->{$p_start}->{'codon_start'};
		if (!$nt_start)
		{
			warn "get_decorations_as_features(): WARNING: could not map decoration start coordinate on feature $feature(".$feature->primary_tag."):\n$decoration\n";
			next;
		}
		my $nt_end = $map->{$p_end}->{'codon_end'};
		if (!$nt_end)
		{
			warn "get_decorations_as_features(): WARNING: could not map decoration end coordinate on feature $feature(".$feature->primary_tag."):\n$decoration\n";
			next;
		}

		( $nt_start, $nt_end ) = ( $nt_end, $nt_start )
		  if ( $nt_start > $nt_end );

		my $f = Bio::Graphics::Feature->new
		(
			-type => $type,
			-name => $name,
			-display_name => $name,
			-start => $nt_start,
 			-end => $nt_end,
			-score => $score,
			-desc => $desc,
			-seq_id => $feature->seq_id,
			-strand => $feature->strand,
			-attributes => {   # remember protein coordinates for callbacks  
				'p_start' => $p_start, 
				'p_end' => $p_end 
			}
		);
		
		warn "DECORATION=$decoration --> $nt_start:$nt_end\n" if (DEBUG);

		push(@features, $f);
	}	
	
	return wantarray ? @features : \@features; 
}

# map protein to nucleotide coordinate
sub _get_coordinate_map {
	my $feature = shift;
	my $cds_tag_name = shift || 'CDS';
	my %map;
	
 # sort all CDS features by coordinates
 # NOTE: filtering for CDS features by passing feature type to get_SeqFeatures()
 # does not work for some reason, probably when no feature store attached
	my @cds = grep { $_->primary_tag eq $cds_tag_name } $feature->get_SeqFeatures();
	if ( $feature->strand > 0 ) {
		my ( $ppos, $residue ) = ( 1, 0 );
		my @sorted_cds = sort { $a->start <=> $b->start } (@cds);
		foreach my $c (@sorted_cds) {
			$map{ $ppos - 1 }{'codon_end'} = $c->start + $residue - 1
			  if ($residue);
			for (
				my $ntpos = $c->start + $residue ;
				$ntpos <= $c->end ;
				$ntpos += 3
			  )
			{
				$map{$ppos}{'codon_start'} = $ntpos;
				$map{$ppos}{'codon_end'}   = $ntpos + 2;
				$ppos++;
				$residue = $ntpos + 2 - $c->end;
			}
		}
	}
	else {
		my ( $ppos, $residue ) = ( 1, 0 );
		my @sorted_cds = reverse sort { $a->start <=> $b->start } (@cds);
		foreach my $c (@sorted_cds) {
			$map{ $ppos - 1 }{'codon_end'} = $c->end - $residue + 1
			  if ($residue);
			for (
				my $ntpos = $c->end - $residue ;
				$ntpos >= $c->start ;
				$ntpos -= 3
			  )
			{
				$map{$ppos}{'codon_start'} = $ntpos;
				$map{$ppos}{'codon_end'}   = $ntpos - 2;
#				print $self->feature->name."\t$ppos\t".$self->{'p2n'}{$ppos}{'codon_start'}."\t".$self->{'p2n'}{$ppos}{'codon_end'}."\n" if ($self->feature->name eq "DAF19-b");
				$ppos++;
				$residue = $c->start - ( $ntpos - 2 );
			}
		}
	}
	
	return \%map;
}

sub decoration_top {
	my $self = shift;
	my $decoration = shift;
	
	if (!$decoration)
	{
		$self->throw("decoration not specified")	if (DEBUG);
		return $self->top;
	}

	my $decoration_height = $self->decoration_height($decoration);	
	my $decoration_position = $self->decoration_position($decoration);
	
	if ($decoration_position eq 'stacked_bottom')
	{			
		$self->throw("$self: stack offset unknown for decoration ".$decoration->name."($decoration)")
			if (!defined $self->stack_offset_bottom($decoration) and DEBUG);
		
#		return $self->bottom + $self->stack_offset_bottom($decoration);
		return $self->top+$self->height + $self->stack_offset_bottom($decoration);
	}
	elsif ($decoration_position =~ /^[+-]?\d+$/)  # number is interpreted as vertical offset
	{
		return $self->top + $decoration_position;
	}
	else 
	{
		$self->throw("invalid decoration_position: $decoration_position")
			if (($decoration_position ne 'inside') and DEBUG);
			
#		return int(($self->bottom-$self->pad_bottom+$self->top+$self->pad_top)/2 - $decoration_height/2 + 0.5);
#		print "top: ".$self->top." height: ".$self->height." decoration_height: ".$decoration_height." result: ".int(($self->top+$self->height)/2 - $decoration_height/2 + 0.5)."\n";		
		return int($self->top+$self->height/2 - $decoration_height/2 + 0.5);		
	}
}

sub decoration_bottom {
	my $self = shift;
	my $decoration = shift;
	
	if (!$decoration)
	{
		$self->throw("decoration not specified")	if (DEBUG);
		return $self->bottom;
	}

	return $self->decoration_top($decoration) + $self->decoration_height($decoration) - 1;	
}

sub _get_add_padding
{
 	my $self = shift;
	
	# determine additional top/bottom padding required due to decorations and decoration labels 
 	my ($max_pad_bottom, $max_pad_top) = (0, 0);
	foreach my $decoration (@{$self->mapped_decorations})
	{
		# skip invisible decorations
		next if (!$self->decoration_visible($decoration));
		
		# additional padding = decoration bound - transcript/gene bound
		my $pad_top = max(0, $self->top - $self->decoration_top($decoration));
		my $pad_bottom = max(0, $self->decoration_bottom($decoration) - $self->top - $self->height);		

		# additional padding for decoration label?
		if ($self->decoration_label($decoration))
		{
			$pad_top += $self->labelfont->height
				if ($self->decoration_label_position($decoration) eq "above");
			$pad_bottom += $self->labelfont->height
				if ($self->decoration_label_position($decoration) eq "below");			
		}

		$max_pad_top = max($max_pad_top, $pad_top);
		$max_pad_bottom = max($max_pad_bottom, $pad_bottom);			    
	}
		
	return ($max_pad_top, $max_pad_bottom);	
}

# add extra padding if decoration exceeds transcript boundaries and if labeled outside
sub pad_bottom {
 	my $self = shift;

	# do not invoke for individual CDS or exon
	return 0 
		if ($self->feature->primary_tag =~ /(CDS|exon|UTR)/i);

	return $self->{'pad_bottom'}
		if (defined $self->{'pad_bottom'});
		
	$self->{'pad_bottom'} = $self->option('pad_bottom');
	if (!defined $self->{'pad_bottom'}) {
		my ($add_pad_top, $add_pad_bottom) = $self->_get_add_padding();
		my $pad = $self->Bio::Graphics::Glyph::processed_transcript::pad_bottom;
			
	  	if ($add_pad_bottom < 0) {
	  		$self->{'pad_bottom'} = $pad;
	  	}
	  	else {
	  		$self->{'pad_bottom'} = $pad + $add_pad_bottom;
	  	}  	
	}
	
  	return $self->{'pad_bottom'};
}

sub pad_top {
	my $self = shift;

	# do not invoke for individual CDS	
	return 0 
		if ($self->feature->primary_tag =~ /(CDS|exon|UTR)/i);
	
	return $self->{'pad_top'}
		if (defined $self->{'pad_top'});

	$self->{'pad_top'} = $self->option('pad_top');

	if (!defined $self->{'pad_top'}) {
		my ($add_pad_top, $add_pad_bottom) = $self->_get_add_padding();
		my $pad = $self->Bio::Graphics::Glyph::processed_transcript::pad_top;
	
	  	if ($add_pad_top < 0) {
	  		$self->{'pad_top'} = $pad;
	  	}
	  	else {
	  		$self->{'pad_top'} = $pad + $add_pad_top;
	  	}
	}
  	
  	return $self->{'pad_top'};		
}

sub decoration_height {
	my $self = shift;
	my $decoration = shift;

	if (!$decoration)
	{
		$self->throw("decoration not specified")	if (DEBUG);
		return $self->height;
	}

	$self->{'active_decoration'} = $decoration; # set active decoration for callback
	my $decoration_height = $self->option('decoration_height');

	$decoration_height = $self->height-2
	  if ( !$decoration_height );

	return $decoration_height;
}

sub decoration_position {
	my $self = shift;
	my $decoration = shift;

	if (!$decoration)
	{
		$self->throw("decoration not specified")	if (DEBUG);
		return "inside";
	}

	$self->{'active_decoration'} = $decoration; # set active decoration for callback
	my $decoration_position = $self->option('decoration_position');
	
	$decoration_position = 'inside'
	  if ( !$decoration_position );

	return $decoration_position;
}

sub _hash {
	my $hash = 0;
	foreach ( split //, shift ) {
		$hash = $hash * 33 + ord($_);
	}
	$hash = $hash + ($hash >> 5);
	return $hash;
}

sub decoration_label_color {
	my $self = shift;
	my $decoration = shift;
	
	if (!$decoration)
	{
		$self->throw("decoration not specified")	if (DEBUG);
		return "black";
	}

	$self->{'active_decoration'} = $decoration; # set active decoration for callback
	my $decoration_label_color = $self->option('decoration_label_color');

	return $decoration_label_color
	  if (  defined $decoration_label_color
		and $decoration_label_color ne 'auto'
		and $decoration_label_color ne '' );
		
	my $decoration_color = $self->decoration_color($decoration);

	return $self->fgcolor
		if ((!$decoration_label_color or $decoration_label_color eq 'auto') 
		      and $decoration_color eq "transparent");

	# assign color complementary to decoration color
	my ( $red, $green, $blue ) =
	  Bio::Graphics::Panel->color_name_to_rgb($decoration_color);

	$decoration_label_color =
	  sprintf( "#%02X%02X%02X", 255 - $red, 255 - $green, 255 - $blue );    # background complement

	return $decoration_label_color;
}

sub decoration_label {
	my $self = shift;
	my $decoration = shift;
	
	if (!$decoration)
	{
		$self->throw("decoration not specified")	if (DEBUG);
		return "";
	}

	$self->{'active_decoration'} = $decoration; # set active decoration for callback
	my $decoration_label = $self->option('decoration_label');
	
	return undef 
		if ( defined $decoration_label and $decoration_label eq "0" );

	return $decoration_label
		if ( $decoration_label and $decoration_label ne "1");
		
	# assign decoration name as default label
	return $decoration->name;
}

sub decoration_label_position {
	my $self = shift;
	my $decoration = shift;
	
	if (!$decoration)
	{
		$self->throw("decoration not specified")	if (DEBUG);
		return "";
	}

	$self->{'active_decoration'} = $decoration; # set active decoration for callback
	my $decoration_label_position = $self->option('decoration_label_position');
	
	return "inside"
		if (!$decoration_label_position);
		
	return $decoration_label_position;
}

sub decoration_border {
	my $self = shift;
	my $decoration = shift;
	
	if (!$decoration)
	{
		$self->throw("decoration not specified")	if (DEBUG);
		return "";
	}

	$self->{'active_decoration'} = $decoration; # set active decoration for callback
	my $decoration_border = $self->option('decoration_border');
	
	return 0 if (!$decoration_border or $decoration_border eq 'none');
	
	return $decoration_border;
}

sub decoration_level {
	my $self = shift;
	my $decoration = shift;
	
	if (!$decoration)
	{
		$self->throw("decoration not specified")	if (DEBUG);
		return "";
	}

	$self->{'active_decoration'} = $decoration; # set active decoration for callback
	my $decoration_level = $self->option('decoration_level');
	
	return "CDS" if (!$decoration_level);
	
	return $decoration_level;
}

sub decoration_color {
	my $self = shift;
	my $decoration = shift;
	
	if (!$decoration)
	{
		$self->throw("decoration not specified")	if (DEBUG);
		return "white";
	}

	$self->{'active_decoration'} = $decoration; # set active decoration for callback
	my $decoration_color = $self->option('decoration_color');

	return $decoration_color
	  if (  defined $decoration_color
		and $decoration_color ne 'auto'
		and $decoration_color ne '' );

	# automatically assign color by hashing feature name to color index
	# 2012-04-24 | CF | reversed order of name and type for better color discrimination of different domains of same type
	my $col_idx = _hash($decoration->name.":".$decoration->type) % scalar(@color_names);
	
	# decoration background should be different from CDS background
	while ( $self->factory->translate_color($color_names[$col_idx]) eq $self->bgcolor )
	{
		$col_idx = ($col_idx + 1) % scalar(@color_names);
	}

	return $color_names[$col_idx];
}

sub decoration_border_color {
	my $self = shift;
	my $decoration = shift;
	
	if (!$decoration)
	{
		$self->throw("decoration not specified")	if (DEBUG);
		return "black";
	}

	$self->{'active_decoration'} = $decoration; # set active decoration for callback
	my $decoration_border_color = $self->option('decoration_border_color');

	return "black" if (!$decoration_border_color);
	
	return $decoration_border_color;
}

sub decorations_visible {
	my $self = shift;

	return $self->code_option('decoration_visible');
}

sub decoration_visible {
	my $self = shift;
	my $decoration = shift;
	
	if (!$decoration)
	{
		$self->throw("decoration not specified")	if (DEBUG);
		return 1;
	}

	$self->{'active_decoration'} = $decoration; # set active decoration for callback
	my $decoration_visible = $self->option('decoration_visible');

	return $decoration_visible
	  if ( defined $decoration_visible and $decoration_visible ne "" );

	return 1;
}

# 2012-05-03 | CF | enable image maps for decorations
sub boxes {
	my $self = shift;

	my @boxes;
	
	my $box_subparts = $self->option('box_subparts');
	if (defined $box_subparts and $box_subparts > $self->level)
	{
		my ($left,$top,$parent) = @_;
	  	$top  += 0; $left += 0;
		# write image maps for smaller decorations first, such that they are on top of larger ones
		my @sorted_decoration = sort { $a->length <=> $b->length } (@{$self->mapped_decorations});
		
		foreach my $mh (@sorted_decoration) {

			next if ( !$self->decoration_visible($mh) );
			next if ( uc($self->decoration_level($mh)) ne uc($self->feature->primary_tag) ); # only decorations at mRNA level 
			
			
			# determine overlapping segments between protein decorations and glyph part
			my $overlap_start_nt = max( $self->feature->start, $mh->start );
			my $overlap_end_nt = min( $self->feature->end, $mh->end );

			if ( $overlap_start_nt <= $overlap_end_nt ) {
	
				my ( $h_left, $h_right ) =  $self->map_no_trunc( $overlap_start_nt, $overlap_end_nt + 1 );
				( $h_left, $h_right ) = ( $h_right, $h_left ) if ( $h_left > $h_right );
				my $h_top = $top + $self->decoration_top($mh);
				my $h_bottom = $top + $self->decoration_bottom($mh);

				push(@boxes, [$mh, $h_left, $h_top, $h_right, $h_bottom, $self]);
			}
		}
	}		

	push(@boxes, $self->Bio::Graphics::Glyph::processed_transcript::boxes(@_));
	
	return wantarray ? @boxes : \@boxes;
}

sub draw {
	my $self = shift;

	warn "draw(): level " . $self->level . " " . $self->feature . "\n"
	  if (DEBUG);

	# undocumented parameter to draw only highlights, ignoring underlying gene model
	if (!$self->option('hide_model'))
	{
		$self->Bio::Graphics::Glyph::processed_transcript::draw(@_) ;
		#warn "draw(): level " . $self->level . " " . $self->feature->name . "\n" if ($self->feature->name);
	}  
	else
	{
		$self->Bio::Graphics::Glyph::draw(@_) ;		
	}

	if ( $self->feature->primary_tag eq "mRNA") {
		return $self->draw_decorations_mRNA(@_);
	}
}

sub draw_connector {
	my $self = shift;

	warn "draw_connector(): " . ref($self) . " " . $self->feature . "\n" if (DEBUG == 2);

    # 2012-04-23 | CF | new undocumented parameter -hide_model to draw only highlights, ignoring underlying gene model
	return $self->Bio::Graphics::Glyph::processed_transcript::draw_connector(@_)
		if (!$self->option('hide_model'));
}

sub draw_component {
	my $self = shift;

	warn "draw_component(): " . ref($self) . " " . $self->feature . "\n" if (DEBUG == 2);

	# draw gene model first
    # 2012-04-23 | CF | new undocumented parameter -hide_model to draw only highlights, ignoring underlying gene model
	if (!$self->option('hide_model'))  
	{
		$self->Bio::Graphics::Glyph::processed_transcript::draw_component(@_);
	}

	# draw decorations on top of gene model
	my $cds_tag_name = $self->option('sub_part') || 'CDS';
	if ( $self->{'parent'} and $self->feature->primary_tag eq $cds_tag_name) {
		return $self->draw_decorations_CDS(@_);
	}
}

sub draw_decorations_mRNA {
	my $self = shift;
	my ( $gd, $dx, $dy ) = @_;

	warn "draw_decorations_mRNA(): " . $self->feature . "\n" if (DEBUG == 2);

	my ( $left, $top, $right, $bottom ) = $self->bounds( $dx, $dy );

	warn "  bounds: left:$left,top:$top,right:$right,bottom:$bottom\n"
	  if (DEBUG == 2);

	foreach my $mh (@{$self->sorted_decorations}) {
		  
		next if ( !$self->decoration_visible($mh) ); 		# skip invisible decorations
		next if ( $self->decoration_level($mh) ne 'mRNA' ); # only decorations at mRNA level 

		$self->draw_decoration($gd, $dx, $dy, $mh, $mh->start, $mh->end, $self->decoration_label($mh));
	}
}

sub draw_decorations_CDS {
	my $self = shift;
	my ( $gd, $dx, $dy ) = @_;

	warn "draw_decorations_CDS(): " . $self->feature . "\n" if (DEBUG == 2);

	# determine overlaps of visible decorations with CDS
	my @overlaps;
	foreach my $mh (@{$self->sorted_decorations}) {
			  
		next if ( !$self->decoration_visible($mh) );  # skip invisible decorations
		next if ( $self->decoration_level($mh) ne 'CDS' ); # only decorations at CDS level 
	
		# determine overlapping segments between protein decorations and feature components
		my $overlap_start_nt = max( $self->feature->start, $mh->start );
		my $overlap_end_nt = min( $self->feature->end, $mh->end );
		
		push (@overlaps, [$mh, $overlap_start_nt, $overlap_end_nt]) if ( $overlap_start_nt <= $overlap_end_nt ); 
	}
	
	# draw decorations
	foreach my $o (@overlaps) {
		
		my ($mh, $overlap_start_nt, $overlap_end_nt) = @$o;

		# draw label only on first overlapping component
		my $h_label = $self->decoration_label($mh);
		$h_label = undef
			if ( (!$self->flip and $overlap_start_nt > $mh->start) or ($self->flip and $overlap_end_nt < $mh->end) );

		$self->draw_decoration($gd, $dx, $dy, $mh, $overlap_start_nt, $overlap_end_nt, $h_label);
	}	
}

sub draw_decoration {
	my $self = shift;
	my ( $gd, $dx, $dy, $mh, $nt_start, $nt_end, $label ) = @_;

	my ( $left, $top, $right, $bottom ) = $self->bounds( $dx, $dy );

	warn "  bounds: left:$left,top:$top,right:$right,bottom:$bottom\n"
	  if (DEBUG == 2);

	my ($h_left, $h_top, $h_right, $h_bottom) = $self->_map_decoration($gd, $dx, $dy, $mh, $nt_start, $nt_end);

	my $color = $self->decoration_color($mh);

	 # don't draw over borders; not supported by SVG
	$gd->clip( $left + 1, $h_top, $right - 1, $h_bottom )
	  if ( !$gd->isa("GD::SVG::Image") );

	if ($color ne 'transparent')
	{
		warn "filledRectangle: left=$h_left,top=$h_top,right=$h_right,bottom=$h_bottom\n"
		  if (DEBUG == 2);
		$gd->filledRectangle( $h_left, $h_top, $h_right, $h_bottom,
			$self->factory->translate_color($color) );				
	}

	my $border_style = $self->decoration_border($mh);
	if ($border_style)
	{
		my ($b_left, $b_top, $b_right, $b_bottom) = ($h_left, $h_top, $h_right, $h_bottom);
		my $border_color = $self->factory->translate_color($self->decoration_border_color($mh));

		warn "border rectangle ($border_style): left=$b_left,top=$b_top,right=$b_right,bottom=$b_bottom\n"
			if (DEBUG == 2);

		if ($border_style eq "dashed")
		{
			my $image_class   = $self->panel->image_class;
			my $gdTransparent = $image_class->gdTransparent;
			my $gdStyled      = $image_class->gdStyled;
		    $gd->setStyle($border_color,$border_color,$border_color,$gdTransparent,$gdTransparent);				
			$gd->rectangle( $b_left, $b_top, $b_right, $b_bottom, $gdStyled );				
		}
		else
		{
			$gd->rectangle( $b_left, $b_top, $b_right, $b_bottom, $border_color );				
		}  				
		
	}
	
	$gd->clip( 0, 0, $gd->width, $gd->height )
	  if ( !$gd->isa("GD::SVG::Image") );

	# draw label
	if ( $label ) {
		$self->draw_decoration_label( $gd, $dx, $dy, $mh, $h_top,
			$h_left, $h_bottom, $h_right, $label );
	}
}

sub _map_decoration {
	my $self = shift;
	my ( $gd, $dx, $dy, $mh, $nt_start, $nt_end ) = @_;
	
	my ( $left, $top, $right, $bottom ) = $self->bounds( $dx, $dy );

	my ( $h_left, $h_right ) =
	  $self->map_no_trunc( $nt_start, $nt_end + 1 );
	( $h_left, $h_right ) = ( $h_right, $h_left )
	  if ( $h_left > $h_right );
	$h_left += 1 if ($gd->isa("GD::SVG::Image"));
	$h_right = max($h_right-1, $h_left) if ($gd->isa("GD::SVG::Image"));
	my $h_top = $dy + $self->decoration_top($mh);
	my $h_bottom = $dy + $self->decoration_bottom($mh);

	return ($h_left, $h_top, $h_right, $h_bottom);
}

sub draw_decoration_label {
	my $self = shift;
	my ( $gd, $dx, $dy, $mh, $h_top, $h_left, $h_bottom, $h_right, $label ) = @_;

	warn "draw_decoration_label(): " . $self->feature . "\n" if (DEBUG == 2);

	my $font      = $self->labelfont;
	my $label_top = $h_top + ($self->decoration_height($mh)-$font->height)/2;
	my $label_pos = $self->decoration_label_position($mh);
	if ( $label_pos and $label_pos eq "above" ) {
		$label_top = $h_top - $font->height - 1;
	}
	elsif ( $label_pos and $label_pos eq "below" ) {
		$label_top = $dy + max($self->top+$self->height, $self->decoration_bottom($mh)) + ($gd->isa("GD::SVG::Image") ? 1 : 0);
	}

	my $label_color = $self->decoration_label_color($mh);

	$gd->clip( $h_left + 1, $label_top, $h_right - 1, $label_top + $font->height )
	  if ( !$gd->isa("GD::SVG::Image") and $label_pos eq "inside" );

	$gd->string( $font, $h_left + 2, $gd->isa("GD::SVG::Image") ? $label_top-1 : $label_top, $label, $self->factory->translate_color($label_color) );

	$gd->clip( 0, 0, $gd->width, $gd->height )
	  if ( !$gd->isa("GD::SVG::Image") );
}

1;

__END__

=head1 NAME

Bio::Graphics::Glyph::decorated_transcript - draws processed transcript with protein decorations

=head1 SYNOPSIS

  See L<Bio::Graphics::Panel> and L<Bio::Graphics::Glyph>.

=head1 DESCRIPTION

This glyph extends the functionality of the L<Bio::Graphics::Glyph::processed_transcript> glyph 
and allows protein decorations (e.g., signal peptides, transmembrane domains, protein domains)
to be drawn on top of gene models. Currently, the glyph can draw decorations in form of colored or outlined boxes 
inside or around CDS segments. Protein decorations are specified at the 'mRNA' transcript level 
in protein coordinates. Protein coordinates are automatically mapped to nucleotide coordinates by the glyph. 
Decorations are allowed to span exon-exon junctions, in which case decorations are split between exons. 
By default, the glyph automatically assigns different colors to different types of protein decorations, whereas 
decorations of the same type are always assigned the same color. 

Protein decorations are provided either with mRNA features inside GFF files (see example below) or 
dynamically via callback function using the B<additional_decorations> option (see glyph options).
The following line is an example of an mRNA feature in a GFF file that contains two protein decorations, 
one signal peptide predicted by SignalP and one transmembrane domain predicted by TMHMM:

C<chr1   my_source   mRNA  74796  75599   .  +  .  ID=rna_gene-1;protein_decorations=SignalP40:SP:1:23:0:my_comment,TMHMM:TM:187:209:0>

Each protein decoration consists of six fields separated by a colon:


=over

=item 1. type

Decoration type.  For example used to specify decoration source (e.g. 'SignalP40')

=item 2. name

Decoration name. Used as decoration label by default (e.g. 'SP' for signal peptide)

=item 3. start

Start coordinate at the protein-level (1-based coordinate)

=item 4. end

End coordinate at the protein-level

=item 5. score

Optional. Score associated with a decoration (e.g. Pfam E-value). This score can be used 
to dynamically filter or color decorations via callbacks (see glyph options).

=item 6. description

Optional. User-defined description of decoration. The glyph ignores this description, 
but it will be made available to callback functions for inspection. Special characters 
like ':' or ',' that might interfere with the GFF tag parser should be avoided. 

=back 

If callback functions are used as glyph parameters (see below), the callback is called for each
decoration separately. That is, the callback can get called multiple times for the same CDS feature,
but each time with a different active decoration. The currently drawn (active) decoration is made available 
to the callback via the glyph method 'active_decoration'. The active decoration is returned in form
of a Bio::Graphics::Feature object, with decoration data fields mapped to corresponding feature
attributes in the following way:

=over

=item * type --> $glyph->active_decoration->type

=item * name --> $glyph->active_decoration->name

=item * nucleotide start coordinate --> $glyph->active_decoration->start

=item * nucleotide end coordinate --> $glyph->active_decoration->end

=item * protein start coordinate --> $glyph->active_decoration->get_tag_values('p_start')

=item * protein end coordinate --> $glyph->active_decoration->get_tag_values('p_end')

=item * score --> $glyph->active_decoration->score

=item * description --> $glyph->active_decoration->desc

=back 

In addition, the glyph passed to the callback allows access to the parent glyph and
parent feature if required (use $glyph->parent or $glyph->parent->feature). 

NOTE: This glyph works only with GFF3 compliant features. In particular, make sure that
every feature has a valid unique ID and that all child features have a valid parent id.

=head2 OPTIONS

This glyph inherits all options from the L<Bio::Graphics::Glyph::processed_transcript> glyph. 
In addition, it recognizes the following glyph-specific options:

  Option          Description                                              Default
  ------          -----------                                              -------

  -decoration_visible                                                      false
  
                  Specifies whether decorations should be visible
                  or not. For selective display of individual 
                  decorations, specify a callback function and 
                  return 1 or 0 after inspecting the active decoration
                  of the glyph. 

  -decoration_color                                                        <auto>
  
                  Decoration background color. If no color is
                  specified, colors are assigned automatically by
                  decoration type and name, whereas decorations of 
                  identical type and name are assigned the same color.
                  A special color 'transparent' can be used here in 
                  combination with the option 'decoration_border' to 
                  draw decorations as outlines.
                            
  -decoration_border                                                       0 (none)
  
                  Decoration border style. By default, decorations are
                  drawn without border ('none' or 0). Other valid 
                  options here include 'solid' or 'dashed'.
                            
  -decoration_border_color                                                 black
  
                  Color of decoration border. 
                            
  -decoration_label                                                        true
                                                                           (decoration name)
                  Decoration label. If not specified, the second data
                  field of the decoration is used as label. Set this
                  option to 0 to get unlabeled decorations. If the label 
                  text extends beyond the size of the decorated segment, 
                  the label will be clipped. Clipping does not occur 
                  for SVG output.

  -decoration_label_position                                               inside
  
                  Position of decoration label. Labels can be drawn 
                  'inside' decorations (default) or 'above' and 'below'
                  decorations.
                  
  -decoration_label_color                                                  <auto>
  
                  Decoration label color. If not specified, this color 
                  is complementary to decoration_color (e.g., yellow text 
                  on blue background, white on black, etc.). If the 
                  decoration background color is transparent and no
                  decoration label color is specified, the foreground color 
                  of the underlying transcript glyph is used as default.

  -additional_decorations                                                  undefined
  
                  Additional decorations to those specified in the GFF file. 
                  Expected is a comma-separated string in the same format as 
                  described above for GFF files, for example
             
                    "SignalP40:SP:1:23:0:my_comment,TMHMM:TM:187:209:0"
              
                  This parameter is intended to be used as callback function,  
                  which inspects the currently processed transcript feature
                  (first parameter to callback) and returns additional protein
                  decorations that should be drawn. Alternatively, decorations 
                  not specified in the GFF file can also be added dynamically to 
                  feature objects before rendering using the add_tag_value()
                  method of the feature object. 

  -decoration_height                                                       CDS height-2
                  
                  Decoration height. Unless specified otherwise,
                  the height of the decoration is the height of the 
                  underlying transcript glyph minus 2, such that 
                  the decoration is drawn within transcript boundaries.

  -decoration_position                                                     inside
  
                  Vertical position of the decoration. If 'inside' is specified
                  (default), decorations are drawn inside CDS segments. 
                  Alternatively, a positive or negative integer value can be
                  specified, which will vertically offset the decoration by
                  the specified amount (in pixels) relative to the CDS segment.
                  Specifying 'stacked_bottom' will stack decorations below 
                  CDS segments in a non-overlapping manner (experimental).
                            
  -decoration_level                                                        CDS
  
                  Feature level at which decoration is drawn ('CDS' or 'mRNA'). 
                  By default, decorations are drawn at the 'CDS'
                  level, which means the decoration is only visible where it
                  overlaps with a coding sequence, skipping introns. 
                  Under some circumstances decorations should span introns, 
                  which can be achieved by specifying 'mRNA' here.
                  
  -box_subparts                                                            0 
                  
                  Same functionality as for basic glyph. Enables mouse-over
                  effects (tooltips and hyperlinks) for decorations via 
                  generation of image maps. Image maps for decorations will 
                  be generated if the level specified here exceeds the level
                  of the underlying glyph part. For example, if you specify
                  level 3, image maps will be generated for decorations of 
                  part level 1 (mRNA) and part level 2 (CDS). Note that this
                  option must be used in combination with -link and -title.

=head1 BUGS

Strandedness arrows are decorated incorrectly. Currently, the glyph plots a rectangular box 
over the arrow instead of properly coloring the arrow.

Overlapping decorations are drawn on top of each other without particular order. The only 
solution to this problem at this point is to reduce decorations to a non-overlapping
set. 

For SVG output or if drawn not inside decorations, decoration labels are not clipped.
Similar as for overlapping decorations, this can result in labels being drawn on top 
of each other. 

Please report all errors.

=head1 SEE ALSO

L<Bio::Graphics::Panel>,
L<Bio::Graphics::Glyph>,
L<Bio::Graphics::Glyph::decorated_gene>,
L<Bio::Graphics::Glyph::processed_transcript>

=head1 AUTHOR

Christian Frech E<lt>frech.christian@gmail.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut
