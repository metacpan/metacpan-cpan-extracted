package Chromosome::Map;

use strict;
use GD;

use Chromosome::Map::Track;

use constant FONT_MEDIUM	=> 'gdMediumBoldFont';
use constant FONT_SMALL		=> 'gdSmallFont';
use constant FONT_TINY		=> 'gdTinyFont';

use constant PAD_TOP	=> 20;
use constant PAD_BOTTOM	=> 40;
use constant PAD_LEFT	=> 20;
use constant PAD_RIGHT	=> 20;

use constant CHR_WIDTH 	  => 6;
use constant CHR_PAD_LEFT => 40;
use constant CHR_PAD_TOP  => 30;
use constant PAD_SCALE	  => 20;		# pixel interval for chromosome scale display

our $VERSION = '0.01';

#-------------------------------------------------------------------------------
# public methods
#-------------------------------------------------------------------------------

sub new {
	my $class = shift;
	$class = ref($class) || $class;
	
	my %Options = @_;
	my $self = {};
	$self->{_name}     = $Options{-name};
	$self->{_size}     = $Options{-length};
	$self->{_start}    = $Options{-start} || 0;
	$self->{_units}    = $Options{-units};
	$self->{_height}   = $Options{-height};
	$self->{_width}    = 0; 						# AUTO
	# define padding, could override
	$self->{_pad_left}   = $Options{-pad_left} 	 || PAD_LEFT;
	$self->{_pad_right}  = $Options{-pad_right}  || PAD_RIGHT;
	$self->{_pad_top}    = $Options{-pad_top} 	 || PAD_TOP;
	$self->{_pad_bottom} = $Options{-pad_bottom} || PAD_BOTTOM;
	$self->{_tracks}   = {};
	$self->{_ident_track} = 0;
	bless $self,$class;
	return $self;
}

sub get_map_name {
	my $self = shift;
	return $self->{_name};
}

sub get_map_start {
	my ($self) = @_;
	return $self->{_start};
}

sub get_map_size {
	my ($self) = @_;
	return $self->{_size};
}

sub get_map_units {
	my ($self) = @_;
	return $self->{_units};
}

sub get_nb_tracks {
	my ($self) = @_;
	return keys ( %{$self->{_tracks}});
}

sub get_list_track {
	my ($self) = @_;
	my %List = %{$self->{_tracks}};
	return %List;
}

sub add_track {
	# the indice number is automatically increment
	# the first track added will have an indice number of 1
	# in case of adding FEATURE track, the indice number will be set to 0
	# as this track must be the first closest to chr
	# NOTE: only ONE feature track can be added to a map
	my ($self,$track) = @_;
	my $indice = $self->_inc_track_ident;
	
	# set indice value to 0 if track type = feature
	# DO NOT add another feature track if exists
	if ($track->get_track_type eq 'feature') {
		$indice = 0;
		return 0 if ($self->{_tracks}->{$indice});
	}
	$self->{_tracks}->{$indice} = $track;
	$track->{_size}  = $self->get_map_size;
	$track->{_start} = $self->get_map_start;
	return 1;
}

sub png {
  my $gd = shift->_gd;
  $gd->png;
}

sub svg {
  my $gd = shift->_gd;
  $gd->svg;
}


#-------------------------------------------------------------------------------
# private methods
#-------------------------------------------------------------------------------

sub _get_track_ident {
	my $self = shift;
	return $self->{_ident_track};
}

sub _inc_track_ident {
	my $self = shift;
	my $ident = $self->_get_track_ident;
	$ident++;
	$self->{_ident_track} = $ident;
	return $ident++;
}

sub _scale {
	# give the value of chromosomal unit for 1 px
	my $self = shift;
	$self->{_scale} = $self->_get_chr_length / ($self->get_map_size - $self->get_map_start);
}

