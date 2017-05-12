package CAD::Drawing::Manipulate;
our $VERSION = '0.12';

# use CAD::Drawing;
use CAD::Drawing::Defined;
use CAD::Drawing::Manipulate::Transform;

our @ISA = qw(
	CAD::Drawing::Manipulate::Transform
	);

use Math::Geometry::Planar;
use CAD::Calc qw(signdist);

use vars qw(
		%movefunc
		@mirrorfunc
		@scalefunc
		@rotatefunc
		);

use warnings;
use strict;
use Carp;
########################################################################
=pod

=head1 NAME

CAD::Drawing::Manipulate - Manipulate CAD::Drawing objects

=head1 Description

Move, Copy, Scale, Mirror, and Rotate methods for single entities and
groups of entities.

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

=head1 Group Methods

These methods are called with required values, followed by a hash
reference of option values.  Note the difference between this and the
individual entity manipulation syntax shown below.  The absence of an
\%options hash reference implies everything in the drawing.

For details about each of the group manipulation methods, see the
corresponding individual entity manipulation method.

=head2 Options

The $opts value shown for each of the group manipulation methods is fed
directly to CAD::Drawing::select_addr().  See the documentation for
this function for additional details.

One of the most common methods of selection (after the implicit all)
may be the explicit list of addresses.  This is done by simply passing
an array reference rather than a hash reference.

=cut
########################################################################

=head2 GroupMove

Move selected entities by @dist.

  $drw->GroupMove(\@dist, $opts);

=cut
sub GroupMove {
	my $self = shift;
	my ($dist, $opts) = @_;
	my $retref = $self->select_addr($opts);
	foreach my $addr (@$retref) {
		$self->Move($addr, $dist);
		}
} # end subroutine GroupMove definition
########################################################################

=head2 GroupCopy

Returns a list of addresses for newly created entities.

  @new = $drw->GroupCopy(\@dist, $opts);

=cut
sub GroupCopy {
	my $self = shift;
	my ($dist, $opts) = @_;
	my $retref = $self->select_addr($opts);
	my @outlist;
	foreach my $addr (@$retref) {
		push(@outlist, $self->Copy($addr, $dist));
		}
	return(@outlist);
} # end subroutine GroupCopy definition
########################################################################

=head2 GroupClone

Returns a list of addresses for newly created entities.

  @new = $drw->GroupClone($dest, $opts);

=cut
sub GroupClone {
	my $self = shift;
	my ($dest, $opts) = @_;
	my $retref = $self->select_addr($opts);
	my @outlist;
	foreach my $addr (@$retref) {
		push(@outlist, $self->Clone($addr, $dest, $opts));
		}
	return(@outlist);
} # end subroutine GroupClone definition
########################################################################

=head2 place

Clones items from $source into $drw and moves them to @pt.  Selects items according to %opts and optionally rotates them by $opts{ang} (given in radians.)

  $drw->place($source, \@pt, \%opts);

=cut
sub place {
	my $self = shift;
	my ($source, $pt, $opts) = @_;
	my %options;
	(ref($opts) eq "HASH") && (%options = %$opts);
	my @newlist = $source->GroupClone($self, $opts);
	if($options{ang}) {
		$self->GroupRotate($options{ang}, \@newlist);
	}
	$self->GroupMove($pt, \@newlist);
#    print "worked\n";
	return(@newlist);
} # end subroutine place definition
########################################################################

=head2 GroupMirror

Mirrors the entities specified by %options (see select_addr()) across
@axis.

  @new = $drw->GroupMirror(\@axis, \%options);

=cut
sub GroupMirror {
	my $self = shift;
	my ($axis, $opts) = @_;
	my $retref = $self->select_addr($opts);
	my @outlist;
	foreach my $addr (@$retref) {
		push(@outlist, $self->Mirror($addr, $axis, $opts));
	}
	return(@outlist);
} # end subroutine GroupMirror definition
########################################################################

=head2 GroupScale

Sorry, \@pt is required here.

  $drw->GroupScale($factor, \@pt, \%opts);

=cut
sub GroupScale {
	my $self = shift;
	my ($factor, $pt, $opts) = @_;
	my $retref = $self->select_addr($opts);
	foreach my $addr (@$retref) {
		$self->Scale($addr, $factor, $pt);
	}
} # end subroutine GroupScale definition
########################################################################

=head2 GroupRotate

