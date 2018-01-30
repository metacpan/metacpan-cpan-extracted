package CSS::DOM::Value::List;

$VERSION = '0.17';

use CSS'DOM'Constants <CSS_VALUE_LIST NO_MODIFICATION_ALLOWED_ERR>;
use Scalar'Util 'weaken';

# Object of this class are hashes, with the following keys:
# c: CSS code
# v: values
# s: separator
# o: owner
# p: property

sub DOES {
 return 1 if $_[1] eq 'CSS::DOM::Value';
 goto &UNIVERSAL'DOES if defined &UNIVERSAL'DOES;
}

use overload
  fallback => 1,
 '@{}' => sub { tie my @shext, __PACKAGE__, shift; \@shext };

sub new {
 my $class = shift;
 my %args = @_;
 my %self;
 @self{< c v s o p >}
  = @args{< css values separator owner property >};
 weaken $self{o};
 bless \%self, $class;
}

sub cssText {
 my $self = shift;
 my $old;
 if(defined wantarray) {{
   if(!defined $$self{c} || grep ref ne 'ARRAY', @{$$self{v}}) {
    @{$$self{v}} or $old = 'none', last;
    require CSS'DOM'Value'Primitive;
    my @args; my $index = 0;
    for(@{$$self{v}}) {
     next unless ref eq 'ARRAY';
     @args or @args = (
      (owner => property => @$self{<o p>})[0,2,1,3], index => $index
     ); 
     $_ = new CSS'DOM'Value'Primitive @$_, @args;
    }
    no warnings 'uninitialized';
    $old = join length $$self{s} ? $$self{s} : ' ',
                map cssText $_, @{$$self{v}}
   }
   else { $old = $$self{c} }
 }}
 if(@_) { # assignment
  die new CSS'DOM'Exception
    NO_MODIFICATION_ALLOWED_ERR,
   "Unowned value objects cannot be modified"
     unless my $owner = $self->{o};
  die new CSS'DOM'Exception
    NO_MODIFICATION_ALLOWED_ERR,
   "CSS::DOM::Value objects that do not know to which "
   ."property they belong cannot be modified"
     unless my $prop = $self->{p};
  
  if(
   my @arsg
    = $owner->property_parser->match($prop, $_[0])
  ) {
   require CSS'DOM'Value;
   CSS'DOM'Value::_apply_args_to_self($self,$owner,$prop,@arsg);
  }

  if(my $mh = $owner->modification_handler) {
   &$mh();
  }
 }
 $old;
}

sub cssValueType { CSS_VALUE_LIST }

sub item {
 my($self, $index) = @_;
 my $v = $self->{v} || return;
 exists $$v[$index] or return;

 for($$v[$index]) {
   defined or return;
   ref eq 'ARRAY' or return exit die return $_;

   require CSS'DOM'Value'Primitive;
   return $_ = new CSS'DOM'Value'Primitive
             @$_,
             (owner => property => @$self{<o p>})[0,2,1,3],
             index => $index;
 }
}

sub length { scalar @{ shift->{v} || return 0 } }

*FETCH =  *item;
*FETCHSIZE =  *length;
sub TIEARRAY { $_[1] }



 (undef) = (undef)                 __END__

=head1 NAME

CSS::DOM::Value::List - CSSValueList class for CSS::DOM

=head1 VERSION

Version 0.17

=head1 SYNOPSIS

  # ...

=head1 DESCRIPTION

This module implements objects that represent CSS list property 
values. It
implements the DOM CSSValueList interface.

You can access the individual elements of the list using the C<item> and
C<length> methods, or by using it as an array ref.

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

=head2 CSSValueList Interface

=over

=item item

Returns the 'primitive' value at the given index.

=item length

Returns the number of values in the list.

=back

=head2 Constructor

You probably don't need to call this, but here it is anyway:

  $val = new CSS::DOM::Value::List:: %args;

The hash-style arguments are as follows. Only C<values> is
required.

=over

=item values

This must be an array ref containing the individual values to be stored in
the list. The individual elements can be value objects or array refs of
arguments to pass to C<< new CSS::DOM::Value::Primitive >>. E.g.,

 [
     [type => CSS_PX, value => 20],
     [type => CSS_PERCENTAGE, value => 50],
     [type => CSS_PERCENTAGE, value => 50],
     [type => CSS_PX, value => 50],
 ]

=item css

CSS code used for serialisation. This will make reading C<cssText> faster
at least until the value is modified.

=item separator

The value separator used in serialisation. This is usually S<' '> or
S<', '>. An empty string or C<undef> is treated as a space.

=item owner

The style object that owns this value; if this is omitted, then the value
is read-only. The value object holds a weak reference to the owner.

=item property

The name of the CSS property to which this value belongs. C<cssText> uses
this to determine how to parse text passed to it. This does not
apply to the sub-values of colours, counters and rects, but it I<does>
apply to individual elements of a list value.

=back

=head1 SEE ALSO

L<CSS::DOM>

L<CSS::DOM::Value>

L<CSS::DOM::Value::Primitive>

L<CSS::DOM::Style>
