package Color::TupleEncode;

use warnings FATAL=>"all";
use strict;

# use Smart::Comments;

use parent qw(Exporter);

our %EXPORT_TAGS = ("all"=>[qw(tuple_asRGB tuple_asRGB255 tuple_asRGBhex tuple_asHSV)]);
Exporter::export_ok_tags("all");

use Carp;
use Graphics::ColorObject;
use Color::TupleEncode::Baran;
use Color::TupleEncode::2Way;
use Math::VecStat qw(min max);
use POSIX qw(fmod);
use Readonly;

# Additional allowable options - added to those of the implementation method
Readonly::Hash  our %OPTIONS_DEFAULT => (-method=>"Color::TupleEncode::Baran");
Readonly::Array our @OPTIONS_OK      => (qw(-method));

=head1 NAME

Color::TupleEncode - Encode a tuple (vector) into a color - useful for
generating color representation of a comparison of multiple values.

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

Given a tuple (e.g. three numbers) , apply color-coding method to
encode the tuple by a color in HSV (hue, saturation, value) space. For a visual tour of the results, see L<http://mkweb.bcgsc.ca/tupleencode/>.

  use Color::TupleEncode;

  # By default the encoding method Color::TupleEncode::Baran will be used

  # initialize and define in one step
  $encoder = Color::TupleEncode->new(tuple=>[$a,$b,$c]);

  # pass in some options understood by the encoding implementation
  %options = {-ha=>30, -saturation=>{dmin=>0.2,dmax=>0.8}};
  $encoder = Color::TupleEncode->new(tuple=>[$a,$b,$c],options=>\%options);

  # initialize tuple directly
  $encoder->set_tuple($a,$b,$c);
  $encoder->set_tuple([$a,$b,$c]);

  # obtain RGB (0 <= R,G,B <= 1) values
  ($r,$g,$b) = $encoder->as_RGB;

  # obtain RGB (0 <= R,G,B <= 255) values
  ($r255,$g255,$b255) = $encoder->as_RGB255;

  # obtain RGB hex (e.g. FF00FF - note no leading #)
  $hex = $encoder->as_RGBhex;

  # obtain HSV (0 <= H < 360, 0 <= S,V <= 1) values
  ($h,$s,$v) = $encoder->as_HSV;

  # change the encoding method
  $encoder->set_method("Color::TupleEncode::2Way");

  # see how many values this method accepts ($tuple_size = 2)
  $tuple_size = $encoder->get_tuple_size();

  # set the tuple with the new method and encode
  $encoder->set_tuple(1,2);

  ($r,$g,$b) = $encoder->as_RGB;

Use C<%options> to define implementation and any parameters that control the encoding. 

  %options = (-method=>"Color::TupleEncode::Baran");

  %options = (-method=>"Color::TupleEncode::Baran",
              -saturation=>{min=>0,max=>1,dmin=>0,dmax=>1});

A non-OO interface is also supported.

  # import functions explicitly
  use Color::TupleEncode qw(tuple_asRGB tuple_asRGB255 tuple_asHSV tuple_asRGBhex);

  # or import them all automatically
  use Color::TupleEncode qw(:all);

  # pass tuple and options just like with new()
  ($r,$g,$b) = tuple_asRGB(tuple=>[$a,$b,$c]);

  # specify options
  ($r,$g,$b) = tuple_asRGB(tuple=>[$a,$b,$c],options=>\%options)

  # specify method directly - note that ::2Way takes two values
  ($r,$g,$b) = tuple_asRGB(tuple=>[$a,$b],method=>"Color::TupleEncode::2Way");

  # tuple_asRGB255, tuple_asHSV and tuple_asRGBhex work analogously

=head1 COLOR ENCODINGS

=head2 Default Encoding

The default encoding method is due to I<Baran et al.> (see L</COLOR
ENCODINGS>). This method encodes a 3-tuple C<(x,y,z)> by first assigning a
characteristic hue to each variable and then calculating a color based
on the relative relationship of the values. The encoding is designed
to emphasize the variable that is most different.

The default encoding is implemented in L<Color::TupleEncode::Baran>.

