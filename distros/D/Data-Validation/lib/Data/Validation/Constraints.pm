package Data::Validation::Constraints;

use namespace::autoclean;
use charnames qw( :full );

use Data::Validation::Constants qw( EXCEPTION_CLASS FALSE HASH TRUE );
use Data::Validation::Utils     qw( ensure_class_loaded load_class throw );
use List::Util                  qw( any );
use Scalar::Util                qw( looks_like_number );
use Try::Tiny;
use Unexpected::Functions       qw( KnownType );
use Unexpected::Types           qw( Any ArrayRef Bool Int Object Str Undef );
use Moo;

# Public attributes
has 'allowed'        => is => 'ro',   iss => ArrayRef, builder => sub { [] };

has 'max_length'     => is => 'ro',   isa => Int;

has 'max_value'      => is => 'ro',   isa => Int;

has 'method'         => is => 'ro',   isa => Str, required => TRUE;

has 'min_length'     => is => 'ro',   isa => Int;

has 'min_value'      => is => 'ro',   isa => Int;

has 'pattern'        => is => 'ro',   isa => Str;

has 'required'       => is => 'ro',   isa => Bool, default => FALSE;

has 'type'           => is => 'ro',   isa => Str | Undef;

has 'type_libraries' => is => 'ro',   isa => ArrayRef[Str],
   builder           => sub { [ 'Unexpected::Types' ] };

has 'type_registry'  => is => 'lazy', isa => Object, builder => sub {
   my $self = shift; ensure_class_loaded 'Type::Registry';
   my $reg  = Type::Registry->for_me;

   $reg->add_types( $_ ) for (@{ $self->type_libraries });

   return $reg;
};

has 'value'          => is => 'ro',   isa => Any;

# Public methods
sub new_from_method {
   my ($class, $attr) = @_;

   $class->can( $attr->{method} ) and return $class->new( $attr );

   return (load_class $class, 'isValid', $attr->{method})->new( $attr );
}

sub validate {
   my ($self, $v) = @_; my $method = $self->method; return $self->$method( $v );
}

around 'validate' => sub {
   my ($orig, $self, $v) = @_;

   not defined $v and $self->required and return FALSE;

   not defined $v and not $self->required and $self->method ne 'isMandatory'
      and return TRUE;

   return $orig->( $self, $v );
};

# Builtin factory validation methods
sub isAllowed {
   my ($self, $v) = @_;

   return (any { $_ eq $v } @{ $self->allowed }) ? TRUE : FALSE;
}

sub isBetweenValues {
   my ($self, $v) = @_;

   defined $self->min_value and $v < $self->min_value and return FALSE;
   defined $self->max_value and $v > $self->max_value and return FALSE;
   return TRUE;
}

sub isEqualTo {
   my ($self, $v) = @_;

   $self->isValidNumber( $v ) and $self->isValidNumber( $self->value )
      and return $v == $self->value ? TRUE : FALSE;

   return $v eq $self->value ? TRUE : FALSE;
}

sub isHexadecimal {
   my ($self, $v) = @_;

   my $pat = '\A (?:(?i)(?:[-+]?)(?:(?=[.]?[0123456789ABCDEF])'
           . '(?:[0123456789ABCDEF]*)(?:(?:[.])(?:[0123456789ABCDEF]{0,}))?)'
           . '(?:(?:[G])(?:(?:[-+]?)(?:[0123456789ABCDEF]+))|)) \z';

   return $self->isMatchingRegex( $v, $pat );
}

sub isMandatory {
   return defined $_[ 1 ] && length $_[ 1 ] ? TRUE : FALSE;
}

sub isMatchingRegex {
   my ($self, $v, $pat) = @_;

   $pat //= $self->pattern; defined $pat or return FALSE;

   return $v =~ m{ $pat }msx ? TRUE : FALSE;
}

sub isMatchingType {
   my ($self, $v, $type_name) = @_; my $type;

   $type_name //= $self->type; defined $type_name or return FALSE;

   try   { $type = $self->type_registry->lookup( $type_name ) }
   catch {
      $_ =~ m{ \Qnot a known type constraint\E }mx
         and throw KnownType, [ $type_name ];
      throw "${_}"; # uncoverable statement
   };

   return $type->check( $v ) ? TRUE : FALSE;
}

sub isPrintable {
   return $_[ 0 ]->isMatchingRegex( $_[ 1 ], '\A \p{IsPrint}+ \z' );
}

sub isSimpleText {
   return $_[ 0 ]->isMatchingRegex( $_[ 1 ], '\A [a-zA-Z0-9_ \-\.]+ \z' );
}

sub isValidHostname {
   return (gethostbyname $_[ 1 ])[ 0 ] ? TRUE : FALSE;
}

sub isValidIdentifier {
   return $_[ 0 ]->isMatchingRegex( $_[ 1 ], '\A [a-zA-Z_] \w* \z' );
}

sub isValidInteger {
   my ($self, $v) = @_;

   my $pat = '\A (?:(?:[-+]?)(?:[0123456789]{1,3}(?:[_]?[0123456789]{3})*)) \z';

   $self->isMatchingRegex( $v, $pat ) or return FALSE;
   int $v == $v or return FALSE;
   return TRUE;
}

sub isValidLength {
   my ($self, $v) = @_;

   defined $self->min_length and length $v < $self->min_length and return FALSE;
   defined $self->max_length and length $v > $self->max_length and return FALSE;
   return TRUE;
}

