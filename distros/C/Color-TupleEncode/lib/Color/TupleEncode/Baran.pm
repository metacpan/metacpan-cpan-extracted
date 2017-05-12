package Color::TupleEncode::Baran;

use warnings FATAL=>"all";
use strict;

use Carp;
use Graphics::ColorObject;
use Color::TupleEncode;
use Math::VecStat qw(min max);
use POSIX qw(fmod);
use Readonly;

#use Smart::Comments;

=head1 NAME

Color::TupleEncode::Baran - a utility class for C<Color::TupleEncode> that
implements color encoding of a 3-tuple C<(x,y,z)> to a color

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

This is a utility module used by L<Color::TupleEncode>. This module
provides the default color encoding scheme. Therefore, if you do not
explicitly set the encoding method in a L<Color::TupleEncode> object explicitly, it will be set to C<Color::TupleEncode::Baran>

To change or set the encoding method, pass the C<method>
directly or as an option in C<new()> or set with C<set_options()>.
C<new()>

  %options = (-method=>"Color::TupleEncode::Baran");
 
  $encoder = Color::TupleEncode(options=>\%options);

  # using the direct setter

  $encoder->set_method("Color::TupleEncode::Baran");
 
  # setting method as an option individually

  $convert->set_options(-method=>"Color::TupleEncode::Baran");

This module is not designed to be used directly.

=head1 ENCODING ALGORITHM

This module encodes a 3-tuple C<(x,y,z)> to a HSV color using the scheme described in

Visualization of three-way comparisons of omics data
Richard Baran Martin Robert, Makoto Suematsu, Tomoyoshi Soga1 and Masaru Tomita
BMC Bioinformatics 2007, 8:72 doi:10.1186/1471-2105-8-72

This publication can be accessed at L<http://www.biomedcentral.com/1471-2105/8/72/abstract/>

This class encodes a 3-tuple C<(x,y,z)> (or C<(a,b,c)> in accordance with the terminology in the publication) to a HSV color C<(h,s,v)>. The following parameters are supported

  # for hue          default
  -ha                0
  -hb                20
  -hc                240

  # for saturation - set using hash reference as
  # option value, e.g. -saturation=>{dmin=>0.2,dmax=>0.8}
  -saturation   dmin     0
                dmax     1
                min      0
                max      0
                relative 0

  # for value - set using has reference as
  # option value, e.g. -saturation=>{min=>0.2}
  -value        dmin     NOT SET
                dmax     NOT SET
                min      0
                max      1
                relative 0

Options are set using 

  %options=>{-ha=>60, -hb=>180, -hc=>300, -saturation=>{dmin=>0,dmax=>2}}

  $encoder = Color::TupleEncode(method=>"Color::TupleEncode::2Way", 
                                options=>\%options);

or

  $encoder->set_options(-ha=>60);
  $encoder->set_options(-ha=>60, -saturation=>{dmin=>0,dmax=>2});

See C<examples/color-chart-3way.png> for a chart of encoded colors.

The color components are calculated as follows.

=head2 Hue

Given the tuple C<(a,b,c)>, let the characteristic hues for each tuple be C<ha,hb,hc>. Form the differences

  dab = | a - b |
  dac = | a - c |
  dbc = | b - c |

The hue is calculated along the gradient formed by the two components that form the largest difference. For example, if C<dac> is the largest difference, the final hue lies along the gradient formed by C<(ha,hc)>.

  hue = 0  if a = b = c

  # values of hue below are fractional in the range [0,1] and
  # always modulo 1 (e.g. hue=1.2 becomes 0.2).

  hue = ha + ( hb - ha ) * dbc / dab      if dab >= dbc and dab >= dac

  hue = hb + ( hc - hb ) * dac / dbc      if dbc > dab and dbc >= dac

  hue = hc + ( ha + 1 - hc ) * dab / dac  if  dac > dab and dac > dbc

  # convert from [0,1] to [0,360]

  hue = hue * 360

