package CAD::Drawing::Manipulate::Transform;
our $VERSION = '0.02';

# use CAD::Drawing;
use CAD::Drawing::Defined;

use Math::Vec qw(NewVec);
use Math::MatrixReal;

require Exporter;
@ISA = 'Exporter';
@EXPORT_OK = qw (
	build_matrix
	transform_pt
	);

use warnings;
use strict;
use Carp;
########################################################################

=pod

=head1 NAME

CAD::Drawing::Manipulate::Transform - Matrix methods for CAD::Drawing

=head1 DESCRIPTION

Provides 3D transformation methods (based on traditional matrix
algorithms) for Drawing.pm objects.

=head1 Coordinate System

All of these methods assume a RIGHT-HANDED coordinate system.  If you
are using a left-handed coordinate system, you are going to have
trouble, trouble, trouble.  We aren't making video games here!

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
  CAD::Drawing::Calculate
  CAD::Calc
  Math::Vec
  Math::Matrix

=cut
########################################################################

=head1 Methods

=cut
########################################################################

=head2 Transform

  $drw->Transform($addr, \%opts);

Options:

  normal_ready => [@normal_vec]  # no-questions-asked normal vector input

=cut
sub Transform {
	my $self = shift;
	my ($addr, $opts) = @_;

	# option handling:
	my $mat = build_matrix(%$opts);
	# ocs vs wcs handling:
	$self->to_wcs($addr);
	my $obj = $self->getobj($addr);
#    print "transforming\n";
	unless(defined($opts->{normal_ready})) {
		# normal data tag-along:
		my $n = $obj->{normal};
		$n || ($n = [0,0,1]);
		@$n = transform_pt($n, $mat);
		my $o = [0,0,0];
		@$o = transform_pt($o, $mat);	
		$obj->{normal} = [NewVec(NewVec(@$n)->Minus($o))->UnitVector()];
	}
	else {
#        print "over-ride: @{$opts->{normal_ready}}\n";exit;
		$obj->{normal} = [@{$opts->{normal_ready}}];
	}
	
	# pt vs pts:
	if(my $pt = $obj->{pt}) {
		@{$pt} = transform_pt($pt, $mat);
	}
	elsif(my $pts = $obj->{pts}) {
		foreach my $pt (@{$pts}) {
			@{$pt} = transform_pt($pt, $mat);
		}
	}
	else {
		croak("obj has no point or points!");
	}


} # end subroutine Transform definition
########################################################################
=head1 Non-OO Functions

=cut
########################################################################

=head2 build_matrix

Builds a linear transformation matrix according to %opts;

  $mat = build_matrix(%opts);

=over

=item Options:

  LTM => $ltm                  # pass-through for pre-built matrices
  R   => [$rX, $rY, $rZ]       # rotation about each axis
  T   => [$tX, $tY, $tZ]       # translation along each axis
  S   => [$sX, $sY, $sZ]       # scaling along each axis

=item Units:

Scaling is in decimal (e.g. $sX = 0.9 will scale by 90%)

=back

=cut
sub build_matrix {
	my (%opts) = @_;
	$opts{LTM} && return($opts{LTM});
	my $rotate    = Math::MatrixReal->new_diag([1,1,1,1]);
	my $translate = Math::MatrixReal->new_diag([1,1,1,1]);
	my $scale     = Math::MatrixReal->new_diag([1,1,1,1]);
	if($opts{R}) {
		my @r = rotation_matrices(@{$opts{R}});
		# ORDER IS SIGNIFICANT!
		$rotate = $r[0]*$r[1]*$r[2];
	}
	if($opts{T}) {
		$translate = translation_matrix(@{$opts{T}});
	}
	if($opts{S}) {
		$scale = scaling_matrix(@{$opts{S}});
	}
	return($rotate*$translate*$scale);
} # end subroutine build_matrix definition
########################################################################

=head2 NewMat

Calls Math::MatrixReal->new_from_rows([@_]) see Math::MatrixReal for
methods which can be applied to the returned object.

  $mat = NewMat(@rows);

=cut
sub NewMat {
	return(Math::MatrixReal->new_from_rows([@_]));
} # end subroutine NewMat definition
########################################################################

=head2 transform_pt

Applies matrix multiplication to linearly transform @pt by $mat.  This
eliminates the tedium of making new matrices just to multiply one point.

  @pt = transform_pt(\@pt, $mat);

=cut
sub transform_pt {
	my ($point, $mat) = @_;
	my @pt = @$point;
	defined($pt[2]) || ($pt[2] = 0);
	my $pt = Math::MatrixReal->new_from_cols([ [@pt[0..2], 1] ]);
	$pt = $mat*$pt;
#    print "now\n$pt\n";
#    my @this = @{$pt};
#    print "got @this\n";
#    print join("\n", map({$_->[0]} @{$this[0]})), "\n";
	return((map({$_->[0]} @{$pt->[0]}))[0..2]);
} # end subroutine transform_pt definition
########################################################################

=head2 rotation_matrices

Returns a list of matrices corresponding to ($rX, $rY, $rZ) 

Rotation is in ccw radians about each axis (right-hand rule) except
that they may be specified in degrees with $angle . "d"

  @rotations = rotation_matrices($rX, $rY, $rZ);

Resulting matrix will perform rotations in Z,Y,X order.

=cut
sub rotation_matrices {
	my(@R) = @_;
	foreach my $ang (@R) {
		if($ang =~ s/d$//) {
			$ang *= $pi / 180;
		}
	}
	return(
		NewMat( 
			[1,0,0,0],
			[0,  cos($R[0]), -sin($R[0]), 0 ],
			[0,  sin($R[0]),  cos($R[0]), 0 ],
			[0,  0,           0,          1 ],
			),
		
		NewMat(
			[ cos($R[1]), 0, sin($R[1]),  0],
			[ 0, 1, 0, 0],
			[ -sin($R[1]), 0, cos($R[1]), 0],
			[0, 0, 0, 1 ],
			),
		
		NewMat(
			[cos($R[2]), -sin($R[2]), 0, 0],
			[sin($R[2]), cos($R[2]), 0, 0],
			[0, 0, 1, 0],
			[0, 0, 0, 1],
			)
	);
} # end subroutine rotation_matrices definition
########################################################################

=head2 translation_matrix

Builds a linear transformation tranlation matrix from @trans, where
@trans = ($trX, $trY, $trZ).

  $mat = translation_matrix(@trans);

=cut
sub translation_matrix {
	my(@T) = @_;
	my $mat = NewMat(
		[1, 0, 0, $T[0]],
		[0, 1, 0, $T[1]],
		[0, 0, 1, $T[2]],
		[0, 0, 0,  1]
		);
	return($mat);
} # end subroutine translation_matrix definition
########################################################################

=head2 scaling_matrix

Builds a linear tranformation matrix from @scales, where @scales =
($sX, $sY, $sZ).

  $mat = scaling_matrix(@scales);

=cut
sub scaling_matrix {
	my(@S) = @_;
	my $mat = NewMat(
		[$S[0], 0,     0,     0],
		[0,     $S[1], 0,     0],
		[0,     0,     $S[2], 0],
		[0,     0,     0,     1]
		);
	return($mat);
} # end subroutine scaling_matrix definition
########################################################################


1;
