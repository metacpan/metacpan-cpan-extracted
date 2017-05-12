package CSS::DOM::Value;

$VERSION = '0.16';

use warnings; no warnings qw 'utf8 parenthesis';;
use strict;

use Carp;
use CSS::DOM::Constants;
use CSS'DOM'Exception 'NO_MODIFICATION_ALLOWED_ERR';
use Exporter 5.57 'import';
use Scalar'Util < weaken reftype >;

use constant 1.03 our $_const = {
    type => 0,
    valu => 1,
    ownr => 2,
    prop => 3,
};
{ no strict; delete @{__PACKAGE__.'::'}{_const => keys %{our $_const}} }

*EXPORT_OK = $CSS::DOM::Constants::EXPORT_TAGS{value};
our %EXPORT_TAGS = ( all => \our @EXPORT_OK );

sub new {
	my $self = bless[], shift;
	my %args = @_;
	my $type = $self->[type] = $args{type};
	$type == CSS_CUSTOM
	? !exists $args{value} && croak
	   'new CSS::DOM::Value(type => CSS_CUSTOM) requires a value'
	: $type == CSS_INHERIT
		|| croak "Type must be CSS_CUSTOM or CSS_INHERIT";

	@$self[valu,ownr,prop] = @args{< value owner property >};
	weaken $$self[ownr];

	$self;
}

sub cssValueType { shift->[type] }

sub cssText {
	my $self = shift;
	my $old = $self->[type] == CSS_CUSTOM
		? $self->[valu] : 'inherit'
	 if defined wantarray;
	if(@_) {
		die new CSS'DOM'Exception
		  NO_MODIFICATION_ALLOWED_ERR,
		 "Unowned value objects cannot be modified"
		   unless my $owner = $self->[ownr];
		die new CSS'DOM'Exception
		  NO_MODIFICATION_ALLOWED_ERR,
		 "CSS::DOM::Value objects that do not know to which "
		 ."property they belong cannot be modified"
		   unless my $prop = $self->[prop];

		if(
		 my @arsg
		  = $owner->property_parser->match($prop, $_[0])
		) {
			_apply_args_to_self($self,$owner,$prop,@arsg);
		}

		if(my $mh = $owner->modification_handler) {
			&$mh();
		}
	}
	$old
}

sub _apply_args_to_self {
  my($self,$owner,$prop,@arsg) = @_;
 _load_if_necessary($arsg[1]);
  my $new = $arsg[1]->new(
   owner => $owner, property => $prop, @arsg[2...$#arsg]
  );
  reftype $self eq "HASH"
   ?  %$self = %$new
   : (@$self = @$new);
  bless $self, ref $new unless ref $new eq ref $self;
}

sub _load_if_necessary {
 $_[0]->can('new')
  || do {
      (my $pack = $_[0]) =~ s e::e/egg;
      require "$pack.pm";
     };
}

                              !()__END__()!

=head1 NAME

CSS::DOM::Value - CSSValue class for CSS::DOM

=head1 VERSION

Version 0.16

=head1 SYNOPSIS

  # ...

=head1 DESCRIPTION

This module implements objects that represent CSS property values. It
implements the DOM CSSValue interface.

This class is used only for custom values (neither primitive values nor
lists) and the special 'inherit' value.

=head1 METHODS

=head2 Object Methods

=over 4

=item cssText

Returns a string representation of the attribute. Pass an argument to set 
it.

=item cssValueType

Returns one of the constants below.

=back

=head2 Constructor

You probably don't need to call this, but here it is anyway:

  $val = new CSS::DOM::Value %arguments;

The hash-style C<%arguments> are as follows:

=over

=item type

C<CSS_INHERIT> or C<CSS_CUSTOM>

=item css

A string of CSS code. This is
only used when C<TYPE> is C<CSS_CUSTOM>.

=item owner

The style object that owns this value; if this is omitted, then the value
is read-only. The value object holds a weak reference to the owner.

=item property

The name of the CSS property to which this value belongs. C<cssText> uses
this to determine how to parse text passed to it.

=back

=head1 CONSTANTS

The following constants can be imported with C<use CSS::DOM::Value ':all'>.
They represent the type of CSS value.

=over

=item CSS_INHERIT (0)

=item CSS_PRIMITIVE_VALUE (1)

=item CSS_VALUE_LIST (2)

=item CSS_CUSTOM (3)

=back

=head1 SEE ALSO

L<CSS::DOM>

L<CSS::DOM::Value::Primitive>

L<CSS::DOM::Value::List>

L<CSS::DOM::Style>