The effect of this encoding is to emphasize the component that is the most different. 

If two components equal and the third is very different, e.g. C<(0.1,1,0.1)> then the encoded hue will the characteristic hue of the largest component. In this case C<h = hb = 120>. 

When the difference in the close values is small C<(0.1,1,0.15)> the encoded hue will be very close to the characterstic hue of the most different component. In this case, the hue will be very close to C<hb = 120> - the hue is C<h = 113>.

When the values are spread equally C<(0.3,0.6,0.9)> the hue will be half way between the characteristic hues of the components that form the largest difference. In this case, the hue will lie between C<ha> and C<hc> - the hue is C<h = 300>.

=head2 Saturation

Given the tuple C<(a,b,c)> and the differences

  dab = | a - b |
  dac = | a - c |
  dbc = | b - c |

let

  d    = max( dab, dac, dbc )

Saturation is given by

  s = 0                              if d <= dmin
  
  s = 1                              if d >= dmax
 
  s = ( d - dmin ) / ( dmax - dmin ) if dmin < d < dmax

Thus, saturation is interpolated when the maximum difference C<d> is within C<[ dmin, dmax ]>. These limits are set by C<set_options>. For example

  $encoder->set_options( -saturation => { dmin => 0.25, dmax => 0.75 } );

would result in saturation varying from its minimum to maximum value from C<dmin = 0.25> to C<dmax = 0.75>. Depending on the magnitude of the difference in components in your tuples, you will want to adjust the difference range to match.

If the C<-relative> option is used, then a relative correction is applied to C<d> if C<d E<gt> 0> before saturation is calculated. Note that with this correction, C<d> will always be in the range C<[ 0, 1 ]>.

  drel = d / max( |a|, |b|, |c|, d )

  d <- drel

Saturation can be constrained within a range C<[ min, max ]> by setting the C<min,max> parameters. These values must be in the range [0,1].

  $encoder->set_options( -saturation => { min => 0.25, max => 0.75 } );

You can set C<min> E<lt> C<max> (e.g. saturation increases as C<d> increases), or C<min> E<gt> C<max> (e.g. saturatio decreases as C<d> increases).

If either of C<(dmin,dmax)> parameters are not set, C<s = 1> always. You can clear a parameter by setting it to C<undef>.

  $encoder->set_options( -saturation => { -dmin => undef, -dmax => undef } )

To toggle the use of relative difference,

  $encoder->set_options( -saturation => { relative => 1 } );

The I<Baran et al.> publication in which this encoding was introduced suggests to use the product of absolute and relative saturations as the final saturation. This can be done by calculating two values of saturation, one with the C<-saturation=>{relative=>0}> option, and one with C<-saturation=>{relative=>1}>.

You can combine saturation and value encoding together. See the L</Value> section.

=head2 Value

The value is defined analogously to saturation. 

You can supplement saturation encoding with value encoding as follows. Set the difference range C<[ dmin, dmax ]> for value to be higher/lower than the difference range for saturation. For example,

  $encoder->set_options(-saturation => { dmin => 0 , dmax => 2},
                        -value      => { dmin => 2 , dmax => 5 , min => 1 , max => 0 };

The effect will be to adjust saturation when the largest component difference is in the range C<[0,2]> (from C<s = 0> to C<s = 1>). Thus as the difference grows, the color becomes more saturated.

In the range C<[ 2, 5 ]>, C<s = 1> since the range is beyond C<dmax> set for saturation. However, in this higher range the value will be adjusted from C<min = 1> to C<max = 0>. Thus, as the difference grows, the color gets darker. 

Below is an example of the HSV values for various C<( x, y, z)> using the options above.

  0 , 0.1 , 1.0   251  0.50  1.0
  0 , 0.1 , 1.5   248  0.75  1.0
  0 , 0.1 , 2.0   246  1.00  1.0
  0 , 0.1 , 3.0   243  1.00  0.67
  0 , 0.1 , 4.0   242  1.00  0.33
  0 , 0.1 , 5.0   242  1.00  0.00
  0 , 0.1 , 6.0   242  1.00  0.00

You can obtain these values with C<examples/example-3way> as follows, for each tuple,

  > examples/example-3way -options "{-saturation=>{dmin=>0,dmax=>2},
                                     -value=>{dmin=2,dmax=>5,min=>1,max=>0}}" 
                          -tuple 0,0.1,1.5


