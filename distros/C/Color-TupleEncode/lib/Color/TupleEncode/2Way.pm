package Color::TupleEncode::2Way;

use warnings FATAL=>"all";
use strict;

use Carp;
#use Color::TupleEncode;

# ................................................................
# If you need min/max/average
# use Math::VecStat qw(min max average);

# ................................................................
# If you need floating point modulo
# use POSIX qw(fmod);

use Readonly;

# use Smart::Comments;

=head1 NAME

Color::TupleEncode::2Way - a utility class for C<Color::TupleEncode> that
implements color encoding of a 2-tuple C<(x,y)> to a color

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

This is a utility module used by L<Color::TupleEncode>. To use
this module as the encoding method, pass the C<method> directly or as an option in C<new()> or set with C<set_options()>.
C<new()>

  %options = (-method=>"Color::TupleEncode::2Way");
 
  $encoder = Color::TupleEncode(options=>\%options);

  # using the direct setter

  $encoder->set_method("Color::TupleEncode::2Way");
 
  # setting method as an option individually

  $convert->set_options(-method=>"Color::TupleEncode::2Way");

This module is not designed to be used directly.

=head1 ENCODING ALGORITHM

This class encodes a 2-tuple C<(x,y)> to a HSV color C<(h,s,v)>. The following parameters are supported

  # for hue          default
  -hzero             180
  -orientation       1

  # for saturation (e.g. -saturation=>{power=>1,rmin=>0}
  -rmin              0
  -power             1
  -min               1
  -max               0

  # for value (e.g. -value=>{power=>2,rmin=>1}
  -rmin              1
  -power             2
  -min               1
  -max               0

Options are set using 

  %options => {-hzero=>0, -orientation=>1, -saturation => { rmin => 0 } }

  $encoder = Color::TupleEncode(method=>"Color::TupleEncode::2Way", 
                                options=>\%options)

or

  $encoder->set_options( -hzero => 0)
  $encoder->set_options( -hzero => 0, -orientation =>1 )
  $encoder->set_options( -hzero => 0, -orientation =>1, -saturation => { rmin => 0} )

See C<examples/color-chart-2way.png> for a chart of encoded colors.

The color components are calculated as follows.

=head2 Hue

Hue is defined based on the ratio of the 2-tuple components, C<x/y>.

    r   = x/y

    hue = hzero + 180                     if  y =  0

    hue = hzero - orient * 180 * (1-r)    if  r <= 1
 
    hue = hzero + orient * 180 * (1-1/r)  if  r >  1

    All hue values are modulo 360.

This method maps the C<(x,y)> pair onto the color wheel as
follows. First, a reference hue C<hzero> is chosen. Next, the mapping
orientation is selected using C<orient>. Assuming that C<orient = 1>,
and given the ratio C<r=x/y>, when C<r<=1> the hue lies in the
interval C<[hzero-180,hzero]>. Thus hue progresses in the
counter-clockwise direction along the color wheel from C<h=hzero> when
C<r=1> to C<h=hzero-180> when C<r=0>.

When C<rE<gt>>1>, the hue lines in the interval C<[hzero,hzero+180]>
and hue progresses clock-wise.

If C<orient = -1>, the direction of hue progression is reversed.

For example, if C<orient = 1> and C<hzero = 180> (cyan), 

         hue  color    r = x/y
     
           0  red      0
          45  orange   0.25
          90  lime     0.5
         135  green    0.75
  hzero  180  cyan     1
         240  blue     1.5
         270  violet   2
         300  purple   3
         315  purple   4
           0  red      INF, NaN (y=0)

=head2 Saturation

The saturation is calculated using the size of the 2-tuple, C<r = sqrt( x**2 + y**2 )>. Depending on the value of C<power>, 

    r = sqrt ( x**2 + y **2 )

                      -r/power
    saturation = 1 - 2           if power > 0

    saturation = 1               if power = 0

The default limits on saturation are C<s = 1> at C<r = 0> and C<s = 0>
at C<r = INF>. The default rate of decrease is C<power = 1>. Thus, for
every unit change in C<r>, saturation is decreased by 50%. Use the
C<power> option to change the rate of change. In general, saturation
will change by a factor of C<2> for every C<power> units of C<r>. That
is,

    r    saturation
         power = 1    power = 2   power = 3
    0    1            1           1
    1    0.5          0.707       0.794
    2    0.25         0.5         0.63
    3    0.125        0.354       0.5
    4    0.063        0.25        0.397
    
If C<power = 0>, saturation will be assigned the value it would have at C<r = 0> if C<power E<gt> 0>.
However, keep in mind the effect of C<rmin>, described below.

Saturation can be interpolated within C<[min,max]> by setting the C<-min> and C<-max> options.

  $convert->set_options(-saturation=>{min=>0.8,max=>0.2})

In this example, saturation will be C<0.8> at C<r E<lt>= 0> and will start decreasing at C<r = 0> towards C<0.2> at C<r = INF>.

You can set the minimum value of the tuple component at which saturation begins to change. Use C<rmin> option,

  $convert->set_options(-saturation=>{min=>0.8,max=>0.2,rmin=>1})

In this example, saturation will be C<0.8> at C<r E<lt>= 1>, will start decreasing at C<r = 1> towards C<0.2> at C<r = INF>.

If C<rmin> is set and C<power = 0>, then saturation will be C<min> for C<r E<lt>= rmin> and C<max> for C<r E<gt> rmin>.

=head2 Value

