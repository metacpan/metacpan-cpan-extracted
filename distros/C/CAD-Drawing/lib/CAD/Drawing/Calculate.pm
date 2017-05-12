package CAD::Drawing::Calculate;
our $VERSION = '0.12';

# use CAD::Drawing;
use CAD::Drawing::Defined;
use CAD::Drawing::Calculate::Finite;

our @ISA = qw(
	CAD::Drawing::Calculate::Finite
	);

use CAD::Calc qw(
	dist2d
	line_intersection
	);

use Math::Vec qw(NewVec);

use vars qw(
	@orthfunc
	);

use warnings;
use strict;
use Carp;
########################################################################
=pod

=head1 NAME

CAD::Drawing::Calculate - Calculations for CAD::Drawing

=head1 DESCRIPTION

This module provides calculation functions for the CAD::Drawing family
of modules.

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
  CAD::Calc
  Math::Vec

=cut
########################################################################

=head1 Methods

=cut
########################################################################

=head1 Extents Calculations

=head2 OrthExtents

Calculates the extents of a group of objects (selected according to select_addr()) and returns an array: [xmin,xmax],[ymin,ymax].

  @extents = $drw->OrthExtents(\%opts);

=cut
sub OrthExtents {
	my $self = shift;
	my($opts) = @_;
	my $retref = $self->select_addr($opts);
	my @worklist = @{$retref};
	my(@xvals, @yvals);
	foreach my $addr (@worklist) {
		my ($xdata, $ydata) = $self->EntOrthExtents($addr);
		push(@xvals, @$xdata);
		push(@yvals, @$ydata);
	}
	@xvals = sort({$a<=>$b} @xvals);
	@yvals = sort({$a<=>$b} @yvals);
	return([ $xvals[0], $xvals[-1] ], [$yvals[0], $yvals[-1] ] );
} # end subroutine OrthExtents definition
########################################################################

=head2 getExtentsRec

Alias to OrthExtents() which returns a polyline-form array of points
(counter clockwise from lower-left) describing a rectangle.

  @rec = $drw->getExtentsRec(\%opts);

=cut
sub getExtentsRec {
	my $self = shift;
	my($opts) = @_;
	my ($x, $y) = $self->OrthExtents($opts);
	return( 
		[$x->[0], $y->[0]],
		[$x->[1], $y->[0]],
		[$x->[1], $y->[1]],
		[$x->[0], $y->[1]],
		);
} # end subroutine getExtentsRec definition
########################################################################

=head2 EntOrthExtents

Gets the orthographic extents of the object at $addr.  Returns 
[\@xpts,\@y_pts] (leaving you to sort through them and find which 
is min or max.)

  @extents = $drw->EntOrthExtents($addr);

=cut
sub EntOrthExtents {
	my $self = shift;
	my ($addr) = @_;
	my $obj = $self->getobj($addr);
	# FIXME: this will only get the point items
	my $stg = $call_syntax{$addr->{type}}[1];
	my ($xpts, $ypts) = $orthfunc[0]{$stg}->($obj->{$stg});
} # end subroutine EntOrthExtents definition
########################################################################

=head2 @orthfunc

List of hash references containing code references to reduce
duplication and facilitate natural flow (rather than ifififif
statements.)

=cut

@orthfunc = (
	{ # stage one hash ref
		"pt" => sub {
			my($pt) = @_;
			return([$pt->[0]], [$pt->[1]]);
		}, # end subroutine $orthfunc[0]{pt} definition
		"pts" => sub {
			my($pts) = @_;
			my @vals = ([], []);
			for(my $i = 0; $i < @$pts; $i++) {
				foreach my $c (0,1) {
					push(@{$vals[$c]}, $pts->[$i][$c]);
				}
			}
			return(@vals);
		}, # end subroutine $orthfunc[0]{pts} definition
	}, # end stage one hash ref
	{ # stage two hash ref
		# FIXME: here we put the fun stuff about rad and text
	}, # end stage two hash ref
); # end @orthfunc bundle
########################################################################

=head1 Planar Geometry Methods

=head2 offset

Intended as any-object offset function (not easy).

$dist is negative to offset outward

  $drw->offset($object, $dist);

=cut
sub offset {
	carp("no offset function yet");
} # end subroutine offset definition
########################################################################

=head2 divide

  $drw->divide();

=cut
sub divide {
	carp("no divide function yet");
} # end subroutine divide definition
########################################################################

