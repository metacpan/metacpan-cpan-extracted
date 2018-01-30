package CSS::DOM::Style;

$VERSION = '0.17';

use warnings; no warnings qw' utf8';
use strict;

use CSS::DOM::Exception 'SYNTAX_ERR';
use CSS::DOM::Util qw 'escape_ident unescape';
use Scalar::Util 'weaken';

# ~~~ use overload fallback => 1, '@{}' => 

# Internal object structure
#
# Each style object is a hash ref:
# {
#    owner       => $owner_rule,
#    parser      => $property_parser,
#    mod_handler => sub { ... },  # undef initially
#    names       => [...],
#    props       => {...},
#    pri         => {...},  # property priorities
# }
#
# The value of an element in the props hash can be one of three things
#  1) a CSSValue object
#  2) an array ref that is a blueprint for a CSSValue object:
#     [ $css_code, $class, @constructor_args]
#  3) a string of css code
# Item (3) is only used when there is no property parser.

sub parse {
	require CSS::DOM::Parser;
	goto &CSS::DOM::Parser::parse_style_declaration;
}

sub new {
	my($class) = shift;

	my $self = bless {}, $class;
	if(@_ == 1) {
		$self->{owner} = shift;
	}
	else {
		my %args = @_;
		$self->{owner} = delete $args{owner};
		$self->{parser}
		 = delete $args{property_parser};
	}
	{
		$self->{parser} ||= (
		    ($self->{owner} || next)->parentStyleSheet || next
		   )->property_parser;
	}
	weaken $self->{owner};
	return $self
}

sub cssText {
	my $self = shift;
	my $out;
	if (defined wantarray) {
		$out = join "; ", map {
			my $pri = $self->getPropertyPriority($_);
			"$_: ".$self->getPropertyValue($_)." !"x!!$pri
				. escape_ident($pri)
		} @{$$self{names}};
	}
	if(@_) {
		my $css = shift;
		!defined $css || !length $css and
			@$self{'props','names'} = (), return $out;

		require CSS::DOM::Parser;
		my $new =CSS::DOM::Parser::parse_style_declaration(
		 $css, property_parser => $$self{parser}
		);

		@$self{'props','names'} = @$new{'props','names'};
		_m($self);
	}
	return $out;
}

sub getPropertyValue { # ~~~ Later I plan to make this return lists of
                       #     scalars in list context (for list properties).
	my $self = shift;
	my $props = $self->{props} || return '';
	my $name = lc$_[0];

	if(my $spec = $self->{parser}) { serialise: {
		if(my $p = $spec->get_property($name)) {
		 if(exists $p->{serialise} and my $s = $p->{serialise}) {
		   my @p = $spec->subproperty_names($name);
		   my %p;
		   for(@p) {
		    my $v = $self->getPropertyValue($_) ;
		    length $v or last serialise;
		    $p{$_}
		     = $spec->get_property($_)->{default} eq $v ?'':$v;
		   }
		   return $s->(\%p);
		 }
		}
	}}

	exists $props->{$name}
		or return return '';
	my $val = $props->{$name};
	return ref $val eq 'ARRAY' ? $$val[0]
	     : !ref $val           ? $val
	     :                       $val->cssText;
}

