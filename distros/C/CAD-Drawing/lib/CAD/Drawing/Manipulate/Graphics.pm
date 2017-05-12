package CAD::Drawing::Manipulate::Graphics;
our $VERSION = '0.02';

use CAD::Drawing;
use CAD::Drawing::Defined;
use Image::Magick;
push(@CAD::Drawing::ISA, __PACKAGE__);

use warnings;
use strict;
use Carp;

=pod

=head1 Name

CAD::Drawing::Manipulate::Graphics - Gimp meets CAD?

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

=cut
########################################################################

=head1 Methods

All of these are CAD::Drawing methods (I force my own inheritance:)

=cut
########################################################################

=head2 image_init

Initialize the image at $addr based on the value at the fullpath key.
This establishes the contained Image::Magick object and loads the image
into memory in the image_handle key.

  $drw->image_init($addr);

=cut
sub image_init {
	my $self = shift;
	my ($addr) = @_;
	($addr->{type} eq "images") or croak("item is not an image\n");
	my $obj = $self->getobj($addr);
	my $name = $obj->{fullpath};
	(-e $name) or croak("$name does not exist\n");
	# print "loading $name ...\n";
	my $im = Image::Magick->new();
	my $err = $im->Read($name);
	$err && carp("read $name gave $err\n");
	$obj->{image_handle} = $im;
} # end subroutine image_init definition
########################################################################

=head2 image_crop

