package CSS::DOM::Value::Primitive;

$VERSION = '0.16';

use warnings; no warnings qw 'utf8 parenthesis';;
use strict;

use Carp;
use CSS::DOM::Constants
 <%SuffixToConst NO_MODIFICATION_ALLOWED_ERR INVALID_ACCESS_ERR>;
use CSS::DOM::Util qw '
	unescape
	unescape_url
	unescape_str escape_str
	             escape_ident ';
use Exporter 5.57 'import';

sub DOES {
 return 1 if $_[1] eq 'CSS::DOM::Value';
 goto &UNIVERSAL'DOES if defined &UNIVERSAL'DOES;
}

use constant 1.03 our $_const = { # Don’t conflict with the superclass!
    type => 2,
    valu => 3,  # counters
    csst => 4,  name => 0,
    ownr => 5,  sepa => 1,
    prop => 6,  styl => 2,
    indx => 7,
    form => 8,
    sfrm => 9, # serialisation format; used currently only by colours
};
{ no strict; delete @{__PACKAGE__.'::'}{_const => keys %{our $_const}} }

*EXPORT_OK = $CSS::DOM::Constants::EXPORT_TAGS{primitive};
our %EXPORT_TAGS = ( all => \our @EXPORT_OK );


sub new {
	my $class = shift;
	my %args = @_;
	for('type','value') {
		croak "The $_ argument to new ${\__PACKAGE__} is required"
		 unless exists $args{$_};
	}
	my $self = bless[], $class;
	@$self[type,valu,csst,ownr,prop,indx,form]
	 = @args{< type value css owner property index format >};
	$self;
}

my @unit_suffixes;
$unit_suffixes[CSS_PERCENTAGE ] = '%';
$unit_suffixes[CSS_EMS        ] = 'em';
$unit_suffixes[CSS_EXS        ] = 'ex';
$unit_suffixes[CSS_PX         ] = 'px';
$unit_suffixes[CSS_CM         ] = 'cm';
$unit_suffixes[CSS_MM         ] = 'mm';
$unit_suffixes[CSS_IN         ] = 'in';
$unit_suffixes[CSS_PT         ] = 'pt';
$unit_suffixes[CSS_PC         ] = 'pc';
$unit_suffixes[CSS_DEG        ] = 'deg';
$unit_suffixes[CSS_RAD        ] = 'rad';
$unit_suffixes[CSS_GRAD       ] = 'grad';
$unit_suffixes[CSS_MS         ] = 'ms';
$unit_suffixes[CSS_S          ] = 's';
$unit_suffixes[CSS_HZ         ] = 'Hz';
$unit_suffixes[CSS_KHZ        ] = 'kHz';

