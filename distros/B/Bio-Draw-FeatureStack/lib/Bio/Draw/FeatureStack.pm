package Bio::Draw::FeatureStack;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.01';

use Bio::Graphics::Feature;
use Bio::Graphics::Panel;
use GD::SVG 0.32;  # minimum version 0.32 for correct color management (sub colorAllocateAlpha)
	
use List::Util qw[min max];

use base qw(Bio::Root::Root);

sub new
{
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
	    
	my %param = @args;
	my $features = $param{'-features'} or throw Bio::Root::BadParameter("gene models not specified");  # BioPerl feature array ref
	my $transcripts_to_skip = $param{'-transcripts_to_skip'}; # optional
	my $alt_feature_type = $param{'-alt_feature_type'}; # optional
	my $glyph = defined $param{'-glyph'} ? $param{'-glyph'} : "generic";
	my $alt_glyph = defined $param{'-alt_glyph'} ? $param{'-alt_glyph'} : "generic";
	my $glyph_params = defined $param{'-glyph_params'} ? $param{'-glyph_params'} : {};
	my $panel_params = defined $param{'-panel_params'} ? $param{'-panel_params'} : {};
	my $alt_glyph_params = defined $param{'-alt_glyph_params'} ? $param{'-alt_glyph_params'} : {};
	my $ignore_utr = $param{'-ignore_utr'};
	my $separator = $param{'-separator'};
	my $intron_size = $param{'-intron_size'};
	my $flip_minus = defined $param{'-flip_minus'} ? $param{'-flip_minus'} : 1;
	my $feature_offsets = $param{'-feature_offsets'};
	my $ruler = defined $param{'-ruler'} ? $param{'-ruler'} : 1;
	my $span = $param{'-span'}; # optional
				
	$self->{'features'} = $features;
	$self->{'transcripts_to_skip'} = $transcripts_to_skip;
	$self->{'glyph'} = $glyph;
	$self->{'alt_glyph'} = $alt_glyph;
	$self->{'glyph_params'} = $glyph_params;
	$self->{'panel_params'} = $panel_params;
	$self->{'alt_glyph_params'} = $alt_glyph_params;
	$self->{'alt_feature_type'} = $alt_feature_type;
	$self->{'ignore_utr'} = $ignore_utr;
	$self->{'separator'} = $separator;
	$self->{'intron_size'} = $intron_size;
	$self->{'flip_minus'} = $flip_minus;
	$self->{'feature_offsets'} = undef;
	$self->{'ruler'} = $ruler;
	$self->{'span'} = $span;

	# set glyph param defaults
	$glyph_params->{'-height'} = 12 if (!defined $glyph_params->{'-height'});

	my @glyph_params;
	map { push(@glyph_params, ($_, $self->{'glyph_params'}->{$_})) } keys(%{$self->{'glyph_params'}});
	$self->{'glyph_param_array'} = \@glyph_params;
		
	my @alt_glyph_params;
	map { push(@alt_glyph_params, ($_, $self->{'alt_glyph_params'}->{$_})) } keys(%{$self->{'alt_glyph_params'}});
	$self->{'alt_glyph_param_array'} = \@alt_glyph_params;

	my @panel_params;
	map { push(@panel_params, ($_, $self->{'panel_params'}->{$_})) } keys(%{$self->{'panel_params'}});
	$self->{'panel_param_array'} = \@panel_params;

	# feature transformation: adjust intron sizes, remove UTRs, flip if on negative strand, remove unwanted transcripts (isoforms)
	my @transformed_features;
	foreach my $feature (@{$features})
	{
		$self->throw("feature undefined") if (!defined $feature);
		
		my $transformed = $self->_transform_feature($feature);
		push(@transformed_features, $transformed);			

#		use Data::Dumper;
#		print Dumper($feature);
					
	}

	# calculate feature offsets if not left-aligned
	$self->_calc_feature_offsets(\@transformed_features, $feature_offsets)
		if (defined $feature_offsets);
			
	# determine coordinate span
	$span = $self->_calc_feature_span(\@transformed_features)
		if (!defined $self->{'span'}); 
	
	# align features
	my @aligned_features;
	for (my $i = 0; $i < @transformed_features; $i ++)
	{
		my $feature = $transformed_features[$i];
		
		my $fid = _get_id($feature);
		my $offset = (defined $self->{'feature_offsets'} and exists $self->{'feature_offsets'}->{$fid}) ? $self->{'feature_offsets'}->{$fid} : 0;
		print "$fid: feature offset=$offset\n" if ($offset and $self->debug);
		
		my $aligned_feature = $self->_align_feature
		(
			$feature, 
			-$feature->start+$offset+1
		);
		$self->throw("aligned_feature undefined: ".$feature->name."\n") if (!$aligned_feature);
		push(@aligned_features, $aligned_feature);
	}

	$self->{'aligned_features'} = \@aligned_features;
	$self->{'aligned_alt_features'} = $alt_feature_type ? $self->_get_alt_features(\@aligned_features) : []; 
		
	return bless($self, $class);
}