=head2 C<Color::TupleEncode::2Way>

This encoding converts a 2-tuple C<(x,y)> to color. It is implemented in the module L<Color::TupleEncode::2Way>.

If you would like to implement your own encoding, I suggest editing and extend this module. See
L</IMPLEMENTING AN ENCODING CLASS> for more details.

=head2 Other Encodings

C<Color::TupleEncode> is designed to derive encoding functionality
from utility modules, such as L<Color::TupleEncode::Baran>. The
utility modules implement the specifics of the tuple-to-color
conversion and L<Color::TupleEncode> does the housekeeping.

You can change the class by using C<-method> in the C<%options> hash passed to C<new()>

  %options = (-method=>"Color::TupleEncode::2Way");

set the option directly

  $threeway->set_options(-method=>"Color::TupleEncode::2Way");

or pass the method name to C<new()>

  Color::TupleEncode->new(method=>"Color::TupleEncode::2Way");

Note that when using the options hash, option names are prefixed by
C<->. When passing arguments to C<new()>, however, the C<-> is not
used.

=head1 EXAMPLES

=head2 Quick encoding

To encode a tuple with the default encoding scheme (C<Color::TupleEncode::Baran>):

  use Color::TupleEncode qw(as_HSV as_RGBhex);

  my @tuple = (0.2,0.5,0.9);

  my @hsv = as_HSV(tuple=>\@tuple);    #  291 0.7 1.0
  my @rgb = as_RGB255(tuple=>\@tuple); #  230  77 255
  my $hex = as_RGBhex(tuple=>\@tuple); #  E64DFF

=head2 Encoding with options

Options control how individual encodings work. The
C<Color::TupleEncode::Baran> method supports changing the
characteristic hues of each variable, min/max ranges for saturation
and value and min/max ranges for the largest variable difference for
saturation and value components.

  # change the characteristic hues
  my @hsv = as_HSV(tuple=>\@tuple,options=>{-ha=>60,-hb=>180,-hc=>300}); # 351 0.7 1.0

=head2 Using another implementation

  use Color::TupleEncode qw(as_HSV as_RGBhex);

  my @tuple = (0.2,0.5,0.9);

  my $method = "Color::TupleEncode::2Way";
  my @hsv   = tuple_asHSV(tuple=>\@tuple,method=>$method);    # 255 0.6 1.0
  my @rgb   = tuple_asRGB255(tuple=>\@tuple,method=>$method); # 102 140 255
  my @rgb   = tuple_asRGBhex(tuple=>\@tuple,method=>$method); # 668Cff

=head2 examples/example-3way

This is one of the example scripts in the C<examples/> directory. It
shows how to use the 3-tuple encoding implemented by L<Color::TupleEncode::Baran>

The C<example-3way> takes a 3-tuple (or uses a random one) and reports its HSV, RGB and hex colors.

  # use a random tuple
  > examples/example-3way
  The 3-tuple 0.787 0.608 0.795 encodes as follows

  hue 125 saturation 0.186 value 1.000
  R 207 G 255 B 211
  hex CFFFD3

  # use a 3-tuple specified with -tuple
  > examples/example-3way -tuple 0.2,0.3,0.9
  The 3-tuple 0.200 0.300 0.900 encodes as follows

  hue 257 saturation 0.700 value 1.000
  R 128 G 77 B 255
  hex 804DFF

=head2 examples/examples-2way

This is one of the example scripts in the C<examples/> directory. It
shows how to use the 2-tuple encoding implemented by L<Color::TupleEncode::2Way>

The C<example-2way> takes a 2-tuple (or uses a random one) and reports its HSV, RGB and hex colors.

  # use a random 2-tuple
  > examples/example-2way
  The 2-tuple 0.786 0.524 encodes as follows

  hue 240 saturation 0.440 value 0.126
  R 18 G 18 B 32
  hex 121220

  # use a 2-tuple specified with -tuple
  > examples/example-2way -tuple 0.2,0.9
  The 2-tuple 0.200 0.900 encodes as follows

  hue 40 saturation 0.167 value 0.422
  R 108 G 102 B 90
  hex 6C665A