=head2 area

  $drw->area($addr);

=cut
sub area {
	my $self = shift;
	my $addr = shift;
	($addr->{type} eq "plines") or croak "only calc area for plines";
	my @pgon = $self->Get("pts", $addr);
	my $tw_area = 0;
	my $x = 0;
	my $y = 1;
	for(my $i = 0; $i < @pgon; $i++) {
		$tw_area += ($pgon[$i][$y] + $pgon[$i-1][$y]) * 
					($pgon[$i][$x] - $pgon[$i-1][$x]);
		}
	return( abs($tw_area / 2) );
} # end subroutine area definition
########################################################################

=head1 Line Manipulations

=head2 pline_to_ray

Transforms a polyline with a nubbin into a ray (line with direction.)

  $line_addr = $drw->pline_to_ray($pline_addr);

=cut
sub pline_to_ray {
	my $self = shift;
	my ($pl_addr) = @_;
	($pl_addr->{type} eq "plines") || carp("not a polyline");
	my @pts = $self->Get("pts", $pl_addr);
	(@pts == 3) || croak("not 3 points to polyline");
#	print "checking: ", dist2d($pts[0], $pts[1]) ,
#						"<=>", 
#						dist2d($pts[1], $pts[2]), 
#			"\n";
	my $dir = dist2d($pts[0], $pts[1]) <=> dist2d($pts[1], $pts[2]);
	($dir > 0) || (@pts = reverse(@pts));
	my $obj = $self->getobj($pl_addr);
	my %lineopts = (
		"layer" => $pl_addr->{layer},
		"color" => $obj->{color},
		"linetype" => $obj->{linetype},
		);
	return($self->addline([@pts[0,1]], \%lineopts) );
} # end subroutine pline_to_ray definition
########################################################################

=head2 trim_both

Trims two lines to their intersection.

  $drw->trim_both($addr1, $addr2, $tol, \@keep_ends);

See CAD::Calc::line_intersection()

=cut
sub trim_both {
	my $self = shift;
	my @items = (shift,shift);
	my $tol = shift;
	my $ends = shift;
	my @keep_ends;
	if($ends) {
		(ref($ends) eq "ARRAY") or croak(
			'CAD::Drawing::Calculate::trim_both() ' .
			'\@keep_ends arg must be array'
			);
		@keep_ends = @$ends;
	}
	my @lines;
	my @vecs;
	my @mids;
	foreach my $item (@items) {
		$item or die "no item\n";
		my @pts = $self->Get("pts", $item);
#        @pts or die "problem with $item\n";
		# print "points: @{$pts[0]}, @{$pts[1]}\n";
		my $vec = NewVec(NewVec(@{$pts[1]})->Minus($pts[0]));
		my $mid = [NewVec($vec->ScalarMult(0.5))->Plus($pts[0])];
		push(@mids, $mid);
		push(@vecs, $vec);
		push(@lines, [@pts]);
	}
	my @int = line_intersection(@lines, $tol);
	## defined($int[0]) or print("no int\n");
	defined($int[0]) or return();
	## defined($int[1]) or print("paralell (no)\n");
	defined($int[1]) or return(); #parallel
#    print "making vec from @int\n";
	my $pt = NewVec(@int);
#    print "got point: @$pt\n";
	foreach my $i (0,1) {
		my $end;
		if(@keep_ends) {
			$end = ! $keep_ends[$i];
		}
		else {
			my $dot = $vecs[$i]->Dot([$pt->Minus($mids[$i])]);
			# print "dot product: $dot\n";
			# if the dot product is positive, 
			#   intersection is in front of midpoint.
			$end = ($dot > 0);
		}
		# print "end is $end\n";
		$lines[$i][$end]  = $pt;
		$self->Set({pts => $lines[$i]}, $items[$i]);
	}

	return($pt);

	

} # end subroutine trim_both definition
########################################################################

=head1 Coordinate Transforms

Switch between coordinate system representations.

=head2 to_ocs

Change the objects coordinates into the object coordinate system.

Both of these are relatively quick.  A simple test shows that one point
can be taken back and forth at about 2KHz, so don't be afraid to use
them.

  $drw->to_ocs($addr);