=head1 EXPORT

Exports nothing.

Use L<Color::TupleEncode>. The method implemented by this module is used by default.

=cut 

=for comment
Given a data triplet, return the corresponding value.

=cut

Readonly::Scalar our $TUPLE_SIZE      => 3;
Readonly::Array  our @OPTIONS_OK      => (qw(-ha -hb -hc -saturation -value));
Readonly::Hash   our %OPTIONS_DEFAULT => (-ha=>0,-hb=>120,-hc=>240,-saturation=>{dmin=>0,dmax=>1});

sub _get_value {
  my $self = shift;
  my ($a,$b,$c) = $self->get_tuple;
  my ($dmin,$dmax);
  # These are the hard limits on value.
  my ($vmin,$vmax) = (1,0);
  # Value options can be one or more of
  # min, max, dmin, dmax, relative
  my $options = $self->get_options(qw(-value));
  return _get_interpolated_component($a,$b,$c,$vmin,$vmax,$options,"value");
}


=for comment
Given a data triplet, return the corresponding saturation

=cut

sub _get_saturation {
  my $self = shift;
  my ($a,$b,$c) = $self->get_tuple;
  my ($s,$dmin,$dmax);
  my ($smin,$smax) = (0,1);
  my $options = $self->get_options(qw(-saturation));
  return _get_interpolated_component($a,$b,$c,$smin,$smax,$options,"saturation");
}

=for comment
Given a data triplet, return the corresponding hue.

=cut

sub _get_hue {
  my $self         = shift;
  my ($a,$b,$c)    = $self->get_tuple;
  my ($ha,$hb,$hc) = $self->get_options(qw(-ha -hb -hc));
  $ha /= 360 if $ha > 1;
  $hb /= 360 if $hb > 1;
  $hc /= 360 if $hc > 1;
  my $h = 0;
  if($a == $b && $a == $c) {
    $h = 0;
  } 
  elsif (abs($a-$b) >= abs($b-$c) && abs($a-$b) >= abs($a-$c)) {
    $h = $ha + ($hb-$ha)*abs($b-$c)/abs($a-$b);
  }
  elsif (abs($b-$c) > abs($a-$b) && abs($b-$c) >= abs($a-$c)) {
    $h = $hb + ($hc-$hb)*abs($a-$c)/abs($b-$c);
  }
  elsif (abs($a-$c) > abs($a-$b) && abs($a-$c) > abs($b-$c)) {
    $h = $hc + ($ha-$hc+1)*abs($a-$b)/abs($a-$c);
    $h = fmod($h,1);
  } else {
    confess "couldn't find hue for $a,$b,$c";
  }
  return 360*$h;
}

=for comment
Common function for saturation and value. Interpolates the
tuple a,b,c between component_min and component_max. Options in $options control the process.

=cut