sub cssText { 
	my $self = shift;
	my $old;
	if(defined wantarray) {
		if(defined $self->[csst]) {
			$old = $self->[csst]
		}
		else { for($self->[type]) {
			my $val = $self->[valu];
			$old
			 = $_ == CSS_RECT 
			    ? 'rect('
			     .  join(
			         ', ',
			          map $self->$_->cssText,
			           <top right bottom left>
			        )
			     .')'
			 : $_ == CSS_RGBCOLOR
			    ? ref $val eq 'ARRAY'
			       ? do {
			          my(@val_objs,$ret)
			           = map $self->$_, <red green blue>;
			          if(
			           my $form = $$self[sfrm]
				    and
			           @$val < 4 || $$val[3]->getFloatValue==1
			          ){
			           if($form =~ /^#/) {
			            # Try to preserve original #bed/#c0ffee
			            # format if possible
			            my $digits = chop $form;
			            if($digits == 1) {
			             for my $val_obj(@val_objs) {
			              my $val = $val_obj->getFloatValue;
			              if(
			               $val_obj->primitiveType
			                == CSS_NUMBER
			              ){
			               not $val % 17 and $val == int $val
			                and $val > 0 and $val < 256
			             # ~~~ Would it be faster simply to use
			             #     a regexp?
			                 or undef $ret, last;
			               $ret .= sprintf "%x", $val/17;
			              }
			              else { # percentage
			               not $val % 20 and $val == int $val
			                and $val > 0 and $val < 101
			             # ~~~ Would it be faster simply to use
			             #     a regexp?
			                 or undef $ret, last;
			               $ret .= sprintf "%x", $val * .15;
			              }
			             }
			            }
			            if(!$val || $digits == 2) {
			             for my $val_obj(@val_objs) {
			              my $val = $val_obj->getFloatValue;
			              if(
			               $val_obj->primitiveType
			                == CSS_NUMBER
			              ){
			               $val == int $val
			                and $val > 0 and $val < 256
			                 or undef $ret, last;
			               $ret .= sprintf "%02x", $val;
			              }
			              elsif($digits == 2) { # percentage
			               not $val % 20 and $val == int $val
			                and $val > 0 and $val < 101
			             # ~~~ Would it be faster simply to use
			             #     a regexp?
			                 or undef $ret, last;
			               $ret .= sprintf "%02x",$val * 2.55;
			              }
			             }
			            }
			            $ret and substr $ret,0,0, = '#';
			           }
			           else { # named colour
			            my $rgb = (\our %Colours)->{lc $form};
			            $val_objs[0]->getFloatValue
			             == $$rgb[0]
			            and $val_objs[1]->getFloatValue
			             == $$rgb[1]
			            and $val_objs[2]->getFloatValue
			             == $$rgb[2]
			            and $ret = $form;
			           }
			          }
			          
			          unless($ret) {
			           my @types
			            = map $_->primitiveType, @val_objs;
			           if($types[0] == $types[1]
			           && $types[0] == $types[2]) {
			            $ret = join ", ",
			                         map cssText $_, @val_objs;
			           }
			           else {
			            my $type = $types[
			              $types[0] == $types[1]
			               || $types[0] == $types[2]
			              ? 0
			              : 1
			            ];
			            $ret = join ", ", $type == CSS_NUMBER
			             ? map
			                $types[$_] == CSS_NUMBER
			                 ? $val_objs[$_]->getFloatValue
			                 : $val_objs[$_]->getFloatValue
			                    * 255/100,
			                0...2
			             : map
			                $types[$_] == CSS_PERCENTAGE
			                 ? $val_objs[$_]->getFloatValue
			                 : $val_objs[$_]->getFloatValue
			                    * 100/255 . '%',
			                0...2;
			           }
			           my $alpha;
			           @$val >= 4 && (
			            $alpha = $self->alpha->cssText
			           ) != 1
			            ? "rgba($ret, $alpha)"
			            : "rgb($ret)"
			          }
			         }
			       : $val =~ /^#/
			         ? $val
			         : escape_ident $val
			 :   _serialise($_,$val)
		}}
	}
	if(@_) {
		require CSS'DOM'Exception,
		die new CSS'DOM'Exception
		  NO_MODIFICATION_ALLOWED_ERR,
		 "Unowned value objects cannot be modified"
		   unless my $owner = $self->[ownr];
		my $prop = $$self[prop];

		# deal with formats
		if(my $format = $$self[form]) {
			if(!our $parser) {
				require CSS'DOM'PropertyParser;
				add_property{
				 $parser = new CSS'DOM'PropertyParser
				} _=>our $prop_spec = {};
			}
			our $prop_spec->{format} = $format;
			if(my @args = match { our $parser } _=> shift) {
				require CSS'DOM'Value;
				CSS'DOM'Value'_apply_args_to_self(
				 $self, $owner, $prop,
				 @args, format => $format, 
				);				
			}
		}

		# This is never reached, at least not when CSS::DOM’s mod-
		# ules call the constructor:
		elsif(!defined $prop) {
			require CSS'DOM'Exception,
			die new CSS'DOM'Exception
			  NO_MODIFICATION_ALLOWED_ERR,
			 ref($self) . " objects that do not know to which "
			 ."property they belong cannot be modified"
		}

		# sub-values of a list
		elsif(defined(my $index = $$self[indx])) {
			my $old_list
				 = $owner->getPropertyCSSValue($prop);
				# ~~~ What do we do if $old_list is undef?
				#     In what circumstances can
				#     that happen?
			# ~~~ If we add an API to PropertyParser to allow
			#     for list sub-value formats, we can do away
			#     with this inefficient mess.
			my $length = $old_list->length;
			my @arsg
			  = $owner->property_parser->match(
			     $prop,
			     join $old_list->{s}, # ~~~ we probably need an
			                     # API to avoid this encap viol
			      map(
			       $old_list->item($_)->cssText, 0..$index-1
			      ),
			      $_[0],
			      map(
			       $old_list->item($_)->cssText,
			       $index+1..$length-1
			      ),
			    );
			require CSS'DOM'Value;
			CSS'DOM'Value'_load_if_necessary($arsg[1]);
			my $list = $arsg[1]->new(
			 owner => $owner,
			 property => $prop,
			 @arsg[2..$#arsg]
			);
			if($list->length != $length) {
					# This would mean we were given a
					# string with commas or a blank
					# string, which are invalid.
					return $old
			}
			@$self = @{ $list->item($index) };
		}

		# property-level values
		elsif(
		 my @arsg
		  = $owner->property_parser->match($prop, $_[0])
		) {
			require CSS'DOM'Value;
			CSS'DOM'Value'_apply_args_to_self(
				 $self, $owner, $prop, @arsg
			);
		}

		if(my $mh = $owner->modification_handler) {
			&$mh();
		}
	}
	$old;
}