sub png
{
	my $self = shift;
	my %param = @_;
	my $image_map = defined $param{'-image_map'} ? $param{'-image_map'} : 0;
	
	my $panel = Bio::Graphics::Panel->new
	(
		-length    => $self->{'span'}+1,
		-key_style => 'between',
		@{$self->{'panel_param_array'}}
	);
	$self->_render_panel($panel);
	
	my $png = $panel->png;
	
	if ($image_map)
	{
		my $map = $panel->create_web_map();
		$panel->finished();
		return ($png, $map);
	}
	
	$panel->finished();
	return $png;
}

sub svg
{
	my $self = shift;
	my %param = @_;
	my $image_map = defined $param{'-image_map'} ? $param{'-image_map'} : 0;
	
	my $panel = Bio::Graphics::Panel->new
	(
		-image_class => "SVG",
		-length    => $self->{'span'}+1,
		@{$self->{'panel_param_array'}}
	);

	$self->_render_panel($panel);
	
	my $svg = $panel->gd;
	$svg = _consolidate_svg($svg);

	if ($image_map)
	{
		my $map = $panel->create_web_map();
		$panel->finished();
		return ($svg, $map);
	}
	
	$panel->finished();
	return $svg;
}

#---------------------------------------
# internal methods
#---------------------------------------
sub _get_alt_features
{
	my $self = shift;
	my $features = shift;
	
	my ($alt_type, $alt_source) = split(':', $self->{'alt_feature_type'});
	
	$self->throw("could not parse type of alternative feature: ".$self->{'alt_feature_type'})
		if (!$alt_type or !$alt_source);

	my @alt_features;	
	foreach my $feature (@$features)
	{
		my @afs = grep {$_->primary_tag eq $alt_type and $_->source eq $alt_source} $feature->get_SeqFeatures();
		foreach my $af (@afs)
		{
			my $dist = $self->_calc_start_dist($feature, $af);
			$af->add_tag_value('start_dist', $dist);
			
		}
		push(@alt_features, \@afs);
	}	
	
	return \@alt_features;
}

# computes distance of alternative feature (e.g. DNA-binding site) to start of nearest transcript, in bp
sub _calc_start_dist
{
	my $self = shift;
	my $f = shift;
	my $af = shift;
	
	return $af->start-$f->start
		if ($f->primary_tag eq 'mRNA');

	my @transcripts = grep {$_->primary_tag eq 'mRNA'} $f->get_SeqFeatures();
	if (@transcripts == 0)
	{
		print "WARNING: No transcripts found for feature $f (".$f->name.")\n" if ($self->debug);
		return undef;
	}	
		
	my $nearest_transcript;
	foreach my $t (@transcripts)
	{
		$nearest_transcript = $t
			if (!$nearest_transcript or abs($af->start-$nearest_transcript->start)>abs($af->start-$t->start));
	}
	
	return $af->start-$nearest_transcript->start;
}