sub isValidNumber {
   my ($self, $v) = @_; return looks_like_number( $v ) ? TRUE : FALSE;
}

sub isValidText {
   return $_[ 0 ]->isMatchingRegex( $_[ 1 ],
          '\A [\t\n !\"#%&\'\(\)\*\+\,\-\./0-9:;=\?@A-Z\[\]_a-z\|\~]+ \z' );
}

sub isValidTime {
   my ($self, $v) = @_; my $pat = '\A (\d\d ): (\d\d) (?: : (\d\d) )? \z';

   $self->isMatchingRegex( $v, $pat ) or return FALSE;

   my ($hours, $minutes, $seconds) = $v =~ m{ $pat }msx;

   ($hours   >= 0 and $hours   <= 23) or return FALSE;
   ($minutes >= 0 and $minutes <= 59) or return FALSE;

   defined $seconds or return TRUE;

   return ($seconds >= 0 && $seconds <= 59) ? TRUE : FALSE;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Data::Validation::Constraints - Test data values for conformance with constraints

=head1 Synopsis

   use Data::Validation::Constraints;

   %config = ( method => $method, %{ $self->constraints->{ $id } || {} } );

   $constraint_ref = Data::Validation::Constraints->new_from_method( %config );

   $bool = $constraint_ref->validate( $value );

=head1 Description

Tests a single data value for conformance with a constraint

=head1 Configuration and Environment

Defines the following attributes:

=over 3

=item C<allowed>

An array reference of permitted values used by L</isAllowed>

=item C<max_length>

Used by L</isValidLength>. The I<length> of the supplied value must be
numerically less than this

=item C<max_value>

Used by L</isBetweenValues>.

=item C<method>

Name of the constraint to apply. Required

=item C<min_length>

Used by L</isValidLength>.

=item C<min_value>

Used by L</isBetweenValues>.

=item C<pattern>

Used by L</isMathchingRegex> as the pattern to match the supplied value
against

=item C<required>

If true then undefined values are not allowed regardless of what other
validation would be done

=item C<type>

If C<isMatchingType> matches against this value

=item C<type_libraries>

A list of type libraries to add to the registry. Defaults to;
L<Unexpected::Types>

=item C<type_registry>

Lazily evaluated instance of L<Type::Registry> to which the C<type_libraries>
have been added

=item C<value>

Used by the L</isEqualTo> method as the other value in the comparison

=back

=head1 Subroutines/Methods

=head2 new_from_method

A class method which implements a factory pattern using the C<method> attribute
to select the subclass

=head2 validate

Called by L<Data::Validation>::check_field this method implements
tests for a null input value so that individual validation methods
don't have to. It calls either a built in validation method or
C<validate> which should have been overridden in a factory
subclass. An exception is thrown if the data value is not acceptable

=head2 isAllowed

Is the the value in the C<< $self->allowed >> list of values

=head2 isBetweenValues

Test to see if the supplied value is numerically greater than
C<< $self->min_value >> and less than C<< $self->max_value >>

=head2 isEqualTo

Test to see if the supplied value is equal to C<< $self->value >>. Calls
C<isValidNumber> on both values to determine the type of comparison
to perform

=head2 isHexadecimal

Tests to see if the value matches the regular expression for a hexadecimal
number

=head2 isMandatory

Undefined and null values are not allowed

=head2 isMatchingRegex

Does the supplied value match the pattern? The pattern defaults to
C<< $self->pattern >>

=head2 isMatchingType

Does the supplied value pass the type constraint check? The constraint
defaults to C<< $self->type >>

=head2 isPrintable

Is the supplied value entirely composed of printable characters?

=head2 isSimpleText

Simple text is defined as matching the pattern '\A [a-zA-Z0-9_ \-\.]+ \z'

=head2 isValidHostname

Calls C<gethostbyname> on the supplied value

=head2 isValidIdentifier

Identifiers must match the pattern '\A [a-zA-Z_] \w* \z'

=head2 isValidInteger

Tests to see if the supplied value is an integer

=head2 isValidLength

Tests to see if the length of the supplied value is greater than
C<< $self->min_length >> and less than C<< $self->max_length >>

=head2 isValidNumber

Return true if the supplied value C<looks_like_number>

=head2 isValidText

Text is defined as any string matching the pattern
'\A [ !%&\(\)\*\+\,\-\./0-9:;=\?@A-Z\[\]_a-z\|\~]+ \z'

=head2 isValidTime

Matches against a the pattern '\A \d\d : \d\d (?: : \d\d )? \z'

=head1 External Constraints

Each of these constraint subclasses implements the required C<validate>
method

=head2 Date

If the C<str2time> method in the L<Class::Usul::Time>
module can parse the supplied value then it is deemed to be a valid
date

=head2 Email

If the C<address> method in the L<Email::Valid> module can parse the
supplied value then it is deemed to be a valid email address

=head2 Password

Currently implements a minimum password length of six characters and
that the password contain at least one non alphabetic character

=head2 Path

Screen out these characters: ; & * { } and space

=head2 Postcode

Tests to see if the supplied value matches one of the approved
patterns for a valid postcode

=head2 URL

Call the C<request> method in L<HTTP::Tiny> to test if a URL is accessible

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<charnames>

=item L<Moo>

=item L<Unexpected>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There is no POD coverage test because the subclasses docs are in here instead

The L<Data::Validation::Constraints::Date> module requires the module
L<Class::Usul::Time> and this is not listed as prerequisite as it
would create a circular dependency

Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2016 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