=head2 examples/tuple2color

This script is much more flexible. It can read tuples from a file, or
generate a matrix of tuples that span a given range. You can specify
the implementation and options on the command line.

The script can also generate a PNG color chart of the kind seen at L<http://mkweb.bcgsc.ca/tupleencode/?color_charts>.

By default C<tuple2color> uses the 3-tuple encoding.

  # generate a matrix of tuples and report RGB, HSV and hex values
  > examples/tuple2color 
  abc 0 0 0 rgb 255 255 255 hsv 0 0 1 hex FFFFFF
  abc 0.2 0 0 rgb 255 204 204 hsv 0 0.2 1 hex FFCCCC
  abc 0.4 0 0 rgb 255 153 153 hsv 0 0.4 1 hex FF9999
  abc 0.6 0 0 rgb 255 102 102 hsv 0 0.6 1 hex FF6666
  abc 0.8 0 0 rgb 255 51 51 hsv 0 0.8 1 hex FF3333
  ...

  # specify range of matrix values (default is min=0, max=1, step=(max-min)/10)
  tuple2color -min 0 -max 1 -step 0.1

  # you can overwrite one or more matrix settings
  tuple2color -step 0.2

  # instead of using an automatically generated matrix, 
  # specify input data (tuples)
  tuple2color -data matrix_data.txt

  # specify how matrix entries should be sorted (default no sort)
  tuple2color -data matrix_data.txt -sortby a,b,c
  tuple2color -data matrix_data.txt -sortby b,c,a
  tuple2color -data matrix_data.txt -sortby c,a,b

  # specify implementation
  tuple2color -data matrix_data.txt -method Color::TupleEncode::Baran

  # specify options for Color::Threeway
  draw_color_char ... -options "-saturation=>{dmin=>0,dmax=>1}"

In addition, generate a PNG image of values and corresponding encoded colors.

  # draw color patch matrix using default settings
  tuple2color -draw

  # specify output image size
  tuple2color ... -width 500 -height 500

  # specify output file
  tuple2color ... -outfile somematrix.png

The 2-way and 3-way encoding color charts are bundled with this
module, at C<examples/color-chart-*.png>.

These charts were generated using C<examples/tuple2color> as follows.

A large 2-tuple encoding chart with C<[a,b]> in the range C<[0,2]> sampling every C<0.15>.

  ./tuple2color -method "Color::TupleEncode::2Way"  \
                -min 0 -max 2 -step 0.15            \
                -outfile color-chart-2way.png       \
                -width 600 -height 1360             \
                -draw

A small 2-tuple encoding chart with C<[a,b]> in the range C<[0,2]> sampling every C<0.3>.

  ./tuple2color -method "Color::TupleEncode::2Way"  \
                -min 0 -max 2 -step 0.3             \
                -outfile color-chart-2way-small.png \
                -width 600 -height 430              \
                -draw

A large 3-tuple encoding chart with C<[a,b,c]> in the range C<[0,1]> sampling every C<0.2>.

  ./tuple2color -step 0.2                           \
                -outfile color-chart-3way.png       \
                -width 650 -height 1450             \
                -draw

A large 2-tuple encoding chart with C<[a,b,c]> in the range C<[0,1]> sampling every C<1/3>.

  ./tuple2color -step 0.33333333333                 \
                -outfile color-chart-3way-small.png \
                -width 650 -height 450              \
                -draw

=head1 SUBROUTINES/METHODS

=head2 C<new()>

=head2 C<new( tuple =E<gt> [ $a,$b,$c ] )>

=head2 C<new( tuple =E<gt> [ $a,$b,$c ], options =E<gt> \%options)>

=head2 C<new( tuple =E<gt> [ $a,$b,$c ], method =E<gt> $class_name)>

=head2 C<new( tuple =E<gt> [ $a,$b,$c ], method =E<gt> $class_name, options =E<gt> \%options)>

Initializes the encoder object. You can immediately pass in a tuple,
options and/or an encoding method. The method can be part of the option hash (as C<-method>).

