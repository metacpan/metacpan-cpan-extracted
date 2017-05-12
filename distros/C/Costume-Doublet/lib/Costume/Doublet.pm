package Costume::Doublet;

use 5.008001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Costume::Doublet ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = qw(make_pattern);

our @EXPORT = qw( );

our $VERSION = '0.001';

use GD;
our @messurments = qw ( chest waist back_length shoulder front_width back_width);
# Preloaded methods go here.
sub make_pattern
{
  my %args = (@_);
    
  #If metric convert to inches
  if ($args{'unit'} eq 'cm')
    {
      foreach my $mes (@messurments)
	{
	  $args{$mes} = $args{$mes} * 2.54;
	}
    }
  
    ## compute stuff
  
  #
  # all point names are in refrence to "Costume Technician's
  # Handbook" by Rosemary Ingham/Liz Covey See page 126-
  

  my $waist_dart   = &find_waist_dart($args{'chest'},$args{'waist'});
  my $ab_height    = $args{'back_length'};
  my $ac_width     = ($args{'chest'} / 2) + 0.5;
  my $ef_width     = ($ac_width  / 2);
  my $gh_height    = ($ab_height / 4);
  my $ij_height    = ($ab_height / 2);
  
  my $img = new GD::Image(800,800);
  
  my $white = $img->colorAllocate(255,255,255);
  my $black = $img->colorAllocate(0,0,0);
  my $red   = $img->colorAllocate(255,0,0);
  my $blue  = $img->colorAllocate(0,0,255);
  my $green = $img->colorAllocate(0,255,0);
  ## Draw Bounding box;
  &draw_grid($img);
  $img->rectangle (&make_point(0,0),
		   &make_point($ac_width,$ab_height),
		   $blue);

  $img->dashedLine(&make_point(0,$gh_height),
		   &make_point($ac_width,$gh_height),
		   $blue);

  $img->dashedLine(&make_point(0,$ij_height),
		   &make_point($ac_width,$ij_height),
		   $blue);

  $img->dashedLine(&make_point($ef_width,0),
		   &make_point($ef_width,$ab_height),
		   $blue);

  my @k_point = &make_point(($ac_width - 3), -0.5);
  my @m_point = &make_point($ac_width,2.5);

  ## Draw the neck hole
  $img->arc($m_point[0],$k_point[1], 
	    (2 * ($m_point[0] - $k_point[0])),
	    (2 * ($m_point[0] - $k_point[0])),
	    90,180,
	    $red);

  $img->dashedLine(&make_point($ef_width,1.375),
		   &make_point($ac_width,1.375),
		   $blue);


  my @n_point = &make_point(($ac_width - 3.0) - sqrt(($args{'shoulder'}** 2) - ( 0.5 + 1.375)**2),
			    1.375);  ## The sholder line takes some triginomitry


  $img->line(@k_point,@n_point,$red);

  my @p_point = &make_point(($ac_width - ($args{'front_width'} / 2)),
			    $gh_height);

  $img->line(@n_point,@p_point,$red);

  my @o_point   = &make_point($ef_width ,$ij_height);
  my @bs_point  = &make_point($ef_width -1 ,$ij_height -1);
  my @q_point   = &make_point(($ac_width - (($args{'waist'} *.25) + 6 +$waist_dart)),
			    $ab_height);

  my @ee_point  = &make_point ((($args{'waist'}  * .25)- 6 - $waist_dart),
			      $ab_height);

  $img->line(@bs_point,@q_point,$red);
  $img->line(@bs_point,@ee_point,$red);
  
  ##Back Nexk

  my @zero_point = &make_point(0,0);
  my @aa_point = &make_point(2.5,-.5);

#  $img->rectangle(&make_point(-2.5,-1),
#		  &make_point(2.5,0),
#		  $green);
  
  $img->arc(&make_point(0,-0.5),
	    (2 *($aa_point[0] - $zero_point[0])),
	    (2 *($aa_point[1] - $zero_point[1])),
	    270,360,
	    $red);


## back Sholder
  my @bb_point = &make_point($args{'back_width'}/2,
			     $gh_height);
  my @cc_point = &make_point( $args{'back_width'}/2,
			      $gh_height -3);


  my $bs_len   = $args{'shoulder'} + 0.5;
  my $sholder_theta = atan2 (($gh_height-3),
			     (($args{'back_width'} / 2) -2.5));

  my @dd_point = &make_point ((2.5 +($bs_len * cos($sholder_theta))),
			      ($bs_len * sin($sholder_theta)) - 0.5);

#  $img->line(@aa_point,@cc_point,$red);
#  $img->line(@bb_point,@cc_point,$red);
  $img->line(@aa_point,@dd_point,$red);

  
  my $poly = new GD::Polygon;
  $poly->addPt(@n_point);
  $poly->addPt(@p_point);
  $poly->addPt(@o_point);
  $poly->addPt(@bs_point);

  $poly->addPt(@bb_point);
  $poly->addPt(@dd_point);
  
  $img->polygon($poly,$green);

  $img->line(@n_point,@dd_point,$white);
  ## Add label
  my $date =  `date +"%d %B %Y"`;
  chomp $date;

  $img->string(gdSmallFont,
	       &make_point ($ef_width+3,$ij_height-2),
	       $args{'name'} ,
	       $red);
 

  $img->string(gdSmallFont,
	       &make_point ($ef_width+3,$ij_height-1),
	       $date,
	       $red);

  $img->string(gdSmallFont,
	       &make_point ($ef_width+-6,$ij_height-2),
	       $args{'name'} ,
	       $red);
 

  $img->string(gdSmallFont,
	       &make_point ($ef_width+-6,$ij_height-1),
	       $date,
	       $red);

  $img->string(gdLargeFont,
	       &make_point ($ef_width+3,$ij_height+1),
	       "FRONT",
	       $red);

  $img->string(gdLargeFont,
	       &make_point ($ef_width-6,$ij_height+1),
	       "BACK",
	       $red);

  ## Print out the image

  open (IMG,">$args{'output'}") or die "Can't open $args{'output'} $!";
  binmode IMG;
  print IMG $img->png;
  close (IMG);
    }