sub _serialise {
 my ($type, $val) = @_;
 for($type) {
   no warnings 'numeric';
   return
      $_ == CSS_ATTR
       ? 'attr(' . $val . ')'
    : $_ == CSS_URI
       ? 'url(' . $val.  ')'
    : $_ == CSS_RECT 
       ? die "_serialise does not support rects"
    : $_ == CSS_RGBCOLOR
       ? die "_serialise does not support colours"
    : $_ == CSS_STRING
       ? do {
          (my $str = $val) =~ s/'/\\'/g;;
          return "'$str'";
         }
    : $_ == CSS_COUNTER
       ? 'counter' . 's' x defined($$val[sepa]) . '('
         . escape_ident($$val[name])
         . (defined $$val[sepa]
            ? ", " . escape_str($$val[sepa])
            : '' )
         . (defined $$val[styl]
            ? ", " . escape_ident($$val[styl])
            : '' )
         . ")"
    : $_ == CSS_DIMENSION
       ? $$val[0].escape_ident$$val[1]
    : $_ == CSS_NUMBER
       ? 0+$val
    :    $unit_suffixes[$_]
          ? 0+$val . $unit_suffixes[$_]
          : $val;
 }

}

sub cssValueType { CSS::DOM::Value::CSS_PRIMITIVE_VALUE }

sub primitiveType { shift->[type] }

sub setFloatValue {
  my ($self,$type,$val) = @'_;

  require CSS'DOM'Exception,
  die new CSS'DOM'Exception INVALID_ACCESS_ERR, "Invalid value type"
   if $type == CSS_UNKNOWN || $type == CSS_COUNTER
   || $type == CSS_RECT || $type == CSS_RGBCOLOR || $type == CSS_DIMENSION;

  # This is not particularly efficient, but I doubt anyone is actually
  # using this API.
  no warnings 'numeric';
  $self->cssText(my $css = _serialise($type, $val));
  require CSS'DOM'Exception,
  die new CSS'DOM'Exception INVALID_ACCESS_ERR, "Invalid value: $css"
   if $self->cssText ne $css;
 _:
}

sub getFloatValue {
 my $self = shift;

 # There are more types that are numbers than are not, so we
 # invert our list.
 my $type = $self->[type];
 require CSS'DOM'Exception,
 die new CSS'DOM'Exception INVALID_ACCESS_ERR, "Not a numeric value"
  if $type == CSS_UNKNOWN || $type == CSS_STRING || $type == CSS_URI 
  || $type == CSS_IDENT || $type == CSS_ATTR || $type == CSS_COUNTER
  || $type == CSS_RECT || $type == CSS_RGBCOLOR;

 no warnings"numeric";
 0+($type == CSS_DIMENSION ? $$self[valu][0] : $$self[valu])
}

*setStringValue = *setFloatValue;

