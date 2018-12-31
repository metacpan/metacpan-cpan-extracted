# ABSTRACT: Output Object Role for Perl 5
package Data::Object::Role::Output;

use strict;
use warnings;

use 5.014;

use Data::Object;
use Data::Object::Role;
use Data::Object::Library;
use Data::Object::Signatures;
use Scalar::Util;

map with($_), our @ROLES = qw(
  Data::Object::Role::Dumper
);

our $VERSION = '0.61'; # VERSION

method print () {

  my @result = Data::Object::Role::Dumper::dump($self);

  return CORE::print(@result);

}

method say () {

  my @result = Data::Object::Role::Dumper::dump($self);

  return CORE::print(@result, "\n");

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Role::Output - Output Object Role for Perl 5

=head1 VERSION

version 0.61

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Role::Output';

=head1 DESCRIPTION

Data::Object::Role::Output provides routines for operating on Perl 5 data
objects which meet the criteria for being output.

=head1 METHODS

=head2 print

  # given $output

  $output->print;

The print method outputs the value represented by the object to STDOUT and
returns true. This method returns a number value.

=head2 say

  # given $output

  $output->say;

The say method outputs the value represented by the object appended with a
newline to STDOUT and returns true. This method returns a L<Data::Object::Number>
object.

=head1 ROLES

This package is comprised of the following roles.

=over 4

=item *

L<Data::Object::Role::Dumper>

=back

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