sub make_point
  {
    my ($x,$y) = @_;
    my $scale_factor = 25;
    my $shift_down   = 100;
    my $shift_right  = 100;
    my ($x_point,$y_point) =
      ((($x  * $scale_factor) + $shift_right),
       (($y  * $scale_factor) + $shift_down));
#    print STDERR "$x_point, $y_point\n";
    return($x_point,$y_point);
  }
    
sub find_waist_dart
  {
      my ($chest,$waist) = @_;
    my $diff = $chest - $waist;

    return 0        if ($diff < 4.0);
    return 0.5      if ($diff < 5.5);
    return 0.75     if ($diff < 7.5);
    return 1.0      if ($diff < 9.5);
    return 1.25     if ($diff < 11.5);
    return 1.5;
}

sub draw_grid
  {
    my $img = shift;
    my $grey = $img->colorAllocate(192,192,192);
    my $red   = $img->colorAllocate(255,0,0);
    my $x = -5;
    my $y = -5;

    while ($x < 60)
    {
      $y = -5;
      while ($y < 60)
	{
	  $img->rectangle(&make_point($x,$y),
			  &make_point($x+1,$y+1),
			  $grey);
	    $y++;
	}
      $x++
    }
    $img->string(gdSmallFont,
		 &make_point (-3,-3),
		 "boxes are 1 inch",
		 $red);

}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Costume::Doublet - Perl extension for to make a base pattern for an Elizabethan doublet

=head1 SYNOPSIS

  use Costume::Doublet;
  Costume::Doublet::make_pattern(chest      => 46,
				waist       => 40,
				back_length => 23,
				shoulder     => 6.75,
				front_width => 15.75,
				back_width  => 17,
				unit        => "inch",
				name        => "Zach Kessin",
				output      => "pattern.png");

  This module takes a set of measurements and will output a pattern for
  a man's doublet. The measurements are taken from "The costume technician's handbook" 

=head1 DESCRIPTION

 The measurements needed are around the 
    chest, 
    around the waist, 
    The length of the back from neck to waist
    the length of the shoulder from base of the neck to the top of the shoulder (its very easy to make this too long
    the width of the front (taken  at the midpoint of the arm joint, about where a tank top would stop)
    The width of the back  ibid.
    
 Unit should be "inch" or "cm" 
 name is the name of the person for whom the pattern is for. 
 output is a filename to output.

=head2 Sewing notes
 the pattern does not include seam allowance. 

 Making a mock up out of cheap fabric is recomeneded.

 For a more authentic garment ajustment of seam placement may be needed. 

 The sleave cap (shown in green) should be a curve. That will i hope
 be in a future version of the software.



=head1 SEE ALSO

Necessary books are the "Costume Technician's Handbook" by Rosemary
InghamLiz Covey as well as "Pattern's of fashion" and others


=head1 AUTHOR

Zachary Kessin, E<lt>zkessin@cs.brandeis.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Zachary Kessin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

If you actually make stuff from the patterns I would love to see pictures! 

=cut
