package Data::Validation::Filters;

use namespace::autoclean;

use Data::Validation::Constants qw( EXCEPTION_CLASS HASH TRUE );
use Data::Validation::Utils     qw( load_class );
use Unexpected::Types           qw( Str );
use Moo;

has 'method'  => is => 'ro', isa => Str, required => TRUE;

has 'pattern' => is => 'ro', isa => Str;

has 'replace' => is => 'ro', isa => Str;

sub new_from_method {
   my ($class, $attr) = @_;

   $class->can( $attr->{method} ) and return $class->new( $attr );

   return (load_class $class, 'filter', $attr->{method})->new( $attr );
}

sub filter {
   my ($self, $v) = @_; my $method = $self->method; return $self->$method( $v );
}

around 'filter' => sub {
   my ($orig, $self, $v) = @_; return defined $v ? $orig->( $self, $v ) : undef;
};

# Builtin filter methods
sub filterEscapeHTML {
   my ($self, $v) = @_;

   $v =~ s{ &(?!(amp|lt|gt|quot);) }{&amp;}gmx;
   $v =~ s{ < }{&lt;}gmx;
   $v =~ s{ > }{&gt;}gmx;
   $v =~ s{ \" }{&quot;}gmx;
   return $v;
}

sub filterLowerCase {
   my ($self, $v) = @_; return lc $v;
}

sub filterNonNumeric {
   my ($self, $v) = @_; $v =~ s{ \D+ }{}gmx; return $v;
}

sub filterReplaceRegex {
   my ($self, $v) = @_;

   my $pattern = $self->pattern or return $v;
   my $replace = defined $self->replace ? $self->replace : q();

   $v =~ s{ $pattern }{$replace}gmx;
   return $v;
}

sub filterTitleCase {
   my ($self, $v) = @_; my @words = split ' ', $v, -1;

   return join ' ', map { ucfirst $_ } @words;
}

sub filterTrimBoth {
   my ($self, $v) = @_;

   $v =~ s{ \A \s+ }{}mx; $v =~ s{ \s+ \z }{}mx;
   return $v;
}

sub filterUpperCase {
   my ($self, $v) = @_; return uc $v;
}

sub filterUCFirst {
   my ($self, $v) = @_; return ucfirst $v;
}

sub filterWhiteSpace {
   my ($self, $v) = @_; $v =~ s{ \s+ }{}gmx; return $v;
}

sub filterZeroLength {
   return defined $_[ 1 ] && length $_[ 1 ] ? $_[ 1 ] : undef;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Data::Validation::Filters - Filter data values

=head1 Synopsis

   use Data::Validation::Filters;

   %config = ( method => $method, %{ $self->filters->{ $id } || {} } );

   $filter_ref = Data::Validation::Filters->new_from_method( %config );

   $value = $filter_ref->filter_value( $value );

=head1 Description

Applies a single filter to a data value and returns it's possibly changed
value

=head1 Configuration and Environment

Defines the following attributes:

=over 3

=item C<method>

Name of the constraint to apply. Required

=item C<pattern>

Used by L</isMathchingRegex> as the pattern to match the supplied value
against

=item C<replace>

The replacement value used in regular expression search and replace
operations

=back

=head1 Subroutines/Methods

=head2 C<new_from_method>

A class method which implements a factory pattern using the C<method> attribute
to select the subclass

=head2 C<filter>

Calls either a builtin method or an external one to filter the data value

=head2 C<filterEscapeHTML>

Replaces &<>" with their &xxx; equivalents

=head2 C<filterLowerCase>

Lower cases the data value

=head2 C<filterNonNumeric>

Removes all non numeric characters

=head2 C<filterReplaceRegex>

Matches the regular expression pattern and substitutes the replace string

=head2 C<filterTitleCase>

Like L</filterUCFirst> but applied to every word in the string

=head2 C<filterTrimBoth>

Remove all leading and trailing whitespace

=head2 C<filterUpperCase>

Upper cases the data value

=head2 C<filterUCFirst>

Upper cases the first character of the data value

=head2 C<filterWhiteSpace>

Removes all whitespace

=head2 C<filterZeroLength>

Returns undef if value is zero length

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo>

=item L<Unexpected>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Validation.  Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

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