Rotates specified entities by $angle.  A center point may be specified
via $opts{pt} = \@pt.

  $drw->GroupRotate($angle, \%opts);

=cut
sub GroupRotate {
	my $self = shift;
	my ($angle, $opts) = @_;
	my %opt;
	(ref($opts) eq "HASH") && (%opt = %$opts);
	my @pt = (0,0);
	$opt{pt} && (@pt = @{$opt{pt}});
	my $retref = $self->select_addr($opts);
	foreach my $addr (@$retref) {
		$self->Rotate($addr, $angle, \@pt);
	}
} # end subroutine GroupRotate definition
########################################################################

=head1 Individual Methods

=cut
########################################################################

=head2 Move

Moves entity at $addr by @dist (@dist may be three-dimensional.)

  $drw->Move($addr, \@dist);

=cut
sub Move {
	my $self = shift;
	my ($addr, $dist) = @_;
	my $obj = $self->getobj($addr);
	my $mv_this = $call_syntax{$addr->{type}}[1];
	$movefunc{$mv_this}->($obj->{$mv_this}, $dist);
} # end subroutine Move definition
########################################################################
%movefunc = (
	"pt" => sub {
				my($pt, $dist) = @_;
				foreach my $c (0..2) {
					$pt->[$c] += $dist->[$c];
				}
			}, # end subroutine $movefunc{pt} definition
	"pts" => sub {
				my($pts, $dist) = @_;
				for(my $i = 0; $i < @$pts; $i++) {
					foreach my $c (0..2) {
						$pts->[$i][$c] += $dist->[$c];
					}
				}
			}, # end subroutine  $movefunc{pts} definition
	); # end %movefunc function hash definition
########################################################################

=head2 Copy

  $drw->Copy($addr, \@dist);

=cut
sub Copy {
	my $self = shift;
	my ($addr, $dist) = @_;
	$addr = $self->Clone($addr);
	$self->Move($addr, $dist);
	return($addr);
} # end subroutine Copy definition
########################################################################

=head2 Clone

Clones the entity at $addr into drawing $dest. 

  $drw->Clone($addr, $dest, \%opts);

%opts may contain:

  to_layer => $layer_name,  # layer to clone into

=cut
sub Clone {
	my $self = shift;
	my ($addr, $dest, $opts) = @_;
	my %opts;
	(defined($dest)) || ($dest = $self);
	if(ref($opts) eq "HASH") {
		%opts = %$opts;
		}
	my $type = $addr->{type};
	my $obj = $self->getobj($addr);
	$obj or croak("no object for $addr->{layer} $addr->{type} $addr->{id}");
	# first gather the required arguments
	my @args;
	my @argstrings = (@{$call_syntax{$type}});
	my $function = shift(@argstrings);
	# uses the object's current contents as the options hash
	my %optarg = %{$obj};
	foreach my $argstring ( @argstrings) {
		push(@args, $obj->{$argstring});
		delete($optarg{$argstring});
		}
	# now build the rest of the options hash
	$optarg{layer} = $addr->{layer};
	defined($opts{"to layer"}) && 
		($optarg{"layer"} = $opts{"to layer"}); # DEPRECATED!
	defined($opts{"to_layer"}) && 
		($optarg{"layer"} = $opts{"to_layer"});
	delete($optarg{addr});
#    print "layer cloned: $obj->{layer}\n";
	$addr = $dest->$function(@args, \%optarg);
#    print "landed on $addr->{layer}\n";
	return($addr);
} # end subroutine Clone definition
########################################################################

=head2 Mirror

Mirrors entity specified by $addr across @axis.

Returns the address of the manipulated entity.  If $opts{copy} is true,
will clone the entity, otherwise modify in-place.

  $drw->Mirror($addr, \@axis, \%opts);

