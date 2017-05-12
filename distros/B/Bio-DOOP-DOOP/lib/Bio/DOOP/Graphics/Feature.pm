package Bio::DOOP::Graphics::Feature;

use strict;
use warnings;
use GD;

=head1 NAME

Bio::DOOP::Graphics::Feature - Graphical representation of the features

=head1 VERSION

Version 0.18

=cut

our $VERSION = '0.18';

=head1 SYNOPSIS

=head1 DESCRIPTION

This object represents a picture that contains all the sequences and sequence features of a subset.
The module is fast enough to use it in your CGI scripts. You can also use it to visualize
the subset.

=head1 AUTHOR

Tibor Nagy, Godollo, Hungary

=head1 METHODS

=head2 create

Creates a new picture. Later you can add your own graphical elements to it.

Arguments: Bio::DOOP::DBSQL object and subset primary id.

Return type: Bio::DOOP::Graphics::Feature object

  $picture = Bio::DOOP::Graphics::Feature->create($db,"1234");

=cut

sub create {

  my $self                 = {};
  my $dummy                = shift;
  my $db                   = shift;
  my $subset               = shift;

  my @seqs    = @{$subset->get_all_seqs};
  my $height  = ($#seqs+1) * 90 + 40;

  my $width   = $subset->get_cluster->get_promo_type + 20;
  my $image   = new GD::Image($width,$height); # Create the image

  $self->{IMAGE}           = $image;
  $self->{DB}              = $db;
  $self->{SEQS}            = \@seqs;
  $self->{WIDTH}           = $width;
  $self->{HEIGHT}          = $height;
  $self->{POS}             = 0;
  $self->{SUBSET_ID}       = $subset->get_id;

  # This is the map of the image. It is useful for HTML image maps.
  # TODO : Add more types to this hash.
  $self->{MAP}             = {
                                motif => [],
                                dbtss => [],
                                utr   => []
  };
  # The colormap of the object.
  $self->{COLOR}           = {
                                background => [200,200,200],
                                label      => [0,0,0],
                                strip      => [220,220,220],
                                utr        => [100,100,255],
                                motif      => [0,100,0],
                                tss        => [0,0,0],
                                frame      => [255,0,0],
                                fuzzres    => [0,0,255]
  };

  bless $self;
  return($self);
}

=head2 add_color

Add an RGB color to the specified element.

The available elements are the following : background, label, strip, utr, motif, tss, frame, fuzzres.

  $image->add_color("background",200,200,200);
  $image->set_colors;

=cut

sub add_color {
  my $self                 = shift;
  my $code                 = shift;
  my $r                    = shift;
  my $g                    = shift;
  my $b                    = shift;
  my @color;
  @color = ($r,$g,$b);
  $self->{COLOR}->{"$code"} = \@color;
}

=head2 set_colors

Sets all colors. Allocate colors previously with add_color. Use this method only ONCE after you set
all the colors. If you use it more than once, the results will be strange.

=cut

sub set_colors {
  my $self                 = shift;

  my $r;
  my $g;
  my $b;
  ($r,$g,$b) = @{$self->{COLOR}->{background}};
  $self->{IMAGE}->colorAllocate($r,$g,$b);                         # Set the background color.
  ($r,$g,$b) = @{$self->{COLOR}->{label}};
  $self->{LABEL}      = $self->{IMAGE}->colorAllocate($r,$g,$b);   # Set the label color.
  ($r,$g,$b) = @{$self->{COLOR}->{utr}};
  $self->{UTR}        = $self->{IMAGE}->colorAllocate($r,$g,$b);   # Set the UTR color.
  ($r,$g,$b) = @{$self->{COLOR}->{motif}};
  $self->{MOTIFCOLOR} = $self->{IMAGE}->colorAllocate($r,$g,$b);   # Set the motif color.
  ($r,$g,$b) = @{$self->{COLOR}->{tss}};
  $self->{TSSCOLOR}   = $self->{IMAGE}->colorAllocate($r,$g,$b);   # Set the tss color.
  ($r,$g,$b) = @{$self->{COLOR}->{strip}};
  $self->{STRIP}      = $self->{IMAGE}->colorAllocate($r,$g,$b);   # Set the strip color.
  ($r,$g,$b) = @{$self->{COLOR}->{frame}};
  $self->{FRAME}      = $self->{IMAGE}->colorAllocate($r,$g,$b);   # Set the frame color.
  ($r,$g,$b) = @{$self->{COLOR}->{fuzzres}};
  $self->{FUZZRES}    = $self->{IMAGE}->colorAllocate($r,$g,$b);   # Set the fuzznuc result color.
}

=head2 add_scale

Draws the scale on the picture.

=cut

sub add_scale {
  my $self                 = shift;

  my $color = $self->{LABEL};

  # Draw the main axis.
  $self->{IMAGE}->line(10,5,$self->{WIDTH}-10,5,$color);

  # Draw the scales.
  my $i;
  for ($i = 20; $i < $self->{WIDTH}-10; $i += 10){
      if( ($i / 100) == int($i / 100) ) {
          $self->{IMAGE}->line($i+10,0,$i+10,10,$color);     # Large scale.
          my $str = ($self->{WIDTH} - 20 - $i) * -1;         # The scale label.
          my $posx = $i - (length($str)/2)*6 + 10;           # Nice label positioning.
          $self->{IMAGE}->string(gdSmallFont,$posx,10,$str,$color);
      }
      else {
          $self->{IMAGE}->line($i+10,3,$i+10,7,$color); # Small scale.
      }
  }

  # Draw the arrow.
  my $arrow = new GD::Polygon;
  $arrow->addPt(9,5);
  $arrow->addPt(15,2);
  $arrow->addPt(15,8);
  $self->{IMAGE}->filledPolygon($arrow,$color);
}

=head2 add_bck_lines

Draws scale lines through the whole image background.

=cut

sub add_bck_lines {
  my $self                 = shift;
  my $color = $self->{STRIP};

  my $i;
  for ($i = 20; $i < $self->{WIDTH}-10; $i += 10){
          $self->{IMAGE}->line($i,0,$i,$self->{HEIGHT},$color);
      }

}

=head2 add_seq

Draws a specified sequence on the picture. This is internal code, do not use it directly.

=cut

sub add_seq {
  my $self                 = shift;
  my $index                = shift;

  my $seq = $self->{SEQS}->[$index];
  my $len = $seq->get_length;
  my $x1  = $self->{WIDTH} - 10;
  my $x2  = $x1-$len;

  # Draw the seq line.
  $self->{IMAGE}->line($x2, $index*90+40, $x1, $index*90+40, $self->{LABEL});

  # Draw UTR.
  my $utrlen = $seq->get_utr_length;
  if ($utrlen){
      my $utrlen2 = $x1 - $utrlen;
      if ($utrlen2 < 10){$utrlen2 = 10}
      $self->{IMAGE}->filledRectangle($utrlen2, $index*90+35, $x1, $index*90+45, $self->{UTR});
      $self->{IMAGE}->string(gdTinyFont, $utrlen2, $index*90+36, "UTR ".$utrlen." bp", $self->{LABEL});
  }

  # Print the sequence name and length.
  my $text = $seq->get_taxon_name . " " . $len . " bp";
  $self->{IMAGE}->string(gdSmallFont, $x2, $index*90+22, $text, $self->{LABEL});

  # Draw features.
  my $features = $seq->get_all_seq_features;
  if ($features == -1){ return }
  my $motif_Y = $index*90 + 60;
  my $shift_factor = 0;
  my $motif_count;

  my $min_motif_id;
  for my $feat (@$features){
     if( ($feat->get_type eq "con") && ($feat->get_subsetid eq $self->{SUBSET_ID})){
	     $min_motif_id = $feat->get_motifid;
             last;
     }
  }
  for my $feat (@$features){
      # Draw motifs.
      if( ($feat->get_type eq "con") && ($feat->get_subsetid eq $self->{SUBSET_ID})){
	  $motif_count = $feat->get_motifid - $min_motif_id + 1;
          # This code helps to make three rows for the motifs.
	  my $label_length = (length($motif_count) + 1) * 6; # Label width with gdSmallFont
          my %motif_element = ($feat->get_motifid => [ $x1 - $len + $feat->get_start,
                                                       $motif_Y + $shift_factor,
                                                       $x1 - $len + $feat->get_end,
                                                       $motif_Y + $shift_factor + 5 ]);
          $self->{IMAGE}->filledRectangle($x1 - $len + $feat->get_start,
                                          $motif_Y + $shift_factor,
                                          $x1 - $len + $feat->get_end,
                                          $motif_Y + $shift_factor + 5,
                                          $self->{MOTIFCOLOR});
          $self->{IMAGE}->string(gdSmallFont, $x1 - $len + $feat->get_start, $motif_Y+$shift_factor+6, "m$motif_count", $self->{LABEL});
          push @{$self->{MAP}->{"motif"}},\%motif_element;
          if ($feat->length > $label_length){
              $shift_factor = 0;
          }
          elsif( ($feat->length < $label_length) && ($shift_factor < 36)){
              $shift_factor += 18;
          }
          else {
              $shift_factor = 0;
          }
     }

      # Draw tss.
      if( ($feat->get_type eq "tss")){
          my $motif_Y = $index*90 + 40;
          my $tssfeat = new GD::Polygon;
          $tssfeat->addPt($x1-$len+$feat->get_start,$motif_Y);
          $tssfeat->addPt($x1-$len+$feat->get_start-5,$motif_Y+10);
          $tssfeat->addPt($x1-$len+$feat->get_start+5,$motif_Y+10);
          $self->{IMAGE}->filledPolygon($tssfeat,$self->{TSSCOLOR});
      }

  }

}

=head2 add_all_seq

Draws all sequences of the subset. The first one is the reference species.

=cut

sub add_all_seq {
  my $self                 = shift;
  my @seqs = @{$self->{SEQS}};
  my $i;
  for($i = 0; $i < $#seqs+1; $i++){
     $self->add_seq($i);
  }
}

=head2 get_png

Returns the png image. Use this when you finish the work and would like to see the result.

  open IMAGE,">picture.png";
  binmode IMAGE;
  print IMAGE $image->get_png;
  close IMAGE;

=cut

sub get_png {
  my $self                 = shift;
  return($self->{IMAGE}->png);
}


=head2 get_image

Returns the drawn image pointer. Useful for adding your own GD methods for unique picture manipulation.

=cut

sub get_image {
  my $self                 = shift;
  return($self->{IMAGE});
}

=head2 get_map

Returns a hash of arrays of hash of arrays reference that contains the image map information.
Here is a real world example of how to handle this method :

  use Bio::DOOP::DOOP;

  $db      = Bio::DOOP::DBSQL->connect($user,$passwd,"doop-plant-1_5","localhost");
  $cluster = Bio::DOOP::Cluster->new($db,'81001110','500');
  $image   = Bio::DOOP::Graphics::Feature->create($db,$cluster);

  for $motif (@{$image->get_map->{motif}}){
    for $motif_id (keys %{$motif}){
       @coords = @{$$motif{$motif_id}};
       # Print out the motif primary id and the four coordinates in the picture
       #        id        x1         y1         x2         y2
       print "$motif_id $coords[0] $coords[1] $coords[2] $coords[3]\n";
    }
  }
  
It is somewhat difficult, but if you are familiar with references and nested data structures, you
will understand it.

=cut

sub get_map {
  my $self                 = shift;
  return($self->{MAP});
}

=head2 get_motif_map

Returns only the arrayref of motif hashes.

=cut

sub get_motif_map {
  my $self                 = shift;
  return($self->{MAP}->{motif});
}

=head2 get_motif_id_by_coord

With this, you can get a motif id, if you specify the coordinates of a pixel.

  $motif_id = $image->get_motif_id_by_coord(100,200);

=cut

sub get_motif_id_by_coord {
  my $self                 = shift;
  my $x                    = shift;
  my $y                    = shift;

  for my $motif (@{$self->get_motif_map}){ 
    for my $motif_id (keys %{$motif}){
       my @coords = @{$$motif{$motif_id}};
       if(($x > $coords[0]) && ($x < $coords[2]) &&
          ($y > $coords[1]) && ($y < $coords[3])) {
           return($motif_id);
       }
    }
  }
  return(0);
}

=head2 draw_motif_frame

This method draws a frame around a given motif.

Arguments: motif primary id

Return type: 0 if success, -1 if the given motif id is not in the picture.

  $image->draw_motif_frame($motifid);

=cut

sub draw_motif_frame {
  my $self                 = shift;
  my $motifid              = shift;
  my $actualid;
  my $have = 0;

  for my $motif (@{$self->{MAP}->{motif}}){
     ($actualid) = keys %{$motif};
     if ($actualid == $motifid){
        my @choords = @{$$motif{$actualid}};
        $have = 1;

        # Draw the frame
        $self->{IMAGE}->rectangle($choords[0]-3,$choords[1]-3,$choords[2]+3,$choords[3]+3,$self->{FRAME});
        $self->{IMAGE}->rectangle($choords[0]-2,$choords[1]-2,$choords[2]+2,$choords[3]+2,$self->{FRAME});
     }
  }

  if ($have == 0){
      return(-1)
  }
  else{
      return(0)
  }
}

=head2 draw_fuzz_result

You can draw the fuzznuc result on the picture with this method.

Arguments : sequence primary id, start position, end position

To set drawing color, you can use the setcolor("fuzzres",$r,$g,$b) method.
The method shows the orientation. The arrow always points to the start position.

Return value : 0 if success, -1 if the given sequence id can't be found.

  $image->draw_fuzz_result(357,20,70);

=cut

sub draw_fuzz_result {
  my $self                 = shift;
  my $seqid                = shift;
  my $start                = shift;
  my $end                  = shift;
  my $index = 0;
  my $ori;

  for my $i (@{$self->{SEQS}}){
     if ($i->get_id eq $seqid){
	my $y = $index*90+50;
        my $len = $self->{WIDTH} - 10 - $i->get_length;
        my $x1  = $len + $start;
        my $x2  = $len + $end;
	my $poly = new GD::Polygon;
	if(($end - $start) > 0){ $ori = -1 }else{ $ori = 1 }

	$poly->addPt($start, $y);
	$poly->addPt($start - 5*$ori, $y - 5);
	$poly->addPt($start - 5*$ori, $y - 2);
	$poly->addPt($end, $y - 2);
	$poly->addPt($end, $y + 3);
	$poly->addPt($start - 5*$ori, $y + 3);
	$poly->addPt($start - 5*$ori, $y + 5);

        $self->{IMAGE}->filledPolygon($poly,$self->{FUZZRES});
        return(0);
     }
     $index++;
  }
  return(-1);
}

1;
