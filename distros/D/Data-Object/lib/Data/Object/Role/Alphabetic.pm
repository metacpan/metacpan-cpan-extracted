# ABSTRACT: Alphabetic Object Role for Perl 5
package Data::Object::Role::Alphabetic;

use strict;
use warnings;

use 5.014;

use Data::Object;
use Data::Object::Role;
use Data::Object::Library;
use Data::Object::Signatures;
use Scalar::Util;

our $VERSION = '0.60'; # VERSION

method eq ($arg1) {

  return "$self" eq "$arg1" ? 1 : 0;

}

method gt ($arg1) {

  return "$self" gt "$arg1" ? 1 : 0;

}

method ge ($arg1) {

  return "$self" ge "$arg1" ? 1 : 0;

}

method lt ($arg1) {

  return "$self" lt "$arg1" ? 1 : 0;

}

method le ($arg1) {

  return "$self" le "$arg1" ? 1 : 0;

}

method ne ($arg1) {

  return "$self" ne "$arg1" ? 1 : 0;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Role::Alphabetic - Alphabetic Object Role for Perl 5

=head1 VERSION

version 0.60

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Role::Alphabetic';

=head1 DESCRIPTION

Data::Object::Role::Alphabetic provides routines for operating on Perl 5
alpha-numeric data.

=head1 METHODS

=head2 eq

  # given 'exciting'

  $alphabetic->eq('Exciting'); # 0

The eq method returns true if the argument provided is equal to the value
represented by the object. This method returns a number value.

=head2 ge

  # given 'exciting'

  $alphabetic->ge('Exciting'); # 1

The ge method returns true if the argument provided is greater-than or equal-to
the value represented by the object. This method returns a Data::Object::Number
object.

=head2 gt

  # given 'exciting'

  $alphabetic->gt('Exciting'); # 1

The gt method returns true if the argument provided is greater-than the value
represented by the object. This method returns a number value.

=head2 le

  # given 'exciting'

  $alphabetic->le('Exciting'); # 0

The le method returns true if the argument provided is less-than or equal-to
the value represented by the object. This method returns a Data::Object::Number
object.

=head2 lt

  # given 'exciting'

  $alphabetic->lt('Exciting'); # 0

The lt method returns true if the argument provided is less-than the value
represented by the object. This method returns a number value.

=head2 ne

  # given 'exciting'

  $alphabetic->ne('Exciting'); # 1

The ne method returns true if the argument provided is not equal to the value
represented by the object. This method returns a number value.

=head1 SEE ALSO

=over 4

=item *

L<Data::Object::Array>

=item *

L<Data::Object::Class>

=item *

L<Data::Object::Class::Syntax>

=item *

L<Data::Object::Code>

=item *

L<Data::Object::Float>

=item *

L<Data::Object::Hash>

=item *

L<Data::Object::Integer>

=item *

L<Data::Object::Number>

=item *

L<Data::Object::Role>

=item *

L<Data::Object::Role::Syntax>

=item *

L<Data::Object::Regexp>

=item *

L<Data::Object::Scalar>

=item *

L<Data::Object::String>

=item *

L<Data::Object::Undef>

=item *

L<Data::Object::Universal>

=item *

L<Data::Object::Autobox>

=item *

L<Data::Object::Immutable>

=item *

L<Data::Object::Library>

=item *

L<Data::Object::Prototype>

=item *

L<Data::Object::Signatures>

=back

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
