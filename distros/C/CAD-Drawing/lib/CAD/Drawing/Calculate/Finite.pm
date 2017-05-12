package CAD::Drawing::Calculate::Finite;
our $VERSION = '0.06';

# use CAD::Drawing;
use CAD::Drawing::Defined;


use warnings;
use strict;
use Carp;
########################################################################
=pod

=head1 NAME

CAD::Drawing::Calculate::Finite - Vector graphics and limited space.

=head1 Description

This module is intended as a back-end to CAD::Drawing for methods
specific to finite formats (and entities) like images and postscript.

=head1 AUTHOR

Eric L. Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com

=head1 COPYRIGHT

This module is copyright (C) 2004-2006 by Eric L. Wilhelm.  Portions
copyright (C) 2003 by Eric L. Wilhelm and A. Zahner Co.

=head1 LICENSE

This module is distributed under the same terms as Perl.  See the Perl
source package for details.

You may use this software under one of the following licenses:

  (1) GNU General Public License
    (found at http://www.gnu.org/copyleft/gpl.html)
  (2) Artistic License
    (found at http://www.perl.com/pub/language/misc/Artistic.html)

=head1 NO WARRANTY

This software is distributed with ABSOLUTELY NO WARRANTY.  The author,
his former employer, and any other contributors will in no way be held
liable for any loss or damages resulting from its use.

=head1 Modifications

The source code of this module is made freely available and
distributable under the GPL or Artistic License.  Modifications to and
use of this software must adhere to one of these licenses.  Changes to
the code should be noted as such and this notification (as well as the
above copyright information) must remain intact on all copies of the
code.

Additionally, while the author is actively developing this code,
notification of any intended changes or extensions would be most helpful
in avoiding repeated work for all parties involved.  Please contact the
author with any such development plans.

=head1 SEE ALSO

  CAD::Drawing

=cut
########################################################################

=head1 Methods

=head2 fit_to_bound

Performs extents and scaling to fit entire drawing within a
bound.  Returns the scale which is required to create the fit.

  $scale = $drw->fit_to_bound(\@bound, \@border, \%opts);

NOTE:

  @bound arg is a rectangle ([0,0],[11,8.5]) 

  @border is ([$left_sp, $bottom_sp], [$right_sp, $top_sp])

  %opts are weird

=cut
sub fit_to_bound {	
	my $self = shift;
	my ($bound, $border, $opt) = @_;
	my @bound = @$bound; # required argument
	my @border;
	if(ref($border) eq "ARRAY") {
		@border = @$border;
# 		print "calculating adjustment for border @border\n";
# 		print "working with bound of @bound\n";
# 		print "border consists of $border[0][0], $border[0][1],",  
#				"as well as $border[1][0] and $border[1][1]\n";exit;
		for(my $pt =0; $pt <scalar(@border); $pt++) {
			foreach my $c (0,1) {
				$bound[$pt][$c] += $border[$pt][$c];
			}
		}
	}
	my (@just_pt, @center, @from_pt, @use_ext);
	my ($world_ptx, $world_pty, $scale);
	my %opts;
	if(ref($opt) eq "HASH") {
		%opts = %$opt;
		if($opts{scale}) {
			$scale = $opts{scale};
# 			print "got scale option $scale\n";
		}
		if($opts{justify}) {
			@just_pt = @{$opts{justify}};
		}
		if($opts{from}) {
			@from_pt = @{$opts{from}};
			$scale or croak("must have scale to use",
 				"\"from\" option in fit_to_bound\n");
		}
		if($opts{center}) {
			@center = @{$opts{center}};
		}
		if($opts{use_extents}) {
			# XXX experimental and undocumented
			@use_ext = @{$opts{use_extents}};
		}
		
	}
	# Method is to scale and then move to fit into the given boundary
	# Calculate orthographic extents of real-world geometry
	unless($scale && (@from_pt)) {
		# XXX undocumented config:
		my @realbound = (@use_ext ? @use_ext : $self->OrthExtents());
# 		print "got boundary of @realbound\n";
# 		print "this translates to @{$realbound[0]} and @{$realbound[1]}\n";
		# Calculate height and width of real-world bounding box
		my $width_world = $realbound[0][1] - $realbound[0][0];
		$world_ptx = $realbound[0][0] + $width_world / 2;
		my $height_world = $realbound[1][1] - $realbound[1][0];
		$world_pty = $realbound[1][0] + $height_world / 2;
# 		print "calculated world size of $width_world,$height_world\n";
# 		print "calculated world center of $world_ptx,$world_pty\n";
		unless($scale) {
			# Calculate height and width of finite-space (given) bounding box
			my $width_finite = $bound[1][0] - $bound[0][0];
			my $height_finite = $bound[1][1] - $bound[0][1];
			# Calculate scale factor (least of the two quotients)
			$scale = (sort({$a<=>$b} 
					($width_finite / $width_world), 
					($height_finite / $height_world) ) )[0];
		}
	}
	else {
		($world_ptx, $world_pty) = @from_pt;
	}
	# Apply scaling
    # print "scaling by factor of $scale using point $world_ptx, $world_pty\n";
	$self->GroupScale($scale, [$world_ptx, $world_pty]);
	# Apply movement: 
	unless(@center) {
		@center = map({($bound[0][$_] + $bound[1][$_]) / 2} 0,1);
	}
	my $movex = $center[0] - $world_ptx;
	my $movey = $center[1] - $world_pty;
	# print "moving by $movex, $movey\n";
	# print "trying to reach center @center\n";
	if(@just_pt) { # paper covers rock
		$movex = $just_pt[0] - $world_ptx;
		$movey = $just_pt[1] - $world_pty;
	}
	$self->GroupMove([$movex, $movey]);
	return($scale);
} # end subroutine fit_to_bound definition
########################################################################

=head2 get_clip_points

Returns a polyline in terms of image pixels.  If a rectangle was stored
in the image, translates this to a polyline that will be clockwise from
lower-left after being switched to world coordinates.

If there are no clip points, the image boundary will be returned.

  $drw->get_clip_points($addr);

=cut
sub get_clip_points {
	my $self = shift;
	my ($addr) = @_;
	($addr->{type} eq "images") or croak("not an image\n");
	my $obj = $self->getobj($addr);
	if($obj->{clipping}) {
		my @imgpoints = @{$obj->{clipping}};
		my @points;
		my $num = scalar(@imgpoints);
		if($num == 2) {
			my @x = sort({$a<=>$b} $imgpoints[0][0], $imgpoints[1][0]);
			my @y = sort({$a<=>$b} $imgpoints[0][1], $imgpoints[1][1]);
			@points = (	# make a polyline that is ccw from lower left
					[ $x[0], $y[1] ], 
					[ $x[1], $y[1] ],
					[ $x[1], $y[0] ],
					[ $x[0], $y[0] ]
					);
		}
		elsif($num > 2) {
			for(my $pt = 0; $pt < $num; $pt++) {
				$points[$pt] = [@{$imgpoints[$pt]}];
			}
		}
		else {
			return();
		}
#        $image_debug && print "yes have points @points\n";
		return(@points);	
	}
	else {
		# just give the extents pixels
		my @points = $self->get_image_rectangle($addr);
		return(@points);
	}
} # end subroutine get_clip_points definition
########################################################################

=head2 get_world_clip_points

  $drw->get_world_clip_points($addr);

=cut
sub get_world_clip_points {
	my $self = shift;
	my ($addr) = @_;
	my @points = $self->get_clip_points($addr);
	if(@points) {
		@points = map({[$self->img_to_drw($_, $addr)]} @points);
		return(@points);
	}
	return();
} # end subroutine get_world_clip_points definition
########################################################################

=head2 get_image_rectangle

  $drw->get_image_rectangle($addr);

=cut
sub get_image_rectangle {
	my $self = shift;
	my $addr = shift;
	($addr->{type} eq "images") or croak("not an image\n");
	my $obj = $self->getobj($addr);
	my @points = (
		[0, $obj->{size}[1]],
		[@{$obj->{size}}], 
		[$obj->{size}[0], 0],
		[0,0]
		);
	return(@points);
} # end subroutine get_image_rectangle definition
########################################################################

=head2 get_world_image_rectangle

  $drw->get_world_image_rectangle();

=cut
sub get_world_image_rectangle {
	my $self = shift;
	my $addr = shift;
	($addr->{type} eq "images") or croak("not an image\n");
	my @points = map({[$self->img_to_drw($_, $addr)]}
		$self->get_image_rectangle($addr)
		);
	return(@points);
} # end subroutine get_world_image_rectangle definition
########################################################################

=head1 Image Pixel Calculations

These allow you to translate between drawing space and image space.

=head2 drw_to_img

Returns the ($i,$j) pixel in (left-handed (typical)) image coordinates
corresponding to the [$x,$y] value of @point.

Floating point values will be returned.  Do your own rounding!

  $drw->drw_to_img(\@point, $addr);

=cut
sub drw_to_img {
	my $self = shift;
	my ($pt, $addr) = @_;
	my $obj = $self->getobj($addr);
	$obj or croak ("no image at $addr->{layer}, $addr->{id}");
	my @point = @$pt;
	my $nx = ($point[0] - $obj->{pt}[0] ) / $obj->{vector}[0][0];
	my $ny = $obj->{size}[1] - 
			($point[1] - $obj->{pt}[1] ) / $obj->{vector}[1][1];
	return($nx, $ny);
} # end subroutine drw_to_img definition
########################################################################

=head2 img_to_drw

Returns the world ($x, $y) location corresponding to the image pixels in
@pixel.

  $drw->img_to_drw(\@pixel, $addr);

=cut
sub img_to_drw {
	my $self = shift;
	my ($pixel, $addr) = @_;
	my $obj = $self->getobj($addr);
	$obj or croak ("no image at $addr->{layer}, $addr->{id}");
	my @point = @$pixel;
	my $px = ($point[0] - 0.5) * $obj->{vector}[0][0] + $obj->{pt}[0];
	my $py = $obj->{pt}[1] + 
			($obj->{size}[1] - $point[1]+0.5) * $obj->{vector}[1][1];
	return($px,$py);
} # end subroutine img_to_drw definition
########################################################################
1;