Options are passed in as a hash reference and the encoding method as
the name of the module that implements the encoding. Two
methods are available (C<Color::TupleEncode::Baran> (default encoding)
and C<Color::TupleEncode::2Way>).

At any time if you try to pass in incorrectly formatted input (e.g. the wrong number of elements in a tuple, an option that is not understood by the encoding method), the module dies using C<confess>.

You can write your own encoding method - see L</IMPLEMENTING AN
ENCODING CLASS> for details.

=cut 

sub new {
  my $class = shift;

  if(@_ && @_ % 2) {
    confess "Arguments to new must be a hash (i.e. even number of entries)";
  }
    
  $class = ref($class) ? ref($class) : $class;
  my $self  = {};
  bless $self, $class;

  # immediately set the method to default - this ensures that
  # a method is set for any further steps
  $self->_set_method($OPTIONS_DEFAULT{-method});

  my %args = @_;

  if($args{method}) {
    $self->_set_method($args{method});
  }

  my %args_ok = (options=>1,tuple=>1,method=>1);
  
  if(my @args_notok = grep(! $args_ok{$_}, keys %args)) {
    confess "Do not understand new() arguments ".join(" ",@args_notok);
  }

  if($args{options}) {
    my $options    = $args{options};
    $self->set_options($options);
  }
  if($args{tuple}) {
    $self->set_tuple( $args{tuple} );
  }

  return $self;
}

=head2 C<set_options( %options )>

Define options that control how encoding is done. Each encoding method has
its own set of options. For details, see L</COLOR ENCODINGS>.

Options are passed in as a hash and option names are prefixed with C<->. 

  $encoder->set_options(-ha=>0,-hb=>120,-hc=>240);

=cut

sub set_options {
  my ($self,@options) = @_;
  return if ! @options;
  my %options;
  if(not @options % 2) {
    %options = @options;
  } 
  elsif (@options == 1) {
    my $options_first = $options[0];
    if(ref( $options_first ) eq "HASH") {
      %options = %$options_first;
    } else {
      confess "Value passed to options must be a hash or hash reference";
    }
  }
  else {
    confess "Value passed to options must be a hash or hash reference";
  }
  my @option_names = keys %options;
  # make sure that the -method option, if it exists, is set first
  @option_names = (grep($_ eq "-method", @option_names),
		   grep($_ ne "-method", @option_names));
  for my $option_name (@option_names) {
    my $option_value = $options{$option_name};
    if($option_name eq "-method") {
      $self->_set_method($option_value);
    } else {
      my $method     = $self->get_options(-method);
      $self->_validate_option($option_name,$option_value);
      if(! defined $option_value) {
	$self->_clear_option($option_name);
      } 
      else {
	$self->{options}{$option_name} = $option_value;
      }
    }
  }
}

=pod

=head2 C<$ok = has_option( $option_name )>

Tests whether the current encoding scheme supports (and has set) the option C<$option_name>.

If the method does not support the option, undef is returned.

If the method supports the option, but it is not set, 0 is returned.

If the method supports the option, and the option is set, 1 is returned.

=cut

sub has_option {
  my ($self,$option_name) = @_;
  my @options_ok = $self->_get_ok_options();
  if(! grep($_ eq $option_name, @options_ok)) {
    return;
  } elsif (exists $self->{options}{$option_name}
	   &&
	   defined $self->{options}{$option_name}) {
    return 1;
  } else {
    return 0;
  }
}

=for comment
Validate an option as acceptable. Returns 1 if the option is supported by the current method, and dies otherwise.

=cut

sub _validate_option {
  my ($self,$option_name,$option_value) = @_;
  confess "Cannot validate an undefined option name." unless defined $option_name;
  my @options_ok;
  my $method;
  if(! defined $self->{options}{-method}) {
    # this package's default options
    confess "Cannot set options to an object that does not have encoding implementation defined.";
  } 
  else {
    # this package's default options and the implementation's default options
    @options_ok = $self->_get_ok_options();
    $method = $self->{options}{-method};
  }
  if(! grep($_ eq $option_name, @options_ok)) {
    confess "Encoding implementation $method does not support option $option_name.";
  }
  if(! defined $option_value) {
    # An undefined option value is acceptable - the option will be cleared
    return 1;
  } else {
    return 1;
  }
}