sub _get_chr_length {
	# return the pixel value available for chr drawing
	my $self = shift;
	my $chr_length = $self->_height - (PAD_TOP + PAD_BOTTOM + CHR_PAD_TOP);
	return $chr_length;
}

sub _locate_element {
	# return the y-axis pixel value for one element
	# i.e element at 24.9 cM will have an y value = 340 px
	my ($self,$value) = @_;
	my $y = $self->_get_y_top + ( ($value - $self->get_map_start) * $self->_scale);
	return $y;
}

sub _get_map_width {
	# use each x_bound track value to calculate final image width
	my $self = shift;
	my %Track = $self->get_list_track;
	my $img_width;
	foreach my $num (sort {$a <=> $b} keys %Track) {
		my $track = $Track{$num};
		$img_width += $track->_get_xbound;
	}
	return $img_width;
}

sub _is_extra_bottom_padding {
	# search the maximum value of extra_bottom_padding
	my $self = shift;
	my %Track = $self->get_list_track;
	my $extra_padding = 0;
	foreach my $num (sort {$a <=> $b} keys %Track) {
		my $track = $Track{$num};
		$extra_padding = $track->_get_extra_bottom_padding if ($track->_get_extra_bottom_padding > $extra_padding);
	}
	return $extra_padding;	
}

sub _height {
	my $self = shift;
	return $self->{_height};
}

sub _pad_left {
	my $self = shift;
	return $self->{_pad_left};
}

sub _pad_right {
	my $self = shift;
	return $self->{_pad_right};
}

sub _pad_top {
	my $self = shift;
	return $self->{_pad_top};
}

sub _pad_bottom {
	my $self = shift;
	return $self->{_pad_bottom};
}

sub _get_y_top {
	my $self = shift;
	return ($self->_pad_top + CHR_PAD_TOP);
}

sub _get_y_bottom {
	my $self = shift;
	return ($self->_height - $self->_pad_bottom);
}

sub _get_screen_size_ratio {
	# return a "printable" size ratio
	my $self = shift;
	my $size = $self->get_map_size;
	my $screen_size = 1;
	
	$screen_size = 1000 if ($size > 10_000);
	$screen_size = 1_000_000 if ($size > 10_000_000);
	return $screen_size;
}

sub _gd {
	use constant TRACK_PAD       => 3;
	use constant CHR_WIDTH_TRACK => 70;
	
	my $self = shift;

	# Define the choosen font size using constant name
	my $font_size_medium = FONT_MEDIUM;
	my $font_size_small  = FONT_SMALL;
	my $font_size_tiny   = FONT_TINY;
	my $font_medium = GD->$font_size_medium;
	my $font_small  = GD->$font_size_small;
	my $font_tiny   = GD->$font_size_tiny;

	# first render tracks
	my %Track_list = $self->get_list_track;
	foreach my $num (sort {$a <=> $b} keys %Track_list) {
		my $track = $Track_list{$num};
		$track->_render_track($self);
	}

	# defined Y0 and Ymax (map limits)
	my $y_chr_top    = $self->_get_y_top;
	my $y_chr_bottom = $self->_get_y_bottom;
	my $x_chr = $self->_pad_left + CHR_PAD_LEFT;
	
	# create final image
	my $width = CHR_WIDTH_TRACK + $self->_get_map_width + $self->_pad_left;
	my $height = $self->_height + $self->_is_extra_bottom_padding;
	my $img = GD::Image->new($width,$height);

	# adding each IMG track to final IMG
	my $x_track = $x_chr + CHR_WIDTH + 1;
	foreach my $num (sort {$a <=> $b} keys %Track_list) {
		my $track   = $Track_list{$num};
		my $gd      = $track->_get_gd;
		my $x_bound = $track->_get_xbound;
		$x_track += TRACK_PAD if ($track->get_track_type ne 'feature');
		$img->copy ($gd, $x_track, 0, 0, 0, $x_bound, $height);
		$x_track += $x_bound;
	}
	
	# get images scale (unit per pixel)
	my $scale = $self->_scale;
	
	# colors definition
	my $black = $img->colorAllocate(0,0,0);
	my $white = $img->colorAllocate(255,255,255);
	
	$img->fill(0,0,$white);
	
	# write map name and draw CHR rectangle
	my $screen_name = $self->get_map_name." (".$self->get_map_units.")";
	$img->string($font_medium, $self->_pad_top, $self->_pad_left,$screen_name, $black);
	$img->filledRectangle($x_chr, $y_chr_top, $x_chr+CHR_WIDTH, $y_chr_bottom, $black);
	
	# draw chromosomal scale
	$self->_draw_grid($img,$x_chr);	
	
	return $self->{_gd} = $img;
}