# removes UTRs, shrinks introns, flip negative strand, remove unwanted transcripts (isoforms)
sub _transform_feature
{
	my $self = shift;
	my $feature = shift;
	my $exon2cds = shift;  # if true, transform exon into cds features
	
	my @transcripts;
	if ($feature->primary_tag eq 'gene')
	{
		# fixed intron size mode currently only functional with mRNA features (not promoters)
		if ($self->{'intron_size'})
		{
			push(@transcripts, grep {$_->primary_tag =~ /mRNA/i} $feature->get_SeqFeatures());		
		}
		else
		{
			push(@transcripts, $feature->get_SeqFeatures());					
		}
	}
	elsif ($feature->primary_tag eq 'mRNA')
	{
		push(@transcripts, $feature);
	}
	else
	{
		$self->throw("invalid feature type: ".$feature->primary_tag);
	}
	
	# remove unwanted isoforms
	my %transcripts_to_skip;
	map {$transcripts_to_skip{$_} = 1} @{$self->{'transcripts_to_skip'}}
		if ($self->{'transcripts_to_skip'});
		
	@transcripts = grep {!$transcripts_to_skip{_get_id($_)}} @transcripts;
	
	my @shifted_transcripts;
	foreach my $transcript (@transcripts)
	{
		my $shift_by = 0;
		my $last_end;
		my @shifted_parts;
		my @parts;
		
		if ($exon2cds)
		{
			 	@parts = sort {$a->start <=> $b->start} grep {$_->primary_tag =~ /exon/i} $transcript->get_SeqFeatures();						
		}
		else
		{
			if ($self->{'ignore_utr'})
			{
			 	@parts = sort {$a->start <=> $b->start} grep {$_->primary_tag !~ /utr/i} $transcript->get_SeqFeatures();			
			}
			else
			{
			 	@parts = sort {$a->start <=> $b->start} $transcript->get_SeqFeatures();
			}
		}
		
		$self->throw("not subfeature found for transcript "._get_id($transcript)."\n") 
			if ($transcript->primary_tag eq 'mRNA' and @parts == 0);
			
		foreach my $part (@parts)
		{
			if ($self->{'intron_size'} and $part->primary_tag =~ /utr|cds|exon/i)
			{
#				print "shift_by=$shift_by\n" if ($self->debug);
				if (defined $last_end)
				{
					my $intron_size = $part->start-$last_end;
					$shift_by += $intron_size - $self->{'intron_size'} if ($intron_size > 1);  # shift by difference to maximum allowed intron size
				}				
				$last_end = $part->end;
			}
							
			my ($f, $id) = $self->_clone_feature
			(
				$part, 
				($self->{'flip_minus'} and $feature->strand < 1) ? $feature->start + $feature->end - $part->end + $shift_by : $part->start - $shift_by, 
				($self->{'flip_minus'} and $feature->strand < 1) ? $feature->start + $feature->end - $part->start + $shift_by : $part->end - $shift_by,
				$self->{'flip_minus'} ? 1 : undef,
				$exon2cds
			);		
			push(@shifted_parts, $f);
		}
				
		@shifted_parts = sort {$a->start <=> $b->start} (@shifted_parts);
		my ($shifted_transcript, $id) = $self->_clone_feature
		(
			$transcript, 
			@shifted_parts > 0 ? $shifted_parts[0]->start 
							   : ($self->{'flip_minus'} and $feature->strand < 1) ? $feature->start + $feature->end - $transcript->end 
							   													: $transcript->start, 
			@shifted_parts > 0 ? $shifted_parts[@shifted_parts-1]->end 
							   : ($self->{'flip_minus'} and $feature->strand < 1) ? $feature->start + $feature->end - $transcript->start 
							                                                      : $transcript->end,
			$self->{'flip_minus'} ? 1 : undef,
			$exon2cds			
		);
		foreach my $c (@shifted_parts)
		{
			$shifted_transcript->add_SeqFeature($c);
		}
		push(@shifted_transcripts, $shifted_transcript);
	}

	if ($feature->primary_tag eq 'gene')
	{
		@shifted_transcripts = sort {$a->start <=> $b->start} (@shifted_transcripts);
		my ($gene, $id) = $self->_clone_feature
		(
			$feature, 
			$shifted_transcripts[0]->start,
			$shifted_transcripts[@shifted_transcripts-1]->end, 
			$self->{'flip_minus'} ? 1 : undef,
			$exon2cds
		);
		foreach my $i (@shifted_transcripts)
		{
			$gene->add_SeqFeature($i);
		}
		return $gene;
	}
	
	return $shifted_transcripts[0];
}

sub _get_id
{
	my $feature = shift;
	
	my $id;
	($id) = $feature->get_tag_values('ID') if ($feature->has_tag('ID'));
	($id) = $feature->get_tag_values('load_id') if (!$id and $feature->has_tag('load_id'));
	$id = $feature->id if (!$id and $feature->can('id'));
	$id = $feature->seq_id.":".$feature->start."..".$feature->end if (!$id);
	
	return $id;
}