=pod 

=head2 C<%options = get_options()>

=head2 C<$option_value = get_options( "-saturation" )>

=head2 C<($option_value_1,$option_value_2) = get_options( qw(-saturation -value) )>

Retrieve one or more (or all) option values. Options control how color
encoding is done and are set by C<set_options()> or during
initialization.

If no option names are passed, a hash of all defined options (hash
keys) and their values (hash values) is returned.

If one or more option names is passed, a list of corresponding values
is returned.

=cut

sub get_options {
  my $self    = shift;
  my @options = @_;
  
  if(! defined $self->{options}{-method}) {
    confess "Cannot get_options() on an object which does not have the encoding method set.";
  }
  # get a list of all allowable options for this implementation
  my $method = $self->{options}{-method};
  my @ok_options = $self->_get_ok_options();
  my $output_hash = 0;
  # if no options were asked for, we'll return them all
  if(! @options) {
    my @ok_options  = $self->_get_ok_options();
    @options = @ok_options;
    $output_hash = 1;
  }
  my @values;
  my %values;
  for my $option_name (@options) {
    if(grep($_ eq $option_name, @ok_options)) {
      my $option_value;
      if(exists $self->{options}{$option_name} && defined $self->{options}{$option_name}) {
	$option_value = $self->{options}{$option_name};
      } else {
	$option_value = undef;
      }
      push @values, $option_value;
      $values{$option_name} = $option_value;
    } else {
      confess "You asked for option $option_name - this option is not supported by method $method.";
    }
  }
  if($output_hash) {
    return %values;
  } else {
    if(@values == 1) {
      return $values[0];
    } else {
      return @values;
    }
  }
}

=for comment
Clear options

=cut

sub _clear_options {
  my $self = shift;
  $self->{options} = {};
}

=for comment
Clear option by deleting its entry.

=cut

sub _clear_option {
  my ($self,$option_name) = shift;
  if(defined $option_name) {
    delete $self->{options}{$option_name};
  }
}


=pod

=head2 C<set_tuple( @tuple )>

=head2 C<set_tuple( \@tuple )>

Define the tuple to encode to a color. Retrieve with C<get_tuple()>.

The tuple size must be compatible with the encoding method. You can check the required size with C<get_tuple_size()>.

=cut

sub set_tuple {
  my ($self,@tuple) = @_;
  my @ok_tuple = $self->_validate_tuple(@tuple);
  $self->_set_tuple(@ok_tuple);
}

=for comment
Set object's data tuple.

=cut

sub _set_tuple {
  my ($self,@tuple) = @_;
  $self->{data} = [@tuple];
}

=pod

=head2 C<@tuple = get_tuple()>

Retrieve the current tuple, defind by C<set_tuple(@tuple)>.

=cut

sub get_tuple {
  my $self = shift;
  if($self->{data}) {
    return @{$self->{data}};
  } else {
    return;
  }
}

=pod

=head2 C<$size = get_tuple_size()>

Retrieve the size of the tuple for the current implementation. For
example, the method by I<Baran et al.> (see L</COLOR ENCODINGS>) uses three
values as input, thus C<$size=3>.

=cut

sub get_tuple_size {
  my $self   = shift;
  my $method = $self->get_options(-method);
  if(! defined $method) {
    confess "Cannot retrieve tuple size for an undefined method";
  } else {
    return $method->_get_tuple_size();
  }
}


=for comment
Set and get the encoding method.

=cut

sub _set_method {
  my ($self,$method) = @_;
  if(ref($method)) {
    confess "The implementation method must be a string, e.g. 'Color::TupleEncode::2Way'";
  }
  for my $fn (qw(_get_value _get_saturation _get_hue _get_tuple_size _get_ok_options _get_default_options)) {
    if(! $method->can($fn)) {
      confess "Thex encoding implementation $method does not support $fn";
    }
  }
  if($method->_get_tuple_size() <= 0) {
    confess "The encoding implementation $method did not return a positive tuple size. Make sure $method::_get_tuple_size() returns a positive number!";
  }
  if(! $method->_get_default_options()) {
    confess "The encoding implementation $method does define \%OPTIONS_DEFAULT";
  }
  if(! $method->_get_ok_options()) {
    confess "The encoding implementation $method does define \@OPTIONS_OK";
  }
  # when we set a method, clear options because they may have been
  # set by a previous method.
  $self->_clear_options();
  $self->{options}{-method} = $method;
  # upon setting the method, set all default options associated with the method
  $self->set_options( $self->_get_implementation_default_options() );
}