sub _ticks {
	# calculate major and minor ticks, given a start position
	# modified from Bio::Graphics::Panel module
	# the MIN_GD_VALUE is used when the map scale is too big
	use constant MIN_WIDTH => 40;
	use constant MIN_GD_VALUE => 50;
	
	my $self = shift;
	
	my $length = $self->get_map_size;
	my $min_width = MIN_WIDTH;
	
	# figure out tick mark scale
	# we want no more than 1 major tick mark every 40 pixels
	# and enough room for the labels
	my $scale = $self->_scale;
	
	$min_width = MIN_GD_VALUE if ($scale > $min_width);

	my $interval = 1;

	while (1) {
		my $pixels = $interval * $scale;
		last if $pixels >= $min_width;
		$interval *= 10;
	}
	return ($interval,$interval/10);
}

sub _draw_grid {
	# draw a grid scale
	# modified from Bio::Graphics::Panel module
	use constant GRID_WIDTH => 3;
	
	my ($self,$gd,$x_chr) = @_;
	
	my $black = $gd->colorAllocate(0,0,0);

	my @positions;
	my ($major,$minor) = $self->_ticks;

	my $first_tick = $minor * int($self->get_map_start/$minor);

	for (my $i = $first_tick; $i <= $self->get_map_size; $i += $minor) {
		push @positions,$i;
	}
	
	my $size_ratio = $self->_get_screen_size_ratio;
	my $x_scale = $self->_pad_left;
	for my $tick (@positions) {
		my $y = $self->_locate_element($tick);
		my $offscale_major = 0;
		if ($tick % $major == 0) {
			$offscale_major = GRID_WIDTH;
			my $screen_value_grid = sprintf ("%.1f",($tick / $size_ratio));
			$gd->string(gdTinyFont,$x_scale,$y-5,$screen_value_grid,$black);
		}
		$gd->line($x_chr - GRID_WIDTH - $offscale_major, $y, $x_chr, $y, $black);
	}
}

1;

__END__

=head1 NAME

Chromosome::Map - Generate GD images of chromosome maps