sub _get_interpolated_component {
  my ($a,$b,$c,$component_min,$component_max,$options,$component_name) = @_;
  # ranges on the component
  my ($min,$max) = ($component_min,$component_max);
  # ranges on the difference
  my ($dmin,$dmax);
  if(defined $options) {
    if(ref($options) eq "HASH") {
      $min = $options->{min}  if defined $options->{min};
      $max = $options->{max}  if defined $options->{max};
      $dmin = $options->{dmin} if defined $options->{dmin};
      $dmax = $options->{dmax} if defined $options->{dmax};
    } else {
      confess "-$component_name option for must be a hash reference, e.g. -$component_name=>{dmin=>0,dmax=>1}";
    }
  }
  if($min < min($component_min,$component_max)) {
    confess "$component_name minimum must be ".min($component_min,$component_max);
  } 
  if($max > max($component_min,$component_max)) {
    confess "$component_name maximum must be ".max($component_min,$component_max);
  }
  my $t; # this is the interpolation parameter 0..1
  if(! defined $dmin || ! defined $dmax) {
    $t = 0;
  } else {
    if($a == $b && $b == $c) {
      $t = 0;
    } 
    elsif(defined $dmin && defined $dmax) {
      my $d = _get_maxdiff($a,$b,$c);
      if(defined $options && $options->{relative}) {
	my $rel_factor = max(abs($a),abs($b),abs($c),$d);
	if($rel_factor) {
	  $d /= $rel_factor;
	} else {
	  # this should never happen because a=b=c=0 test
	  # has been done above
	  $d = 0;
	}
      }
      if($d <= $dmin) {
	$t = 0;
      } elsif ($d >= $dmax) {
	$t = 1;
      } else {
	$t = ($d-$dmin)/($dmax-$dmin);
      }
    }
    else {
      $t = 0;
    }
  }
  ## $v
  ## $vmin
  ## $vmax
  my $component = _interpolate($t,$min,$max);
  return $component;
}

=for comment
Interpolate value (0..1) between max and min

=cut

sub _interpolate {
  my ($x,$min,$max) = @_;
 
  #my $min_real = $min < $max ? $min : $max;
  #my $max_real = $max > $min ? $max : $min;

  ## $x
  ## $min
  ## $max

  if($x <= 0) {
    return $min;
  } 
  elsif ($x >= 1) {
    return $max;
  } 
  else {
    my $d = $max - $min;
    $d = $d * $x;
    $d = $min + $d;
    my $xi = $min + $x * ($max-$min);
    return $xi;
  }
}

=for comment
Retrieve largest difference

=cut

sub _get_maxdiff {
  my ($a,$b,$c) = @_;
  return scalar max(abs($a-$b),abs($a-$c),abs($b-$c));
}

=for comment
Returns the tuple size for this encoding.

=cut

sub _get_tuple_size {
  return $TUPLE_SIZE;
}

=for comment
Returns a list of options that this implementation understands.

=cut

sub _get_ok_options {
  return @OPTIONS_OK;
}

=for comment
Returns a hash of default options for this implementation

=cut

sub _get_default_options {
  return %OPTIONS_DEFAULT;
}

=pod 

=head1 IMPLEMENTING AN ENCODING CLASS

The encoding class must implement the following functions. Given a C<Color::TupleEncode> object C<$obj>,

=head2 C<$value = _get_value( $obj )>

=head2 C<$saturation = _get_saturation( $obj )>

=head2 C<$hue = _get_hue( $obj )>

=head2 C<$size = _get_tuple_size()>

=head2 C<@opt_ok =_get_ok_options()>

=head2 C<%opt_def = _get_default_options()>

=head1 AUTHOR

Martin Krzywinski, C<< <martin.krzywinski at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-color-threeway at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Color-TupleEncode>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Color::TupleEncode

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Color-TupleEncode>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Color-TupleEncode>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Color-TupleEncode>

=item * Search CPAN

L<http://search.cpan.org/dist/Color-TupleEncode/>

=back

=head1 SEE ALSO

For details about the color encoding, see

=over

=item Color::TupleEncode 

Driver module. This is the module that provides an API for the color encoding. See L<Color::TupleEncode>.

=item Color::TupleEncode::2Way

A utility module that encodes a 2-tuple to a color. See L<Color::TupleEncode::2Way>.

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Martin Krzywinski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Color::TupleEncode::Baran