sub _calc_feature_span
{
	my $self = shift;
	my $features_ref = shift;

	my $max_span = 0;
	foreach my $feature (@$features_ref)
	{
		next if (!defined $feature);
  		my $span = abs($feature->end - $feature->start + 1);
  		my $fid = _get_id($feature);	
		$span +=  $self->{'feature_offsets'}->{$fid} 
			if (defined $self->{'feature_offsets'} and exists $self->{'feature_offsets'}->{$fid});	
		$max_span = $span if ($span > $max_span);		
	}

	print "feature span: $max_span\n" if ($self->debug);
	$self->{'span'} = $max_span;

	return $max_span;	
}

sub _calc_feature_offsets
{
	my $self = shift;
	my $features_ref = shift;
	my $feature_offsets = shift;

	# user-defined feature offsets? 
	if (ref($feature_offsets) eq "HASH")
	{
		$self->{'feature_offsets'} = $feature_offsets;
	}
	else
	{
		my @features = @$features_ref;
		$self->{'max_offset'} = 0;
		my %f_offset;
				
		# determine maximum offset by decoration position
		foreach my $feature (@$features_ref)
		{
			my $fid = _get_id($feature);
			my @transcripts;
			if ($feature->primary_tag eq 'gene')
			{
				push(@transcripts, grep {$_->primary_tag eq 'mRNA'} $feature->get_SeqFeatures());
			}
			else
			{
				push(@transcripts, $feature);
			}
	
			foreach my $t (@transcripts)
			{
				if ($feature_offsets eq "start_codon") 
				{
					# align by start codon
					my @cds = sort {$a->start <=> $b->start} grep {$_->primary_tag eq 'CDS'} $t->get_SeqFeatures();
					@cds = sort {$a->start <=> $b->start} grep {$_->primary_tag eq 'exon'} $t->get_SeqFeatures() if (@cds == 0);
					$f_offset{$fid} = $cds[0]->start-$feature->start
						if (!defined $f_offset{$fid} or $f_offset{$fid} > $cds[0]->start-$feature->start);
				}
				elsif (defined $feature_offsets)
				{
					# align features by decoration
					# requires Bio::Graphics::Glyph::decorated_transcript for coordinate mapping
					use Bio::Graphics::Glyph::decorated_transcript;
					
					my @decorations = Bio::Graphics::Glyph::decorated_transcript::get_decorations_as_features($t);
					foreach my $decoration (@decorations)
					{
						next if ($decoration->name ne $feature_offsets);
						$f_offset{$fid} = $decoration->start - $feature->start; 
					}																			
				}
				$self->{'max_offset'} = $f_offset{$fid} if ($f_offset{$fid} > $self->{'max_offset'});
			}
		}
		
		# set offset for transcripts with this decoration
		foreach my $f_id (keys(%f_offset))
		{
			$self->{'feature_offsets'}{$f_id} = $self->{'max_offset'} - $f_offset{$f_id}; 
		}
	}	
}

sub _align_feature
{
	my $self = shift;
	my $feature = shift or throw Bio::Root::BadParameter("feature not specified");
	my $offset = shift;
	my $parent_id = shift;  # internal parameter for recursive calls

	$self->throw("offset not specified") 
		if (!defined $offset);

	my ($start, $end) = ($feature->start, $feature->end);	
	my ($aligned_feature, $id) = $self->_clone_feature($feature, $start + $offset, $end + $offset);	
	$parent_id = $id if (!$parent_id);
#	$aligned_feature->add_tag_value('parent_id', $parent_id) if ($parent_id);	

	# copy subfeatures recursively
	foreach my $subfeature ($feature->get_SeqFeatures())
	{
		$aligned_feature->add_SeqFeature
		(
			$self->_align_feature($subfeature, $offset, $parent_id) 
		);
	}

	return $aligned_feature;
}