sub getStringValue {
 my $self = shift;

 my $type = $self->[type];
 require CSS'DOM'Exception,
 die new CSS'DOM'Exception INVALID_ACCESS_ERR, "Not a string value"
  unless $type == CSS_STRING || $type == CSS_URI
      || $type == CSS_IDENT  || $type == CSS_ATTR;

 "$$self[valu]"
}

# ------------- Rect interface --------------- #

sub _autoviv_rect_value {
 my($self,$index) = @_;
 for my $val($$self[valu][$index]) {
  if(ref $val eq 'ARRAY') {
   $val = new
    __PACKAGE__,
     owner => $$self[ownr],
     format => '<length>|auto',
     @$val;
   delete $$self[csst]; # prevent this from being used by cssText; hence-
  }                     # forth we must use the subvalues
  return $val
 }
}

sub top { _autoviv_rect_value $_[0], 0 }
sub right { _autoviv_rect_value $_[0], 1 }
sub bottom { _autoviv_rect_value $_[0], 2 }
sub left { _autoviv_rect_value $_[0], 3 }

# ------------- RGBColor interface --------------- #

sub _autoviv_colour_value {
 my($self,$index) = @_;
 if(ref $$self[valu] ne 'ARRAY') {
  if($$self[valu] =~ /^#(..|.)(..|.)(..|.)/) {
   my $x = -length($1) + 3;
   $$self[sfrm] = '#' . length $1;
   no strict 'refs';
   $$self[valu] = [
    map([type => CSS_NUMBER, value => hex $$_ x$x], 1...3),
   ];
  }
  else {
   our %Colours or require "CSS/DOM/Value/Primitive/colours.pl";
   my $rgb = $Colours{lc($$self[sfrm] = $$self[valu])};
   $$self[valu] = [
    map
     [type => CSS_NUMBER, value => $_],
     @$rgb
   ];
  }
 }
 for my $val($$self[valu][$index]) {
  if(ref $val eq 'ARRAY') {
   $val = new
    __PACKAGE__,
     owner => $$self[ownr],
     format => $index == 3 ? '<number>' : '<number>|<percentage>',
     @$val;
   delete $$self[csst];
  }
  elsif(!defined $val and $index == 3) { # alpha
   $val = new
    __PACKAGE__,
     owner => $$self[ownr],
     format => '<number>',
     type => CSS_NUMBER,
     value => 1; 
   delete $$self[csst];
  }
  return $val
 }
}

sub red { _autoviv_colour_value $_[0], 0 }
sub green { _autoviv_colour_value $_[0], 1 }
sub blue { _autoviv_colour_value $_[0], 2 }
sub alpha { _autoviv_colour_value $_[0], 3 }

                              !()__END__()!

=head1 NAME

CSS::DOM::Value::Primitive - CSSPrimitiveValue class for CSS::DOM

=head1 VERSION

Version 0.16

=head1 SYNOPSIS

  # ...

=head1 DESCRIPTION

This module implements objects that represent CSS primitive property 
values (as opposed to lists). It
implements the DOM CSSPrimitiveValue, Rect, and RGBColor interfaces.

=head1 METHODS

If you need the constructor, it's below the object methods. Normally you
would get an object via L<CSS::DOM::Style's C<getPropertyCSSValue>
method|CSS::DOM::Style/getPropertyCSSValue>.

=head2 CSSValue Interface

=over 4

=item cssText

Returns a string representation of the attribute. Pass an argument to set 
it.

=item cssValueType

Returns C<CSS::DOM::Value::CSS_PRIMITIVE_VALUE>.

=back

=head2 CSSPrimitiveValue Interface

=over

=item primitiveType

Returns one of the L</CONSTANTS> listed below.

=item getFloatValue

Returns a number if the value is numeric.

=back

The rest have still to be implemented.

=head2 Rect Interface

The four methods C<top>, C<right>, C<bottom> and C<left> each return
another
value object representing the individual value.

=head2 RGBColor Interface

The four methods C<red>, C<green>, C<blue> and C<alpha> each return another
value object representing the individual value.

=head2 Constructor

You probably don't need to call this, but here it is anyway:

  $val = new CSS::DOM::Value::Primitive:: %args;