=pod

=head2 C<$method = get_method()>

Retrieve the current encoding method. By default, this is L<Color::TupleEncode::Baran>.

=cut 

sub get_method {
  my $self = shift;
  return $self->{options}{-method};
}

=pod

=head2 C<set_method( "Color::TupleEncode::2Way" )>

Set the encoding method. By default, the method is L<Color::TupleEncode::Baran>.

You can also set the method as an option

  $encoder->set_options(-method=>"Color::TupleEncode::2Way");

or at initialization

  Color::TupleEncode->new(method=>"Color::TupleEncode::2Way");

  Color::TupleEncode->new(options=>{-method=>"Color::TupleEncode::2Way"});

Note that when using the options hash, option names are prefixed by
C<->. When passing arguments to C<new()>, however, the C<-> is not
used.

=cut 

sub set_method {
  my ($self,$method) = @_;
  $self->_set_method($method);
}

=pod

=head2 C<($r,$g,$b) = as_RGB()>

Retrieve the RGB encoding of the current tuple. The tuple is set by either C<set_tuple()> or at initialization.

Each of the returned RGB component values are in the range C<[0,1]>.

If the tuple is not defined, then C<as_RGB()>, this and other C<as_*> methods return nothing (evaluates to false in all contexts).

=cut

sub as_RGB {
  my $self = shift;
  if(! $self->get_tuple) {
    return;
  }
  my @hsv   = $self->as_HSV();
  my $color = Graphics::ColorObject->new_HSV(\@hsv);
  return @{$color->as_RGB};
}

=pod

=head2 C<as_RGB255()>

Analogous to C<as_RGB()> but each of the returned RGB component values
are in the range C<[0,255]>.

=cut

sub as_RGB255 {
  my $self = shift;
  if(! $self->get_tuple) {
    return;
  }
  my @hsv   = $self->as_HSV();
  my $color = Graphics::ColorObject->new_HSV(\@hsv);
  return @{$color->as_RGB255};

}

=pod

=head2 C<$hex = as_RGBhex()>

Analogous to C<as_RGB()> but returned is the hex encoding (e.g. C<FF01AB>) of the RGB color.

Note that the hex encoding does not have a leading C<#>.

=cut

sub as_RGBhex {
  my $self = shift;
  if(! $self->get_tuple) {
    return;
  }
  my @hsv   = $self->as_HSV();
  my $color = Graphics::ColorObject->new_HSV(\@hsv);
  return $color->as_RGBhex;

}

=pod

=head2 C<($h,$s,$v) = as_HSV()>

Retrieve the HSV encoding of the current tuple. The tuple is set by either C<set_tuple()> or at initialization.

Hue C<$h> is in the range C<[0,360)> and saturation C<$s> and value C<$v> in the range C<[0,1]>.

=cut

sub as_HSV {
  my $self = shift;
  if(! $self->get_tuple) {
    return;
  }
  my ($h,$s,$v);
  $h = $self->_get_hue;
  $s = $self->_get_saturation;
  $v = $self->_get_value;
  confess "problem" if ! defined $v;
  return ($h,$s,$v);
}

=pod

=head1 EXPORT

In addition to the object oriented interface, you can call these
functions directly to obtain the color encoding. Note that any
encoding options must be passed in each call.

=head2 C<($r,$g,$b) = tuple_asRGB( tuple =E<gt> [$a,$b,$c])>

=head2 C<($r,$g,$b) = tuple_asRGB( tuple =E<gt> [$a,$b,$c], options =E<gt> %options)>