sub _clone_feature
{
	my $self = shift;
	my $feature = shift;
	my $start = shift;
	my $end = shift;
	my $strand = shift;
	my $exon2cds = shift;
	
	my $clone = Bio::Graphics::Feature->new
	(
		-name => ($feature->can("display_name") and $feature->display_name)
				 ? $feature->display_name 
				 : ($feature->can("name") and $feature->name) 
				   ? $feature->name
				   : (ref($feature) eq "Bio::Seq::RichSeq" and $feature->can("seq") and $feature->seq) # special case for features loaded from genbank entries
				     ? $feature->seq->accession_number
				     : "",
		-seq_id => $feature->seq_id,
		-source => $feature->can('source_tag') ? $feature->source_tag : $feature->source,
		-primary_tag => ($exon2cds and $feature->primary_tag eq 'exon') ? 'CDS' : $feature->primary_tag,
		-start => $start ? $start : $feature->start,
		-end => $end ? $end : $feature->end,
		-score => $feature->score,
		-strand => defined $strand ? $strand : $feature->strand,
		-frame => $feature->can('phase') ? $feature->phase : "",
		-phase => $feature->can('phase') ? $feature->phase : ""
	);			

	# copy tags
	foreach my $tagname ($feature->get_all_tags())
	{
		next if (uc($tagname) eq 'LOAD_ID');
#		next if (uc($tagname) eq 'NAME');
#		next if (uc($tagname) eq 'PARENT_ID');
		next if (uc($tagname) eq 'ID');
		foreach my $value ($feature->get_tag_values($tagname))
		{
			$clone->add_tag_value($tagname, $value);
		}
	}

	# add description for genbank/embl entries, depending on which information is available
	$clone->add_tag_value('Note', $clone->get_tag_values("product"))
		if (!$clone->has_tag("Note") and !$clone->has_tag("note") and $clone->has_tag("product"));
	$clone->add_tag_value('Note', $clone->get_tag_values("gene"))
		if (!$clone->has_tag("Note") and !$clone->has_tag("note") and $clone->has_tag("gene"));
	$clone->add_tag_value('Note', $feature->seq->desc)
		if (!$clone->has_tag("Note") and !$clone->has_tag("note") and ref($feature) eq "Bio::Seq::RichSeq" and $feature->can("seq") and $feature->seq and $feature->seq->desc);
		
	my $id = _get_id($feature);
	$clone->add_tag_value('ID', $id) if ($id);

	return ($clone, $id);	
}

sub _render_panel
{
	my $self = shift;
	my $panel = shift;

	# add ruler (or spacer)
	if ($self->{'ruler'})
	{
		$panel->add_track
		(
			Bio::Graphics::Feature->new(-start => 1, -end => $self->{'span'}),
			-glyph  => 'arrow',
			-fgcolor => 'black',
			-bump   => 0,
			-double => 1,
			-tick   => 2,
			-relative_coords => $self->{'max_offset'} ? 1 : 0,
			-relative_coords_offset => $self->{'max_offset'} ? -$self->{'max_offset'} : undef
		);		
	}
	else
	{
		$panel->add_track
		(
			Bio::Graphics::Feature->new(-start => 0, -end => 0),
			-glyph  => 'segments',
			-fgcolor => 'white',
			-height => 19
		);				
	}

	# add tracks for all features
	for (my $i = 0; $i < @{$self->{'aligned_features'}}; $i ++)
	{
		# render track with alternative feature above main track (if specified)
		my $alt_f = $self->{'aligned_alt_features'}->[$i];
		if ($alt_f)
		{
			$panel->add_track
			(
				$alt_f,
				-glyph => $self->{'alt_glyph'},
				@{$self->{'alt_glyph_param_array'}}
			);						
		}		

		# add main feature track
		my $f = $self->{'aligned_features'}->[$i];
		print "adding track ".$f->name."\n" if ($self->debug);		
		$panel->add_track
		(
			$f,
			-glyph => $self->{'glyph'},
			@{$self->{'glyph_param_array'}}
		);
		
		# separator
		if ($self->{'separator'} and $i < @{$self->{'aligned_features'}}-1)
		{	
			$panel->add_track
			(
				Bio::Graphics::Feature->new(-start => 1, -end => $self->{'span'}),
				-glyph  => 'line',
				-height => 1,
				-fgcolor => 'black',
				-bgcolor => 'black'
			);
		}		
	}	
}