Crops an image and its definition (actually, changes its insert point)
according to the points given by @crop_points (which maybe had better be
within the object (but I don't really sweat that.))

@crop_points should be in world coordinates as follows:

  @crop_points = (
    [$lower_left_x , $lower_left_y ],
	[$upper_right_x, $upper_right_y],
	);
  # note that you can get these as 
  # ($drw->getExtentsRec($something))[0,2]

  $drw->image_crop($addr, \@crop_points);

=cut
sub image_crop {
	my $dbg = 0;
	my $self = shift;
	my ($addr, $crp_pts) = @_;
	($addr->{type} eq "images") or croak("not an image\n");
	my $obj = $self->getobj($addr);
	(ref($crp_pts) eq "ARRAY") or croak("$crp_pts is not array\n");
	(@$crp_pts == 2) or croak("crop points should be 2\n");
	# need upper left first
	my @crop_start = map({sprintf("%0.0f", $_)}
		$self->drw_to_img(
			[
				$crp_pts->[0][0], # leftmost x
				$crp_pts->[1][1]  # uppermost y
			], 
			$addr)
		);
	my @crop_stop  = map({sprintf("%0.0f", $_)}
		$self->drw_to_img(
			[
				$crp_pts->[1][0],  # rightmost x
				$crp_pts->[0][1]   # lowermost y
			],
			$addr)
		);
	my @ext = map({$crop_stop[$_] - $crop_start[$_]} 0,1);
	my $im = $obj->{image_handle};
	my @old_ext = $self->get_world_image_rectangle($addr);
	$dbg && print "old extents @{$obj->{size}}\n";
	$dbg && print "new extents: @ext\n";
	$dbg && print "start crop: @crop_start\n";
	$dbg && print "stop  crop: @crop_stop\n";
	$im->Crop(
		width => $ext[0], height => $ext[1],
		x => $crop_start[0], y => $crop_start[1],
		);
	my @sz = $im->Get("width", "height");
	$dbg && print "check: @sz\n";

	# image processing does strange things, so we use the size reported
	# by Image::Magick to reset the insert point and size of the image
	my @new_base = (
		$crop_start[0],
		$crop_start[1] + $sz[1],
		);
	my @new_pt = $self->img_to_drw(\@new_base, $addr);
	$dbg && print "old insert: @{$obj->{pt}}\n";
	$dbg && print "new basepoint: @new_base at @new_pt\n";
	$obj->{pt} = [@new_pt];
	$obj->{size} = [@sz];
	if(0) {
		my $check = CAD::Drawing->new();
		$check->addpolygon(\@old_ext);
		$check->addrec($crp_pts, {color => "blue"});
		$check->addpolygon(
			[$self->get_world_image_rectangle($addr)], {color => "red"}
			);
		$check->show(hang=>1);
		exit;
	}
} # end subroutine image_crop definition
########################################################################

=head2 image_scale

Scales both the image and the definition by $scale, starting at
@base_point.

  $drw->image_scale($addr, $scale, \@base_point);

=cut
sub image_scale {
	my $self = shift;
	my ($addr, $scale, $point) = @_;
	($addr->{type} eq "images") or croak("not an image\n");
	# this sets only the insert:
	$self->Scale($addr, $scale, $point);
	# maybe not scale image here (punt like autoheck)
	my $obj = $self->getobj($addr);
	# really should put this in the manipulate code?
	$obj->{vector}[0][0] *=$scale;
	$obj->{vector}[1][1] *=$scale;
	print "vectors now $obj->{vector}[0][0], $obj->{vector}[1][1]\n";
} # end subroutine image_scale definition
########################################################################

=head2 image_rotate

This leaves the definition orthoganal, expands the underlying image
object, and resets the insert point and size properties accordingly.

  $drw->image_rotate($addr, $angle, \@point);

The current implementation does not handle the change to the image
clipping boundary.

=cut
sub image_rotate {
	my $dbg = 0;
	my $check = 0;
	# FIXME: must be a better way to do this:
	my $bgcolor = "gold";
	my $self = shift;
	my ($addr, $ang, $pt) = @_;
	($addr->{type} eq "images") or croak("not an image\n");
	my $obj = $self->getobj($addr);
	my $im = $obj->{image_handle};
	# Ben Franklin was retarded
	my $cw_deg_ang = $ang * -180 / $pi;
	# image rotates inside the box:
	$im->Rotate(degrees => $cw_deg_ang);
	# but now we have to change the box
	my ($w, $h) = $im->Get("width", "height");
	$dbg && print "size now $w x $h\n";
	# so we make a fake version of the image:
	my @pts = $self->get_world_image_rectangle($addr);
	print "points: \n\t", join("\n\t", map({join(",", @$_[0,1])} @pts)), "\n";
	my $scrpad = CAD::Drawing->new();
	my $box = $scrpad->addpolygon([map({[@$_]} @pts)]);
	# and rotate that
	$dbg && print "rotating about @$pt\n";
	$scrpad->Rotate($box, $ang, $pt);
	print "points: \n\t", join("\n\t", map({join(",", @$_[0,1])} @pts)), "\n";
	my @ext = $scrpad->getExtentsRec([$box]);
	$check && $scrpad->addcircle($pt, 10, {color => "red"});
	$check && $scrpad->addpolygon(\@pts, {color => "green"});
	$check && $scrpad->addpolygon(\@ext, {color => "red"});
	$check && $scrpad->addcircle($ext[0], 5, {color => "blue"});
	# so the lower-left of the extents is our new insert:
	my @insert = @{$ext[0]};
	$obj->{pt} = [@insert];
	$dbg && print "new insert: @insert\n";
	$check && $scrpad->show(hang=>1);
	$check && exit;
	# set the size and we're done
	$obj->{size} = [$w, $h];
} # end subroutine image_rotate definition
########################################################################

=head2 image_swap_context

This involves a scaling of the image (the contexts should be aligned
over each other at this point or everything will go to hell.)  Do your
own move / rotate / crop before calling this, because all this does is
to scale the underlying image object such that the vec property of the
image definition at $dest_addr can be used correctly.

Note that this does not "swap" the image to $dest_addr, rather it uses
the image definition of $dest_addr to change the image object and
definition at $source_addr.

Also note that the image must fit completely inside (I think) of the
destination in order for the composite to work correctly.

  $drw->image_swap_context($source_addr, $dest_addr);

=cut
sub image_swap_context {
	my $dbg = 0;
	my $self = shift;
	my ($s_addr, $d_addr) = @_;
	my $bgcolor = "gold";
	($s_addr->{type} eq "images") or croak("not an image\n");
	($d_addr->{type} eq "images") or croak("not an image\n");
	my $obj = $self->getobj($s_addr);
	# note: we will kill this one:
	my $im_in = $obj->{image_handle};
	# determine the scale difference between the two definitions
	my $dvecs = $self->Get("vector", $d_addr);
	my $svecs = $self->Get("vector", $s_addr);
	my @scale = (
		$dvecs->[0][0] / $svecs->[0][0],
		$dvecs->[1][1] / $svecs->[1][1],
		);
	$dbg && print "vecs scale at @scale\n";
	my ($w, $h) = map({sprintf("%0.0f", $_ * $scale[0])}
		$im_in->Get("width", "height")
		);
	$im_in->Scale("width" => $w, "height" => $h);
	$dbg && print "size now $w x $h (hopefully)\n";
	$dbg && print "checking: ", 
		join(" x ", $im_in->Get("width", "height")), "\n";
	# and set the vecs
	$obj->{vector} = [map({[@$_]} @$dvecs)];
	# and the size
	$obj->{size} = [$w, $h];
	# need to create a new image object which represents the destination
	# size and find the points where this one fits into that.
	my $d_size = $self->Get("size", $d_addr);
	my $im_out = Image::Magick->new();
	$im_out->Set(size => sprintf("%0.0fx%0.0f", @$d_size));
	$dbg && print "filling new image at @$d_size\n";
	$im_out->Read("xc:$bgcolor");
	$im_out->Transparent("color" => $bgcolor);
	# dot each corner for justification into other images
	my $color = $aci2hex[$self->Get("color", $s_addr)];
	$dbg && print "output dot color: $color\n";
	my $x = $d_size->[0] - 1;
	my $y = $d_size->[1] - 1;
	$im_out->Set("pixel[0,0]" => $color);
	$im_out->Set("pixel[$x,0]" => $color);
	$im_out->Set("pixel[0,$y]" => $color);
	$im_out->Set("pixel[$x,$y]" => $color);
	# determine placement from 0,0 of source mapped onto dest:
	my @placement = map({sprintf("%0.0f", $_)}
		$self->drw_to_img([$self->img_to_drw([0,0], $s_addr)], $d_addr) 
		);
	$dbg && print "compositing...\n";
	$im_out->Composite(
		compose => "Over", image => $im_in,
		x => $placement[0], y => $placement[1] 
		);
	$dbg && print "done\n";
	$obj->{image_handle} = $im_out;
	undef($im_in);
	# set the size, so it will be proper
} # end subroutine image_swap_context definition
########################################################################

1;