sub getPropertyCSSValue {
	my $self = shift;
	$self->{parser} or return;
	exists +(my $props = $self->{props} || return)->{
	  my $name = lc$_[0]
	}	or return return;
	my $valref = \$props->{$name};
	return ref $$valref eq 'ARRAY'
		? scalar (
			$$$valref[1]->can('new')
			 || do {
			     (my $pack = $$$valref[1]) =~ s e::e/egg;
			     require "$pack.pm";
			    },
			$$valref =
			  $$$valref[1]->new(
			   owner => $self, property => $name,
			   @$$valref[2..$#$$valref],
			  )
		) : $$valref;
}

sub removeProperty {
	my $self = shift;
	my $name = lc shift;

	# Get the value so we can return it
	my $val;
	$val = $self->getPropertyValue($name)
	 if defined wantarray;

	# Get names of subprops if we are dealing with a shorthand prop
	my @to_delete;
	if(my $spec = $self->{parser}) {
		@to_delete = $spec->subproperty_names($name);
	}
	@to_delete or @to_delete = $name;

	# Delete the properties
	for my $name(@to_delete) {
		delete +($self->{props} || return $val)->{$name};
		@{$$self{names}} = grep $_ ne $name,
			@{$$self{names} || return $val};
	}

	$val;
}

sub getPropertyPriority {
	return ${shift->{pri}||return ''}{lc shift} || ''
}

sub setProperty {
	my ($self, $name, $value, $priority) = @_;

	# short-circuit for the common case
	length $value or $self->removeProperty($name),return;

	require CSS'DOM'Parser;
	my @tokens = eval { CSS'DOM'Parser'tokenise_value($value); }
		or die CSS::DOM'Exception->new( SYNTAX_ERR, $@);

	# check for whitespace/comment assignment
	$tokens[0] =~ /^s+\z/ and $self->removeProperty($name),return;

	my $props = $$self{props} ||= {};
	my $pri = $$self{pri} ||= {};

	my $val;
	if(my $spec = $self->{parser}) {
		my(@args) = $spec->match($name, @tokens)
			or return;
		if(@args == 1) { # shorthand
			while(my($k,$v) = each %{ $args[0] }) {
				$self->removeProperty($k), next
				 if $v eq "";
				exists $$props{$k=lc$k}
				 or push @{$$self{names}}, $k;
				$$props{$k} = $v;
				$$pri{$k} = $priority;
			}
			return;
		}
		else {
			$val = \@args;
		}
	}

	exists $$props{$name=lc$name} or push @{$$self{names}}, $name;
	$$props{$name} = $val || join "", @{ $tokens[1] };
	$$pri{$name} = $priority;

	_m($self);
	return
}

sub item {
	my $ret = shift->{names}[shift];
	return defined $ret ? $ret : ''
}

sub parentRule {
	shift->{owner}
}

sub _set_property_tokens { # private
	my ($self,$name,$types,$tokens) = @_;

	# Parse out the priority first
	my $priority;
	if($types =~ /(s?(ds?))i\z/ and $tokens->[$-[2]] eq '!') {
		$types =~ s///;
		$priority = unescape pop @$tokens;
		pop @$tokens for 1..length $1;
	} else {
		$priority = '';
	}

	# Get the prop & priority hashes
	my $props = $$self{props} ||= {};
	my $pri = $$self{pri} ||={};

	# See if we need to parse the value
	my $val;
	if(my $spec = $self->{parser}) {
		my(@args) = $spec->match($name,$types,$tokens)
			or return;
		if(@args == 1) {
			while(my($k,$v) = each %{ $args[0] }) {
				$self->removeProperty($k), next
				 if $v eq "";
				exists $$props{$k=lc$k}
				 or push @{$$self{names}}, $k;
				$$props{$k} = $v;
				$$pri{$k} = $priority;
			}
			return;
		}
		else {
			$val = \@args;
		}
	}
	else { $val = join "", @$tokens }

	# Assign the value & priority
	exists $$props{$name=lc$name} or push @{$$self{names}}, $name;
	$$props{$name} = $val;
	$$pri{$name} = $priority;
}


{ my $prop_re = qr/[a-z]+(?:[A-Z][a-z]+)*/;
sub can {
	SUPER::can { shift } @_ or
		$_[0] =~ /^$prop_re\z/o ? \&{+shift} : undef;
}
sub AUTOLOAD {
	my $self = shift;
	if(our $AUTOLOAD =~ /(?<=:)($prop_re)\z/o) {
		(my $prop = $1) =~ s/([A-Z])/-\l$1/g;
		my $val;
		defined wantarray
			and $val = $self->getPropertyValue($prop);
		@_ and $self->setProperty($prop, shift);
		return $val;
	} else {
		die "Undefined subroutine $AUTOLOAD called at ",
			join(" line ", (caller)[1,2]), ".\n";
	}
}
sub DESTROY{}
}
*cssFloat = \&float;

sub modification_handler {
	my $old = (my $self = shift)->{mod_handler};
	$self->{mod_handler} = shift if @_;
	$old;
}

sub _m#odified
{
	&{$_[0]->{mod_handler} or return}($_[0]);
}

sub property_parser { shift->{parser} }

sub length { # We put this one last to avoid having to say CORE::length
             # elsewhere.
	scalar @{shift->{names}||return 0}
}



                              !()__END__()!

=head1 NAME

CSS::DOM::Style - CSS style declaration class for CSS::DOM

=head1 VERSION

Version 0.17

=head1 SYNOPSIS

  use CSS::DOM::Style;
  
  $style = CSS::DOM::Style::parse(' text-decoration: none ');
  
  $style->cssText; # returns 'text-decoration: none'
  $style->cssText('color: blue'); # replace contents
  
  $style->getPropertyValue('color'); # 'blue'
  $style->color;                     # same
  $style->setProperty(color=>'green'); # change it
  $style->color('green');              # same

=head1 DESCRIPTION

This module provides the CSS style declaration class for L<CSS::DOM>. (A
style declaration is what comes between the braces in C<p { margin: 0 }>.)
It 
implements
the CSSStyleDeclaration DOM interface.

=head1 CONSTRUCTORS

=over 4

=item CSS::DOM::Style::parse( $string )

=item CSS::DOM::Style::parse( $string, property_parser => $parser )

This parses the C<$string> and returns a new style declaration 
object. This is useful if you have text from an HTML C<style> attribute,
for instance.

For details on C<$property_parser>, see L<CSS::DOM::PropertyParser>.

=item new CSS::DOM::Style $owner_rule

=item new CSS::DOM::Style owner => $owner_rule, property_parser => $p

You don't normally need to call this, but, in case you do, here it is.
C<$owner_rule>, which is optional, is expected to be a L<CSS::DOM::Rule>
object, or a subclass like L<CSS::DOM::Rule::Style>.

=back

=head1 METHODS

=over 4

=item cssText ( $new_value )

Returns the body of this style declaration (without the braces). If you
pass an argument, it will parsed and replace the existing CSS data.

=item getPropertyValue ( $name )

Returns the value of the named CSS property as a string.

=item getPropertyCSSValue ( $name )

Returns an object representing the property's value. 
(See L<CSS::DOM::Value>.)

=item removeProperty ( $name )

Removes the named property, returning its value.

=item getPropertyPriority

Returns the property's priority. This is usually the empty string or the
word 'important'.

=item setProperty ( $name, $value, $priority )

Sets the CSS property named C<$name>, giving it a value of C<$value> and
setting the priority to C<$priority>.

=item length

Returns the number of properties

=item item ( $index )

Returns the name of the property at the given index.

=item parentRule

Returns the rule to which this declaration belongs.

=item modification_handler ( $coderef )

This method, not part of the DOM, allows you to attach a call-back routine
that is run whenever a change occurs to the style object (with the style
object as its only argument). If you call it
without an argument it returns the current handler. With an argument, it
returns the old value after setting it.

=item property_parser

This returns the parser that was passed to the constructor.

=back

This module also has methods for accessing each CSS property directly.
Simply capitalise each letter in a CSS property name that follows a hyphen,
then remove the hyphens, and you'll have the method name. E.g., call the
C<borderBottomWidth> method to get/set the border-bottom-width property.
One exception to this is that C<cssFloat> is the method used to access the
'float' property. (But you can also use the C<float> method, though it's
not part of the DOM standard.)

=head1 SEE ALSO

L<CSS::DOM>

L<CSS::DOM::Rule::Style>

L<CSS::DOM::PropertyParser>

L<HTML::DOM::Element>