=head2 C<($r,$g,$b) = tuple_asRGB( tuple =E<gt> [$a,$b,$c], method =E<gt> $class_name)>

=head2 C<($r,$g,$b) = tuple_asRGB( tuple =E<gt> [$a,$b,$c], method =E<gt> $class_name, options =E<gt> %options)>

=cut

sub tuple_asRGB {
  my @args = @_;
  my $self = Color::TupleEncode->new(@args);
  confess "No data values provided" if ! $self->get_tuple;
  return $self->as_RGB();
}

=head2 C<($r,$g,$b) = tuple_asRGB255()>

=head2 C<$hex = tuple_asRGBhex()>

=head2 C<($h,$s,$v) = tuple_asHSV()>

These functions work just like tuple_asRGB, but return the color in a different color space (e.g. RGB, HSV) or form (component or hex).

=cut

sub tuple_asRGB255 {
  my @args = @_;
  my $self = Color::TupleEncode->new(@args);
  confess "No data values provided" if ! $self->get_tuple;
  return $self->as_RGB255();
}

sub tuple_asRGBhex {
  my @args = @_;
  my $self = Color::TupleEncode->new(@args);
  confess "No data values provided" if ! $self->get_tuple;
  return $self->as_RGBhex();
}

sub tuple_asHSV {
  my @args = @_;
  my $self = Color::TupleEncode->new(@args);
  confess "No data values provided" if ! $self->get_tuple;
  return $self->as_HSV();
}

=for comment
Having defined a tuple with new() or set_tuple(), return the corresponding color value.

=cut

sub _get_value {
  my $self   = shift;
  my $method = $self->get_options(-method);
  my $v      = eval $method.q{::_get_value($self)};
  confess "Problem calculating value: $@" if $@;
  return $v;
}

=for comment
Having defined a tuple with new() or set_tuple(), return the corresponding color saturation.

=cut

sub _get_saturation {
  my $self   = shift;
  my $method = $self->get_options(-method);
  my $s      = eval $method.q{::_get_saturation($self)};
  confess "Problem calculating saturation: $@" if $@;
  return $s;
}

=for comment
Having defined a tuple with new() or set_tuple(), return the corresponding color hue.

=cut

sub _get_hue {
  my $self   = shift;
  my $method = $self->get_options(-method);
  my $h      = eval $method.q{::_get_hue($self)};
  confess "Problem calculating hue: $@" if $@;
  return $h;
}

=for comment
Check that the data triplet has all values defined. A list must be passed - not a list reference!

=cut

sub _validate_tuple {
  my ($self,@tuple_in) = @_;
  my @ok_tuple;
  my @tuple;
  if(@tuple_in == 1) {
    my $tuple_in_first = $tuple_in[0];
    if( ref( $tuple_in_first ) eq "ARRAY") {
      @tuple = @$tuple_in_first;
    } 
    elsif ( ref( $tuple_in_first ) ) {
      confess "Tuple must be passed in as a list or array reference.";
    } 
    else {
      @tuple = @tuple_in;
    }
  }
  else {
    @tuple = @tuple_in;
  }
  my $method     = $self->get_options(-method);
  my $tuple_size = $method->_get_tuple_size();
  if(@tuple == $tuple_size) {
    for my $i (0..$tuple_size-1) {
      confess "value at index [$i] in data tuple is not defined." if ! defined $tuple[$i];
      confess "value at index [$i] cannot be a reference - saw $tuple[$i] which is a ".ref($tuple[$i]) if ref $tuple[$i];
      confess "value at index [$i] in data tuple is not a number." if $tuple[$i] !~ qr{^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$};
    }
    return @tuple;
  } else {
    confess "Wrong number of values in tuple. Must pass exactly ",$tuple_size," values as input data, either as list reference. Saw ".int(@tuple)." values: ".join(" ",@tuple);
  }
}

=for comment
Retrieve allowed and default options

=cut

sub _get_ok_options {
  my $self = shift;
  my $method = $self->{options}{-method};
  my @OK = ($method->_get_ok_options,@OPTIONS_OK);
  return @OK;
}