=cut
sub to_ocs {
	my $self = shift;
	my ($addr) = @_;
	my $obj = $self->getobj($addr);
	if(my $n = $obj->{normal}) {
		# FIXME: if direction is Z, kill the flags
#        print "normal is @$n\n";
		if($ac_storage_method{$addr->{type}} eq "ocs") {
			# need to translate
			my @ocs = _ocs_axes(@{$n});
#            print "ocs is: ", join("\n", map({join(",", @{$_})} @ocs)), "\n";
			if($obj->{pts}) {
				foreach my $pt (@{$obj->{pts}}) {
					@{$pt} = map({$ocs[$_]->Comp($pt)} 0..2);
				}
			}
			else {
				# safe to assume it is a point?
				@{$obj->{pt}} = map({$ocs[$_]->Comp($obj->{pt})} 0..2);
			}
		} # end if stored in ocs
		$obj->{extrusion} = $n;
		delete($obj->{normal});
	}
	else { # object is in xy coords with normal in [0,0,1] direction
		return();
	}

} # end subroutine to_ocs definition
########################################################################

=head2 to_wcs

Change the object's coordinates into the world coordinate system.

  $drw->to_wcs($addr);

=cut
sub to_wcs {
	my $self = shift;
	my ($addr) = @_;
	my $obj = $self->getobj($addr);
	if(my $n = $obj->{extrusion}) {
		# FIXME: if direction is Z, kill the flags

		# also have to check if this object is stored as WCS or OCS?
		if($ac_storage_method{$addr->{type}} eq "ocs") {
			# need to translate
			my @ocs = _ocs_axes(@{$n});
			my @tcs = _wcs_axes(@ocs);
			if($obj->{pts}) {
				foreach my $pt (@{$obj->{pts}}) {
#                    warn("pt was: ", join(",", @{$pt}), "\n");
					@{$pt} = map({$tcs[$_]->Comp($pt)} 0..2);
#                    warn("pts being transformed for $addr->{type} ", 
#                        join(",", @{$pt}), "\n");
				}
			}
			else {
				# safe to assume it is a point?
#                warn("pt was: ", join(",", @{$obj->{pt}}), "\n");
				@{$obj->{pt}} = map({$tcs[$_]->Comp($obj->{pt})} 0..2);
#                warn("pt being transformed for $addr->{type} ", 
#                    join(",", @{$obj->{pt}}), "\n");
			}
		} # end if stored in ocs
		$obj->{normal} = $n;
		delete($obj->{extrusion});
	}
	else { # object is in xy coords with normal in [0,0,1] direction
		return();
	}
} # end subroutine to_wcs definition
########################################################################

=head2 flatten

Puts the object in the wcs, zeros all z-coordinates and deletes the
normal vector.  Note that this is fine for projecting polylines and
lines, but may not be what you want if you are trying to make a circle
into an ellipse (at least not yet.)

  $drw->flatten($addr);

=cut
sub flatten {
	my $self = shift;
	my ($addr) = @_;
	$self->to_wcs($addr);
	my $obj = $self->getobj($addr);
	if($obj->{pts}) {
		foreach my $pt (@{$obj->{pts}}) {
			$pt->[2] = 0;
		}
	}
	else {
		$obj->{pt}[2] = 0;
	}
	delete($obj->{normal});
} # end subroutine flatten definition
########################################################################

=head1 Functions

Non-OO internal-use functions.

=head2 _ocs_axes

Returns the x,y, and z axes for the ocs described by @normal.  These
will have arbitrary lengths.

  @local_axes = _ocs_axes(@normal);

=cut
sub _ocs_axes {
	my $z = NewVec(@_);
	my $x = NewVec(NewVec(0,0,1)->Cross($z));
	($x->Length()) || ($x = NewVec($z->[2],0,0));
	my $y = NewVec($z->Cross($x));
	return($x,$y,$z);
} # end subroutine _ocs_axes definition
########################################################################

=head2 _wcs_axes

Returns the x,y, and z axes for the world coordinate system in terms of
the @ocs_axes.

  @trs_axes = _wcs_axes(@ocs_axes);

=cut
sub _wcs_axes {
	my (@ocs) = map({NewVec(@$_)} @_);
	my @tcs;
	my @wcs = map({NewVec(@$_)} [1,0,0],[0,1,0],[0,0,1]);
	foreach my $i (0..2) {
		$tcs[$i] = NewVec(map({$ocs[$_]->Comp($wcs[$i])} 0..2));
	}
	return(@tcs);
} # end subroutine _wcs_axes definition
########################################################################
1;