# agreed, this is a bit of a hack to fix font alignment problems, but GBrowse does the same
# see GBrowse/cgi-bin/gbrowse_img
sub _consolidate_svg
{
	my $g = shift;

	my $height    = ($g->getBounds)[1];
	my $width    += ($g->getBounds)[0];

    my $image_height = $height;
    
    my $svg = qq(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n\n);
    $svg   .= qq(<svg height="$image_height" width="$width" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">\n);

	my $offset = 0;
    my $s = $g->svg;
    my $current_width = 0;
    foreach (split "\n",$s) {
		if (m!</svg>!) {
		    last;
		}
		elsif (/<svg.+width="([\d.]+)"/) {
		    $current_width = int($1+0.5);
		    my $height     = $height - ($g->getBounds)[1];
			    $svg .= qq(<g transform="translate($offset,$height)">\n);
		}
		elsif ($current_width) {
		    $svg .= "$_\n";
		}
	}
	$svg .= "</g>\n" if $current_width;
	$offset += $current_width;
	$svg   .= qq(</svg>\n);

    # munge fonts slightly for systems that don't have Helvetica installed
    $svg    =~ s/font="Helvetica"/font="san-serif"/gi;
    $svg    =~ s/font-size="11"/font-size="9"/gi;  
    $svg    =~ s/font-size="13"/font-size="12"/gi;  

    return $svg;	
}


1;

__END__

=head1 NAME

Bio::Draw::FeatureStack - BioPerl module to generate GD images of stacked gene models

=head1 SYNOPSIS

  use Bio::DB::SeqFeature::Store;
  use Bio::Draw::FeatureStack;
 
  # load GFF3-compliant features from GFF file 
  # features could be obtained from/with any other source/methods as well...
  #---
  my @features;
  my $store = Bio::DB::SeqFeature::Store->new
  (
    -adaptor => 'memory',
    -dsn => 'my_gff_file.gff3' 
  );    			
  push(@features, $store->features(-name => 'gene1', -aliases => 1));
  push(@features, $store->features(-name => 'gene2', -aliases => 1));

  # create FeatureStack, passing features as array-ref
  #---
  my $feature_stack = new Bio::Draw::FeatureStack
  (
    -features => \@features,    # array-ref of features to be rendered
    -glyph => 'gene',           # features will be rendered using this BioPerl glyph
    -flip_minus => 1,           # flip features on reverse strand (default is on)
    -ignore_utr => 1,           # do not show UTRs (default is off)
    -panel_params => {          # Bio::Graphics::Panel parameters
      -width => 1024,          
      -pad_left => 80,
      -pad_right => 20,
      -grid => 1
    },
    -glyph_params => {          # glyph-specific parameters (Bio::Graphics::Glyph::gene in this case)
      -utr_color   => 'white',
      -label_position => 'left',
      -label_transcripts => 1,
      -description => 1
    }
  );

  # output SVG, including HTML image map
  #---
  (my $svg, $map) = $feature_stack->svg(-image_map => 1);
	
  # output PNG
  #---
  my $png = $feature_stack->png;
	
=head1 DESCRIPTION

FeatureStack creates GD images of vertically stacked gene models to facilitate visual comparison
of gene structures. Compared genes can be clusters of orthologous genes,
gene family members, or any other genes of interest. FeatureStack takes an array of BioPerl
feature objects as input, projects them onto a common coordinate space, flips features 
from the negative strand (optional), left-aligns them by start coordinates (optional), sets a 
fixed intron size (optional), removes unwanted transcripts (optional), and then draws the 
so transformed features with a user-specified glyph. Internally, this transformation is
achieved by cloning all input features into L<Bio::Graphics::Feature> objects before the
features get rendered by the specified glyph. Output images can be generated in SVG 
(scalable vectorized image) or PNG (rastered image) format. 

FeatureStack was designed with the goal to retain maximum control of the rendering 
process. As such, the user can not only control how FeatureStack behaves using the 
FeatureStack parameters described below, but also can provide both panel- and glyph-specific 
parameters to fine-control all aspects of the rendered image. 

Albeit FeatureStack can be used in combination with any glyph, it is particularly useful
when used in combination with the L<Bio::Graphics::Glyph::decorated_gene> glyph. This glyph is 
currently not distributed with BioPerl, but should install together with FeatureStack. 
L<Bio::Graphics::Glyph::decorated_gene> can also be used and obtained independent from 
FeatureStack via CPAN. The decorated_gene glyph allows to highlight protein motifs such as 
signal peptides, transmembrane domains, or protein domains on top of gene models, 
which greatly faclitates the comparison of gene structures. Please refer to the documentation
of L<Bio::Graphics::Glyph::decorated_gene> for more details. If protein decorations are associated 
with gene features in the input data, FeatureStack can also automatically align gene models 
by a user-defined decoration type, such that for example gene models are aligned by a 
particularly well conserved protein motif. 

FeatureStack requires GFF3-complient features. That is, features provided to
FeatureStack need to have either a two-tier 'mRNA'->'CDS' or three-tier 'gene'->'mRNA'->'CDS' 
level structure. Here is an example gene structure in GFF3 format compatible with FeatureStack:

   MAL10  test  gene  1596486  1597604  .  +  .  ID=PF10_0392;Name=PF10_0392
   MAL10  test  mRNA  1596486  1597604  .  +  .  ID=rna_PF10_0392-1;Name=PF10_0392-1;Parent=PF10_0392
   MAL10  test  CDS   1596486  1596554  .  +  .  ID=cds_PF10_0392-1;Parent=rna_PF10_0392-1
   MAL10  test  CDS   1596747  1597604  .  +  .  ID=cds_PF10_0392-2;Parent=rna_PF10_0392-1

FeatureStack can display multiple transcripts (isoforms) per gene if the specified 
glyph supports this as well (for example the 'gene' or the 'decorated_gene' glyph).

In addition to drawing a set of gene models on top of each other, FeatureStack can intermingle
gene models with alternative tracks that display additional features associated with these genes. 
This can be used for example to display regulatory elements or sequence variants (SNPs, indels)
alongside gene model. There is currently no limitation of how these alternative features 
are displayed, and any BioPerl glyph can be used for this purpose. In the input data, alternative 
features must be specified one level below the gene or transcript feature that is passed to
FeatureStack. Here is an example GFF that shows how a regulatory motif (associated with the gene)
and a SNP (associated with a transcript) can be specified:

   CHR_I  test  gene      5100769  5101677  .  +  .  ID=Gene:Y110A7A.20;Name=ift-20
   CHR_I  test  promoter  5100709  5100722  .  +  .  ID=Promoter:Y110A7A.20;Note=GTCTCTATAGCAAC;Parent=Gene:Y110A7A.20
   CHR_I  test  mRNA      5100769  5101677  .  +  .  ID=Transcript:Y110A7A.20;Parent=Gene:Y110A7A.20
   CHR_I  test  SNP       5100888  5100888  .  +  .  ID=SNP123456;Parent=Transcript:Y110A7A.20;Note=C>T
   CHR_I  test  CDS       5100769  5101423  .  +  .  ID=CDS:Y110A7A.20:1;Parent=Transcript:Y110A7A.20
   CHR_I  test  CDS       5101468  5101677  .  +  .  ID=CDS:Y110A7A.20:2;Parent=Transcript:Y110A7A.20

=head2 OPTIONS

  Option          Description                                              Default
  ------          -----------                                              -------

 -features                                                                 none
  
                  Array reference (mandatory). BioPerl features to be 
                  displayed. Currently, features can be either of type 
                  'mRNA' or 'gene'. 
                  
  -glyph                                                                   'generic'

                  String (optional). Name of glyph to be used to render 
                  features. The glyph specified here should be suitable 
                  for rendering the provided features (e.g., use 
                  'processed_transcript' glyph for features of type 'mRNA' 
                  and 'gene' glyph for features of type 'gene'). The 
                  'decorated_gene' or 'decorated_transcript' glyph 
                  can also be used for highlighting protein features on 
                  top of gene models (see description above). 
                  
                  If no glyph is specified, the 'generic' glyph will 
                  be used.
                  
  -glyph_params                                                            none

                  Hash reference (optional). Glyph-specific parameters. 
                  Will be passed unmodified to the glyph. Parameters 
                  can include callback functions for fine-grained control 
                  of the rendering process. Please refer to the
                  documentation of the glyph for a description of which
                  glyph parameters are available. 

  -panel_params                                                            none

                  Hash reference (optional). Panel parameters. Will be 
                  passed unmodified to the L<Bio::Graphics::Panel> instance 
                  that is internally created by FeatureStack.  

                  Typical parameters here include -width, -pad_left, 
                  -pad_right, or -grid (see L<Bio::Graphics::Panel> for
                  more information).

  -ignore_utr                                                              false
  
                  Boolean (optional). If true, gene models will be drawn
                  without untranslated regions (UTRs).
                  
  -flip_minus                                                              true
  
                  Boolean (optional). By default, features on the negative
                  (reverse) strand are drawn flipped, such that the 
                  5' end of features is always on the left side. This 
                  behaviour can be turned off by setting this parameter to
                  0 (false).

  -intron_size                                                             undef
  
                  Integer (optional). Intron size in base-pairs. If specified, 
                  introns of gene models will be transformed to have 
                  this specified size. This is useful when comparing gene 
                  models of vastly different sizes due to very large
                  introns (for example, when comparing protist genes with human 
                  genes). By default, gene models are drawn to scale with
                  original intron sizes. This parameter does not affect
                  the length of exons, which are always drawn to scale.
                  
  -feature_offsets                                                         undef
  
                  Hash reference or string (optional). This parameter allows 
                  you to control the horizontal alignment of features. By
                  default, all features are left-aligned by their start
                  coordinate.  
                  
                  If a hash reference is specified here, it is assumed that
                  keys correspond to feature IDs and values to offsets in bp. 
                  This way the alignment of individual features can be 
                  manually fine-controlled. 
                  
                  If 'start_codon' is specified, features will be aligned
                  by their smallest CDS coordinate, assuming that this
                  will be the translation start site.
                  
                  Any other value here will be interpreted as the name of
                  a protein decoration. In this case, FeatureStack will
                  attempt to use L<Bio::Graphics::Glyph::decorated_transcript>
                  to map this protein decoration to nucleotide space and 
                  will then left-align the feature by this mapped 
                  coordinate. This way, features can for example be 
                  automatically aligned by their most conserved protein 
                  domain. If no protein decoration with this name is found
                  for a feature, then this feature will not be aligned.
                  Please refer to the documentation of the 
                  decorated_transcript glyph to see how protein decorations
                  can be specified for transcripts.

  -transcripts_to_skip                                                     none

                  Array reference (optional). Contains transcript IDs not to
                  be included in the output image. This parameter can be used
                  if a gene feature passed to FeatureStack has multiple 
                  isoforms but only a subset of these isoforms should appear
                  in the output.
  
  -alt_feature_type                                                        none

                  String (optional). Type and source of alternative features 
                  (e.g., 'SNP:mpileup') to be outputted alongside gene models. 
                  FeatureStack looks for features of this type/source one
                  level below the specified gene/transcript feature. If found, 
                  alternative features are drawn in a separate track above 
                  the gene track. The appearance of alternative features 
                  can be controlled using the -alt_glyph and -alt_glyph_params 
                  parameters.
                  
                  FeatureStack will automatically compute the distance of
                  alternative features (in bp) to the associated main features's 
                  start coordinate and adds this distance as a feature tag
                  (tag name 'start_dist'). This tag can later be read 
                  by the glyph that displays alternative features. 
                  This can e.g. be useful for labeling regulatory features 
                  with their distance from the transcription start site 
                  (UTRs visible) or from the translation start site 
                  (UTRs ignored).
                  
  -alt_glyph                                                               none
   
                  String (optional). Name of glyph to be used to draw 
                  alternative features specified with -alt_feature_type.

  -alt_glyph_params                                                        none

                  Hash reference (optional). Glyph-specific parameters for 
                  glyph specified with -alt_glyph. Parameters will be passed 
                  unmodified to the glyph. Parameters can include callback 
                  functions for fine-grained control of the rendering process. 

  -ruler                                                                   true

                  Boolean (optional). If true, a ruler indicating distances
                  in base-pairs will be drawn on top of the image. The ruler
                  will automatically adjust to feature offsets; that is,
                  the origin of the ruler will be placed at the
                  point where features are align, showing negative 
                  coordinates left of this point and positive coordinates 
                  right of this point. 

  -span                                                                    [auto]

                  Integer (optional). Span of the output image in bp. By 
                  default, the span is the length of the longest feature. 
                  If one wants to generate an image that shows only the 
                  5' portion of features (for example to visualize only 
                  the first exon of genes and their associated promoters), 
                  one can set a smaller, fixed value here, effectively 
                  clipping the right part of the image at this coordinate.

  -separator                                                               false

                  Boolean (optional). If true, draw horizontal line between
                  gene models. This might be useful if alternative tracks
                  are visible to know which alternative track belongs to
                  which gene model track. 
                  
=head2 EXPORT

None by default.

=head1 BUGS

Please report all errors.

=head1 SEE ALSO

L<Bio::Graphics::Panel>,
L<Bio::Graphics::Glyph>,
L<Bio::Graphics::Glyph::gene>,
L<Bio::Graphics::Glyph::processed_transcript>,
L<Bio::Graphics::Glyph::decorated_gene>,
L<Bio::Graphics::Glyph::decorated_transcript>,
L<Bio::DB::SeqFeature::Store>

It is recommended to study test cases shipped with this module 
to get additional information of how to use this module.
 
=head1 AUTHOR

Christian Frech E<lt>frech.christian@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Christian Frech

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