=cut
sub Mirror {
	my $self = shift;
	my ($addr, $axis, $opts) = @_;
	my %opts;
	(ref($opts) eq "HASH") && (%opts = %$opts);
	$opts{copy} && ($addr = $self->Clone($addr));
	my $type = $addr->{type};
	my $obj = $self->getobj($addr);
	my $stg = $call_syntax{$type}[1];
	$mirrorfunc[0]{$stg}->($obj->{$stg}, $axis);
	my $syn_len = scalar(@{$call_syntax{$type}});
	for(my $i = 2; $i < $syn_len; $i++) {
		$stg = $call_syntax{$type}[$i];
		$mirrorfunc[1]{$stg} && $mirrorfunc[1]{$stg}->($obj, $axis);
		}
	return($addr);
} # end subroutine Mirror definition
########################################################################
@mirrorfunc = (
	{ # First hash for stage-1 operations
		"pt" => sub {
			my($pt, $axis) = @_;
				@{$pt} = pointmirror($axis, $pt);
			}, # end subroutine $mirror[0]{pt} definition
		"pts" => sub {
			my($pts, $axis) = @_;
			for(my $i = 0; $i < @$pts; $i++) {
				@{$pts->[$i]} = pointmirror($axis, $pts->[$i]);
				}
			}, # end subroutine $mirror[0]{pts} definition
		}, # end %{$mirrorfunc[0]} hash definition
	{ # Second hash for stage-2 operations
		"angs" => sub {
			my($obj, $axis) = @_;
			my $a_ang = angle_of($axis);
#            printf("angle:  %0.4f\n", $a_ang * 180 / $pi);
#            printf("s: %0.4f\n", $obj->{angs}[0] * 180 / $pi);
#            printf("e: %0.4f\n", $obj->{angs}[1] * 180 / $pi);
			$obj->{angs}[0] = $a_ang + ($a_ang - $obj->{angs}[0]);
			$obj->{angs}[1] = $a_ang + ($a_ang - $obj->{angs}[1]);
			@{$obj->{angs}} = reverse(@{$obj->{angs}});
			checkarcangs($obj->{angs});
#            printf("now s: %0.4f\n", $obj->{angs}[0] * 180 / $pi);
#            printf("now e: %0.4f\n", $obj->{angs}[1] * 180 / $pi);
			}, # end subroutine $mirrorfunc[1]{rad} definition
		}, # end %{$mirrorfunc[1]} hash definition
	); # end @mirrorfunc array definition
########################################################################

=head2 Scale

  $drw->Scale($addr, $factor, \@pt);

=cut
sub Scale {
	my $self = shift;
	my ($addr, $factor, $pt) = @_;
	my $obj = $self->getobj($addr);
	my $domove = (defined($pt->[0]) or defined($pt->[1]));
	$domove && ($self->Move($addr, [map({-$_} @$pt)]));
	my $stg = $call_syntax{$addr->{type}}[1];
	$scalefunc[0]{$stg}->($obj->{$stg}, $factor);
#    my $syn_len = scalar(@{$call_syntax{$addr->{type}}});
#    for(my $i = 2; $i < $syn_len; $i++) {
#        $stg = $call_syntax{$addr->{type}}[$i];
##        print "looking for $stg for $addr->{type}\n";
##        $scalefunc[1]{$stg} && print "ok, found it\n";
#        $scalefunc[1]{$stg} && $scalefunc[1]{$stg}->($obj, $factor);
#        }
	foreach my $key ( keys(%{$scalefunc[1]})) {
		defined($obj->{$key}) && $scalefunc[1]{$key}->($obj, $factor);
	}
	$domove && ($self->Move($addr, $pt));
} # end subroutine Scale definition
########################################################################
@scalefunc = (
	{ # First hash for stage-1 operations
		"pt" => sub {
			my($pt, $factor) = @_;
			foreach my $c (0..2) {
				$pt->[$c] *= $factor;
				}
			}, # end subroutine $scalefunc[0]{pt} definition
		"pts" => sub {
			my($pts, $factor) = @_;
			for(my $i = 0; $i < @$pts; $i++) {
				foreach my $c (0..2) {
					$pts->[$i][$c] *= $factor;
					}
				}
			}, # end subroutine $scalefunc[0]{pts} definition
		}, # end %{$scalefunc[0]} hash definition
	{ # Second hash for stage-2 operations
		"rad" => sub {
			my($hashref, $factor) = @_;
			$hashref->{rad} *= $factor;
			}, # end subroutine $scalefunc[1]{rad} definition
		"height" => sub {
			my($hashref, $factor) = @_;
			$hashref->{height} *= $factor;
			}, # end subroutine $scalefunc[1]{height} definition
		}, # end %{$scalefunc[1]} hash definition
); # end @scalefunc array definition
########################################################################

=head2 Rotate

Rotates entity specified by $addr by $angle (+ccw radians) about @pt.
Angle may be in degrees if $angle =~ s/d$// returns a true value (but I
hope the "d" is the only thing on the end, because I'm not looking for
anything beyond that.)  $angle = "45" . "d" will get converted, but
$angle = "45" . "bad" will be called 0.  Remember, this is Perl:)

  $drw->Rotate($addr, $angle, \@pt);

