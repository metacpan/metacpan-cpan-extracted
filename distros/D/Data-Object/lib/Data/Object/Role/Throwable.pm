# ABSTRACT: Throwable Object Role for Perl 5
package Data::Object::Role::Throwable;

use strict;
use warnings;

use 5.014;

use Data::Object;
use Data::Object::Role;
use Data::Object::Library;
use Data::Object::Signatures;
use Scalar::Util;

our $VERSION = '0.61'; # VERSION

method throw (@args) {

  my $message = (@args % 2 == 1) ? shift : undef;
  my $class   = Data::Object::load('Data::Object::Exception');

  @_ = ($class => (object => $self, message => $message));

  goto $class->can('throw');

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Role::Throwable - Throwable Object Role for Perl 5

=head1 VERSION

version 0.61

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Role::Throwable';

=head1 DESCRIPTION

Data::Object::Role::Throwable provides routines for operating on Perl 5
data objects which meet the criteria for being throwable.

=head1 METHODS

=head2 throw

  # given $throwable

  $throwable->throw;

The throw method terminates the program using the core die keyword, passing the
object to the L<Data::Object::Exception> class as the named parameter C<object>.
If captured this method returns an exception value.

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

Al Newkirk <al@iamalnewkirk.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