=head1 SYNOPSIS

 #!/usr/bin/perl -w 
 # This script produce a chromosomal map with several markers and QTL
 # interval region. A fake %GC content is added to the chromosome 
 
 use strict; 
 use Chromosome::Map;
 
 my %H = (ADL120 => '25', 
          ADL035 => '5', 
          ADL034 => '4', 
          MCW014 => '110', 
          MCW123 => '89', 
          MCW340 => '70', 
          LEI456 => '132', 
          LEI451 => '130', 
          LEI452 => '130.5', 
          LEI453 => '130.7', 
          LEI454 => '131', 
          LEI455 => '131.4', 
          LEI457 => '132', 
          MCW087 => '50', 
          MCW012 => '12', 
          MCW051 => '51', 
          ADL121 => '26', 
          ADL123 => '27', 
          ADL122 => '26.2', 
          MCW114 => '45', 
          LEI258 => '15', 
          MCW240 => '45.1', 
          MCW247 => '110', 
          LEI556 => '44', 
          MCW614 => '45.2', 
          ADL067 => '5.3', 
          MCW140 => '45.2', 
          LEI056 => '45.6', 
         ); 
 
 my $map = Chromosome::Map->new (-length     => '140', 
                                 -name       => 'GGA5', 
                                 -height     => '500', 
                                 -units      => 'cM', 
                                ); 
 
 my $size  = $map->get_map_size; 
 my $units = $map->get_map_units; 
 
 print "Map size: $size $units\n";
 
 my $mark_track = Chromosome::Map::Track->new (-name => 'Markers',
                                               -type => 'marker',
                                              );
 my $qtl_track  = Chromosome::Map::Track->new (-name => 'QTL',
                                               -type => 'interval',
                                              );
 my $GC_track  = Chromosome::Map::Track->new  (-name    => '%GC content',
                                               -type    => 'feature',
                                               -display => 'relative',
                                               -render  => 'gradient',
                                              );
 # adding tracks to map
 $map->add_track($mark_track);
 $map->add_track($qtl_track);
 $map->add_track($GC_track);
 
 my $nb_track = $map->get_nb_tracks;
 print "Nb track: $nb_track\n";
 
 # Generating a fake feature relative elements and add them in track
 # only for illustrative purpose
 my %GC;
 for (my $i=0;$i<=5000;$i++) {
     my $nb = abs ( rand ($size));
     my $value = abs ( rand (1));
     $GC{$nb} = $value;
 }
 
 foreach my $nb (keys %GC) {
     my $gc = Chromosome::Map::Feature->new (-loc => $nb,
                                             -color => 'indigo',
                                             -value => $GC{$nb},
                                             -valuetype => 'relative',
                                            );
     $GC_track->add_element($gc);
 }
 
 my @Color = qw (blueviolet darkgoldenrod black softblue khaki red blue tomato);
 
 foreach my $mark (keys %H) {
     my $i = abs (int( rand ($#Color) ) );
     my $marker = Chromosome::Map::Element->new(-name  => $mark,
                                                -loc   => $H{$mark},
                                                -color => $Color[$i],
                                               );
     $mark_track->add_element($marker);
 }
 
 # Define QTL element
 my $qtl1 = Chromosome::Map::Block->new (-name  => 'BW',
                                         -start => '3',
                                         -end   => '11',
                                         -color => 'darkgoldenrod',
                                        );
 
 my $qtl2 = Chromosome::Map::Block->new (-name  => 'FAT',
                                         -start => '92',
                                         -end   => '100',
                                         -color => 'darkgoldenrod',
                                        );
 
 my $qtl3 = Chromosome::Map::Block->new (-name  => 'LEAN',
                                         -start => '112',
                                         -end   => '120',
                                         -color => 'darkgoldenrod',
                                        );
 
 my $qtl4 = Chromosome::Map::Block->new (-name  => 'EGG DEV',
                                         -start => '95',
                                         -end   => '115',
                                        );
 
 my $qtl5 = Chromosome::Map::Block->new (-name  => 'IC',
                                         -start => '91',
                                         -end   => '122',
                                         -color => 'blueviolet',
                                        );
 
 my $qtl6 = Chromosome::Map::Block->new (-name  => 'BORN',
                                         -start => '20',
                                         -end   => '130',
                                        );
 
 my $qtl7 = Chromosome::Map::Block->new (-name  => 'REPRODUCTION',
                                         -start => '20',
                                         -end   => '130',
                                        );
 
 $qtl_track->add_element($qtl1);
 $qtl_track->add_element($qtl2);
 $qtl_track->add_element($qtl3);
 $qtl_track->add_element($qtl4);
 $qtl_track->add_element($qtl5);
 $qtl_track->add_element($qtl6);
 $qtl_track->add_element($qtl7);
 
 
 my $png = $map->png;
 my $filename_png = "chr_map.png";
 open (PNG, ">$filename_png") || die "cannot create file: $filename_png!\n";
 binmode PNG;
 print PNG $png;
 close PNG;

=head1 DESCRIPTION 

The Chromosome::Map module can produce chromosomal map image file. It can be used to draw genetic or physical maps. Several tracks (i.e. list of marker) can be add to the chromosomal map: markers track and QTL interval region track (see synopsis). A code colors list is available at L<http://chicken.genouest.org/documentations/chromosomemap/#colors>

=head1 METHODS 

This section describes the class and object methods for the Chromosome::Map module. 

=head2 Map object 

First, you will begin by creating a new Chromosome::Map object:

 my $map = Chromosome::Map->new ( ... options ... );

The new() method creates a new panel object. The options are a set of tag/value pairs as follows: 
 
 Option        Value                                                  Default
 ------        -----                                                  -------
 -name         title name of the chromosomal map                      none

 -start        location start of the map                              0
 -length       size of the map (i.e location end)                     none
 -units        unit of the map (i.e cM or MB, only for display)       none
 -height       size of the resulting image (pixel)                    none

 -pad_left     left margin                                            20
 -pad_right    right margin                                           20
 -pad_top      top margin                                             20
 -pad_bottom   bottom margin                                          40

Public methods description:

=over 4

=item *

add_track: add an existing track to an existing map. return O in case of error

 $map->add_track($track) 

=item *

png: create a PNG image of the map

 $name = $map->png 

=item *

get_map_name: return the title name of the map

 $name = $map->get_map_name 

=item *

get_map_start: return the start location of the map

 $map_start = $map->get_map_start 

=item *

get_map_size: return the end location of the map (i.e. the map size)

 $map_size = $map->get_map_size 

=item *

get_map_units: return the unit of the map (i.e. cM, MB, KB...)

 $map_unit = $map->get_map_units 

=item *

get_nb_tracks: return the number of the tracks in the map

 $nb_track = $map->get_nb_tracks 

=item *

get_list_track: return a list (%Hash) of the tracks in the map

 %List = $map->get_list_track 

=back

=head2 Track object 

Then, you will create different tracks and add them to the Chromosome::Map object.

 my $track = Track->new ( ... options ... ); 
 $map->add_track($track); 

The new() method creates a new track object. The options are a set of tag/value pairs as follows: 

 Option        Value                                                  Default
 ------        -----                                                  -------
 -name         title name of the track                                none
 
 -type         this tag will permit you to define the type of the     none
               track with the followin values:
               'marker': designed for markers
               'interval': designed for QTL interval region, could
               marker interval or gene location, too
               'feature': designed to plot physical features on
               chromosomes (%GC, nb genes)

if you choose the feature track type, you have to define some other specific 
 options:

 Option        Value                                                  Default
 ------        -----                                                  ------- 
 -display      the tag will permit to define the rendering of the     absolute
               feature track with the following value:
               'absolute': if several feature values are present in
               one pixel interval, the feature values will be added
               for display.
               'relative': if several feature values are present in
               one pixel interval, the mean value of all the
               feature values will be used for display.

 -render       define the rendering effet of the feature track with   plain
               the following values:
               'plain': use plain color
               'gradient': gradient value according to the feature
               value
               'threshold': change color according to a threshold
               value

 -threshold    define the threshold value to change color in          none 
               threshold rendering effect

Note: you cannot add several feature tracks. Other feature tracks will be discard. 

Public methods description: 

=over 4

=item *

add_element: add an existing element to an existing track. return O in case of error

 $track->add_element($element) 

=item *

get_track_name: return the start location of the map 

 $track_name = $track->get_track_name 

=item *

get_track_type: return the track type (i.e. marker, interval or feature) 

 $track_type = $track->get_track_type 

=item *

get_nb_elements: return the number of elements in a track 

 $nb_element = $track->get_nb_elements 

=item *

get_list_element: return an ARRAY of the elements in the track 

 @List = $track->get_list_element 

=item *

get_list_element_sorted_location: return an ARRAY of the elements in the track, sorted on their location 

 @List = $track->get_list_element_sorted_location 

=back

=head2 Element, Block and Feature objects
 
When your map and tracks object are created, then, you can create the elements you want to add into the tracks. There is three different type of object: 

=over 4

=item Element object

This object is primary designed to manage marker elements and to add them into a marker track. You will create it by passing the name (optional), the location of the element and the font color (optional, default=black). 

 my $marker = Chromosome::Map::Element->new( ... options ... ) 

 Option        Value                                                  Default
 ------        -----                                                  -------  
 -name         element name (optional)                                none 
 -loc          element location                                       none 
 -color        color_name                                             black 

the -color tag will permit to define different element group and display them with different colors. 

=item Block object

This object is primary designed to display chromosomal interval (i.e QTL region, genes, ...). This class is inherited from the element object with a field for the interval end location. You will create this object by passing it the block name (optional), block start and end location, and the block background color (note: the end location must be greater than thestart location). 

 my $block = Chromosome::Map::Bloc->new( ... options ... ) 

 Option        Value                                                  Default
 ------        -----                                                  -------
 -name         block name (optional)                                  none 
 -loc          block start location                                   none  
 -end          block end location                                     none  
 -color        color_name                                             black

=item Feature object

This object is designed to display chromosome features as %GC content, gene density or whatever features with a numerical value. This object is also inherited from the element class. You will create this object by passing it the feature location, the feature value, the value type (i.e. absolute or relative) and color, depending on the display rendering choosen during the feature track creation. 

 my $feature = Chromosome::Map::Feature->new( ... options ... ) 

 Option        Value                                                  Default
 ------        -----                                                  -------
 -loc          feature location                                       none 
 -value        feature value                                          none 
 -color        feature rendering color                                softblue 
 -threscolor   feature threshold color (if value > threshold)         red 
 -value        feature value                                          1 
 -valuetype    feature value type:                                    absolute 
               'absolute': absolute value (i.e. nb of genes)
               'relative': relative value (i.e. %GC)

Of course, you cannot mix different value types in one track. 

The choice of value type has an impact on the rendering of the feature track. You have to choose carefully the value type tag and the display tag of the feature track object: 

=over 8

=item *

If you choose an 'absolute' value type element, you can either display it in absolute or relative render option in the track object.

ex: let hypothetize you want to display the number of gene on your chromosome. 
For each gene, you will create a feature object: 

 my $gene = Chromosome::Map::Feature->new (-loc=$location); 

Then, you can display the feature track as 'absolute': in one pixel interval, the number of genes will be displayed. But, you can also display the number of genes as a percentage of the maximum 
number of genes on the chromosome: the render tag in the track object have to be set to 'relative'. 

=item *

If you choose a 'relative' value type element, you HAVE to set the render tag in the track object to 'relative' (since displaying relative data in an absolute is non sense). 

=back

=back

Common public methods (available with element, block and feature objects): 

=over 4

=item *

get_element_loc: 

 $loc = $element->get_element_loc 

=item *

get_element_name: 

 $element_name = $element->get_element_name 

=item *

get_element_color: 

 $element_color = $element->get_element_color 

=back

Block public method:  

=over 4

=item *

get_block_end: 

 $block_end_location = $block->get_block_end 

=back

Feature public methods:  

=over 4

=item *

get_feature_value: return the value of the feature object 

 $value = $feature->get_feature_value 

=item *

get_feature_value_type: return the type of the value (relative or absolute) 

 $value_type = $feature->get_feature_value_type

=item *

get_feature_threshold_color: return the threshold color (default=red) 

 $threshold_col = $feature->get_feature_threshold_color 

=back

=head1 AUTHOR 

Frédéric Lecerf L<http://chicken.genouest.org>

=head1 COPYRIGHT 

Copyright (C) 2010, Frédéric Lecerf.

=head1 LICENSE 

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.