=cut
sub Rotate {
	my $self = shift;
	my ($addr, $angle, $pt) = @_;
	(ref($pt) eq "ARRAY") || ($pt = [0,0]);
	my $obj = $self->getobj($addr);
	my $type = $addr->{type};
	if($angle =~ s/d$//) {  
		# allow spec of angle in degrees with $angle . "d";
		$angle *= $pi / 180;
		}
	my $stg = $call_syntax{$type}[1];
	$rotatefunc[0]{$stg}->($obj->{$stg}, $angle, $pt);
	my $syn_len = scalar(@{$call_syntax{$type}});
	for(my $i = 2; $i < $syn_len; $i++) {
		$stg = $call_syntax{$type}[$i];
		$rotatefunc[1]{$stg} && $rotatefunc[1]{$stg}->($obj,$angle, $pt);
		}
} # end subroutine Rotate definition
########################################################################
@rotatefunc = (
	{ # First hash for stage-1 operations
		"pt" => sub {
			my($pt, $angle, $cpt) = @_;
				@{$pt}[0,1] = pointrotate(@{$pt}[0,1], $angle, @{$cpt});
			}, # end subroutine $rotatefunc[0]{pt} definition
		"pts" => sub {
			my($pts, $angle, $cpt) = @_;
			for(my $i = 0; $i < @$pts; $i++) {
				@{$pts->[$i]}[0,1] = 
						pointrotate(@{$pts->[$i]}[0,1],$angle, @{$cpt});
				}
			}, # end subroutine $rotatefunc[0]{pts} definition
		}, # end %{$rotatefunc[0]} hash definition
	{ # Second hash for stage-2 operations
		"angs" => sub {
			my($hashref, $angle) = @_;
			foreach my $ang (0, 1) {
				$hashref->{angs}[$ang] += $angle;
				}
			checkarcangs($hashref->{angs});
			}, # end subroutine $rotatefunc[1]{angs} definition
		# NOTE:  I'm ignoring the vector on images and rotation 
		# angle of text for now
		}, # end %{$rotatefunc[1]} hash definition
	); # end @rotatefunc array definition
########################################################################

=head1 Internal Functions

=cut
########################################################################

=head2 pointrotate

Internal use only.

  ($x, $y) = pointrotate($x, $y, $ang, $xc, $yc);

=cut
sub pointrotate {
	my ($x, $y, $ang, $xc, $yc) = @_;
	my $xn = $xc + cos($ang) * ($x - $xc) - sin($ang) * ($y - $yc);
	my $yn = $yc + sin($ang) * ($x - $xc) + cos($ang) * ($y - $yc);
	return($xn, $yn);
} # end subroutine pointrotate definition
########################################################################

=head2 pointmirror

  @point = pointmirror($axis, $pt);

=cut
sub pointmirror {
	my ($axis, $pt) = @_;
# 	print "axis: ", join(" ", map({join(",", @{$_})} @{$axis}[0,1])), "\n";
# 	print "point: ", join(",", @{$pt}), "\n";
	my $foot = PerpendicularFoot([ @{$axis}[0,1], $pt ]);
# 	print "foot: @$foot\n";
	my $x = $foot->[0] - ($pt->[0] - $foot->[0]);
	my $y = $foot->[1] - ($pt->[1] - $foot->[1]);
	return($x, $y);
} # end subroutine pointmirror definition
########################################################################

=head2 angle_of

  angle_of(\@segment);

=cut
sub angle_of {
	my ($axis) = @_;
	my @delta = signdist(@{$axis});
	return(atan2($delta[1], $delta[0]));
} # end subroutine angle_of definition
########################################################################

=head1 Polygon Methods

These don't do anything yet and need to be moved to another module anyway.

=cut
########################################################################

=head2 CutPline

  $drw->CutPline();

=cut
sub CutPline {
	my $self = shift;

} # end subroutine CutPline definition
########################################################################

=head2 IntPline

  $drw->IntPline();

=cut
sub IntPline {
	my $self = shift;

} # end subroutine IntPline definition
########################################################################

=head2 intersect_pgon

  intersect_pgon();

=cut
sub intersect_pgon {

} # end subroutine intersect_pgon definition
########################################################################

1;