The hash-style arguments are as follows. Only C<type> and C<value> are
required.

=over

=item type

One of the constants listed below under L</CONSTANTS>

=item value

The data stored inside the value object. The format expected depends on the
type. See below.

=item css

CSS code used for serialisation. This will make reading C<cssText> faster
at least until the value is modified.

=item owner

The style object that owns this value; if this is omitted, then the value
is read-only. The value object holds a weak reference to the owner.

=item property

The name of the CSS property to which this value belongs. C<cssText> uses
this to determine how to parse text passed to it. This does not
apply to the sub-values of colours, counters and rects, but it I<does>
apply to individual elements of a list value.

=item index

The index of this value within a list value (only applies to elements of a
list, of course).

=item format

This is used by sub-values of colours and rects. It determines
how assignment to C<cssText> is handled. This uses the same syntax as the
formats in L<CSS::DOM::PropertyParser|CSS::DOM::PropertyParser/format>.

=back

Here are the formats for the C<value> argument, which depend on the type:

=over

=item CSS_UNKNOWN

A string of CSS code.

=item CSS_NUMBER, CSS_PERCENTAGE

A simple scalar containing a number.

=item Standard Dimensions

Also a simple scalar containing a number.

This applies to C<CSS_EMS>, C<CSS_EXS>, C<CSS_PX>, C<CSS_CM>, C<CSS_MM>, C<CSS_IN>, C<CSS_PT>, C<CSS_PC>, C<CSS_DEG>, C<CSS_RAD>, C<CSS_GRAD>, C<CSS_MS>, C<CSS_S>, C<CSS_HZ> and C<CSS_KHZ>.

=item CSS_DIMENSION

An array ref: C<[$number, $unit_text]>

=item CSS_STRING

A simple scalar containing a string (not a CSS string literal; i.e., no
quotes or escapes).

=item CSS_URI

The URL (not a CSS literal)

=item CSS_IDENT

A string (no escapes)

=item CSS_ATTR

A string containing the name of the attribute.

=item CSS_COUNTER

An array ref: C<[$name, $separator, $style]>

C<$separator> and C<$style> may each be C<undef>. If C<$separator> is
C<undef>, the object represents a C<counter(...)>. Otherwise it represents
C<counters(...)>.

=item CSS_RECT

An array ref: C<[$top, $right, $bottom, $left]>

The four elements are either CSSValue objects or
array refs of arguments to be passed to the constructor. E.g.:

 [
     [type => CSS_PX, value => 20],
     [type => CSS_PERCENTAGE, value => 50],
     [type => CSS_PERCENTAGE, value => 50],
     [type => CSS_PX, value => 50],
 ]

When these array refs are converted to objects, the C<format>
argument is supplied automatically, so you do not need to include it here.

=item CSS_RGBCOLOR

A string beginning with '#', with no escapes (such as '#fff' or '#c0ffee'),
a colour name (like red) or an array ref with three to four elements:

 [$r, $g, $b]
 [$r, $g, $b, $alpha]

The elements are either CSSValue objects or array refs of
argument lists, as with C<CSS_RECT>.

=back

=head1 CONSTANTS

The following constants can be imported with 
C<use CSS::DOM::Value::Primitive ':all'>.
They represent the type of primitive value.

=over

=item CSS_UNKNOWN    

=item CSS_NUMBER     

=item CSS_PERCENTAGE 

=item CSS_EMS        

=item CSS_EXS        

=item CSS_PX         

=item CSS_CM         

=item CSS_MM         

=item CSS_IN         

=item CSS_PT         

=item CSS_PC         

=item CSS_DEG        

=item CSS_RAD        

=item CSS_GRAD       

=item CSS_MS         

=item CSS_S          

=item CSS_HZ         

=item CSS_KHZ        

=item CSS_DIMENSION  

=item CSS_STRING     

=item CSS_URI        

=item CSS_IDENT      

=item CSS_ATTR       

=item CSS_COUNTER    

=item CSS_RECT       

=item CSS_RGBCOLOR   

=back

=head1 SEE ALSO

L<CSS::DOM>

L<CSS::DOM::Value>

L<CSS::DOM::Value::List>

L<CSS::DOM::Style>