The value is calculated using the same formula as for saturation. 

By setting different C<rmin> values for saturation and value components, you can control the range of C<r> over which the encoding acts. For example, 

  $convert->set_options(-saturation=>{rmin=>0},-value=>{rmin=>1})

will result in saturation changing for C<r E<gt> 0> and value only for
C<r E<gt> 1>. For C<r E<lt>= 1>, value will be at its C<min> setting.

=head1 EXPORT

Exports nothing.

Use L<Color::TupleEncode> and set the encoding method to
C<"Color::TupleEncode::2Way"> to use this module.

=cut 

Readonly::Scalar our $TUPLE_SIZE      => 2;
Readonly::Array  our @OPTIONS_OK      => (qw(-orientation -hzero -saturation -value));
Readonly::Hash   our %OPTIONS_DEFAULT => (-hzero=>180,
					  -orientation=>1,
					  -saturation => {power=>1,min=>1,max=>0,rmin=>0},
					  -value      => {power=>2,min=>1,max=>0,rmin=>1});

sub _component_power_scale {
  my ($value,$options,$component_name,$min,$max,$power) = @_;
  $min = $options->{min} if defined $options->{min};
  $max = $options->{max} if defined $options->{max};
  confess "Option for $component_name minimum must be between [0,1] (saw $min), e.g. use -$component_name=>{rmin=>0.25}." if $min < 0;
  confess "Option for $component_name maximum must be between [0,1] (saw $max), e.g. use -$component_name=>{compmax=>0.75}." if $max > 1;
  $power = defined $options->{power} ? $options->{power} : $power;
  confess "Power for $component_name must be non-negative (saw $power), e.g. use -$component_name=>{power=>1}" if $power < 0;
  my $rmin = defined $options->{rmin} ? $options->{rmin} : 0;
  my $component;
  if(! defined $power) {
    confess "The option -power is not defined for $component_name. It is required to compute the value. Try -$component_name=>{power=>3}.";
  } elsif ($power == 0) {
    if($value <= $rmin) {
      $component = $min;
    } else {
      $component = $max;
    }
  } else {
    ### $component_name
    ### $value
    ### $rmin
    if($value < $rmin) {
      ### below rmin
      $component = $min;
    } else {
      my $f = 1 - 2 ** ( - ($value-$rmin) / $power );
      ### $value
      ### $f
      $component = _interpolate($f,$min,$max);
    }
    ### $component
  }
  $component = 0 if $component < 0;
  $component = 1 if $component > 1;
  return $component;
}

=for comment
Given a 2-tuple, return the corresponding color saturation (in the range [min,max]).

=cut

sub _get_saturation {
  my ($self)  = shift;
  my $options = $self->get_options(-saturation);
  my ($a,$b)  = $self->get_tuple;
  my ($min,$max,$power) = (1,0,1);
  my $r = sqrt($a**2 + $b**2);
  my $component = _component_power_scale($r,$options,"saturation",$min,$max,$power);
}

=for comment
Given a 2-tuple, return the corresponding color saturation (in the range [min,max]).

=cut

sub _get_value {
  my ($self)  = shift;
  my $options = $self->get_options(-value);
  my ($a,$b)  = $self->get_tuple;
  my ($min,$max,$power) = (1,0,2);
  my $r = sqrt($a**2 + $b**2);
  my $component = _component_power_scale($r,$options,"value",$min,$max,$power);
  return $component;
}

=for comment
Given a data triplet, return the corresponding color hue (in the range [0,360)).

=cut

sub _get_hue {
  my $self   = shift;
  my ($a,$b) = $self->get_tuple;

  my $ratio  = $b ? abs($a/$b) : undef;
  my $h;
  my $hzero  = $self->get_options(-hzero);
  my $orient = $self->get_options(-orientation);
  if(defined $ratio) {
    # if the ratio is negative, the hue will be in the first 
    # half of the color wheel, starting at hue $hzero and
    # progressing counterclockwise
    if($ratio <= 1) {
      $h = $hzero - $orient * 180*(1-$ratio);
    }
    # if the ratio is positive, the hue will be in the second
    # half of the color wheel, starting at hue $hzero and
    # progressing clockwise
    else {
      $h = $hzero + $orient * 180*(1-1/$ratio);
    }
  }
  else {
    # If the ratio is not defined ($b = 0), set it to hue $hzero
    $h = $hzero + 180;
  }
  return $h % 360;
}

sub _interpolate {
  my ($x,$min,$max) = @_;

  if($x <= 0) {
    return $min;
  } 
  elsif ($x >= 1) {
    return $max;
  } 
  else {
    my $xi = $min + $x * ($max-$min);
    return $xi;
  }
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

The 2-tuple color encoding implemented in this module was created by the author.

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

=over

=item Color::TupleEncode 

Driver module. This is the module that provides an API for the color encoding. See L<Color::TupleEncode>.

=item Color::TupleEncode::Baran

Encodes a 3-tuple to a color using the scheme described in

Visualization of three-way comparisons of omics data
Richard Baran Martin Robert, Makoto Suematsu, Tomoyoshi Soga1 and Masaru Tomita
BMC Bioinformatics 2007, 8:72 doi:10.1186/1471-2105-8-72

This publication can be accessed at L<http://www.biomedcentral.com/1471-2105/8/72/abstract/>

=item Color::TupleEncode::2Way

A template class for implementing an encoding scheme.

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Martin Krzywinski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Color::TupleEncode::2Way