sub _get_implementation_ok_options {
  my $self = shift;
  my $method = $self->{options}{-method};
  my @OK = $method->_get_ok_options;
  return @OK;
}

sub _get_default_options {
  my $self   = shift;
  my $method = $self->{options}{-method};
  my %DEF    = (%OPTIONS_DEFAULT,$method->_get_default_options);
  return \%DEF;
}
sub _get_implementation_default_options {
  my $self   = shift;
  my $method = $self->{options}{-method};
  my %DEF    = $method->_get_default_options;
  return \%DEF;
}

=pod 

=head1 IMPLEMENTING AN ENCODING CLASS 

=head2 Required Functions

It is assumed that the encoding utility class will implement the following functions.

=over

=item C<_get_hue()>

=item C<_get_saturation()>

=item C<_get_value()>

=back

Encodings must be done from a tuple to HSV color space. HSV is a
natural choice because it is possible to visually identify individual
H,S,V components of a color (e.g. orage saturated dark). On the other
hand, doing so in RGB is very difficult (what is the R,G,B
decomposition of a dark desaturated orange?).

Each of these functions should be implemented as follows. For example, C<_get_saturation>

  sub _get_saturation {
    # obtain the Color::TupleEncode object
    my $self = shift;
    # extract data tuple
    my (@tuple) = $self->get_tuple;
    my $saturation;
    ... now use @tuple to define $saturation
    return $saturation;
  }

=over

=item C<_get_tuple_size()>

=back

This function returns the size of the tuple used by the encoding. You
can implement this as follows,

  Readonly::Scalar our $TUPLE_SIZE => 3;

  sub _get_tuple_size {
    return $TUPLE_SIZE;
  }

=over

=item C<_get_ok_options()>

=item C<_get_default_options()>

=back

You must define a package variable C<@OPTIONS_OK>, which lists all
acceptable options for this encoding. Any options you wish to be set
by default when this method is initially set should be in C<%OPTIONS_DEFAULT>.

For example,

  Readonly::Array our @OPTIONS_OK      => 
      (qw(-ha -hb -hc -saturation -value));
  
  Readonly::Hash  our %OPTIONS_DEFAULT => 
      (-ha=>0,-hb=>120,-hc=>240,-saturation=>{dmin=>0,dmax=>1});

Two functions provice access to these variables

  sub _get_ok_options {
    return @OPTIONS_OK; 
  }

  sub _get_default_options {
    return %OPTIONS_DEFAULT;
  }

=head2 Using Your Implementation

See the example files with this distribution

  # uses Color::TupleEncode::2Way
  > examples/example-2way

  # uses Color::TupleEncode::Baran
  > examples/example-3way

of how to go about using your implementation.

For example, if you have created C<Color::TupleEncode::4Way>, which
encodes 4-tuples, then you would use it thus

  use Color::TupleEncode;
  use Color::TupleEncode::4Way;

  # set the method to your implementation
  $encoder = Color::TupleEncode->new(method=>"Color::TupleEncode::4Way");

  # set any options for your implementation
  $encoder->set-options(-option1=>1,-option2=>10)

  # encode
  ($h,$s,$v) = $encoder->as_HSV(1,2,3,4);

=head1 AUTHOR

Martin Krzywinski, C<< <martin.krzywinski at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-color-tupleencode at rt.cpan.org>, or through
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

L<Color::GraphicsObject> for converting colors between color spaces.

L<Color::TupleEncode::Baran> for the 3-tuple encoding (by I<Baran et al.>).

L<Color::TupleEncode::2Way> for the 2-tuple encoding (by Author).

=head1 ACKNOWLEDGEMENTS

For details about the color encoding, see

=over 

=item Color::TupleEncode::Baran

Encodes a 3-tuple to a color using the scheme described in

  Visualization of three-way comparisons of omics data
  Richard Baran Martin Robert, Makoto Suematsu, Tomoyoshi Soga and Masaru Tomita
  BMC Bioinformatics 2007, 8:72 doi:10.1186/1471-2105-8-72

This publication can be accessed at L<http://www.biomedcentral.com/1471-2105/8/72/abstract/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Martin Krzywinski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Color::TupleEncode
