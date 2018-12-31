# ABSTRACT: Exception Object for Perl 5
package Data::Object::Exception;

use strict;
use warnings;

use 5.014;

use Data::Object;
use Data::Object::Class;
use Data::Object::Library;
use Data::Object::Signatures;
use Scalar::Util;

use Data::Dumper ();

use overload ('""' => 'data', '~~' => 'data', fallback => 1,);

our $VERSION = '0.61'; # VERSION

has file       => (is => 'ro');
has line       => (is => 'ro');
has message    => (is => 'ro');
has object     => (is => 'ro');
has package    => (is => 'ro');
has subroutine => (is => 'ro');

around BUILDARGS => fun($orig, $self, @args) {

  unshift @args, (ref $args[0] ? 'object' : 'message') if @args == 1;

  return $self->$orig(@args);

};

method catch ($object) {

  my $class = ref $self;

  return UNIVERSAL::isa($object, $class);

}

method data () {

  my $class   = ref $self;
  my $file    = $self->file;
  my $line    = $self->line;
  my $default = $self->message;
  my $object  = $self->object;

  my $objref = overload::StrVal($object) if $object;
  my $message = $default || "An exception ($class) was thrown";
  my @with = join " ", "with", $objref if $objref and not $default;

  return join(" ", $message, @with, "in $file at line $line") . "\n";

}

method dump () {

  local $Data::Dumper::Terse = 1;

  return Data::Dumper::Dumper($self);

}

method throw (Any @args) {

  my $class = ref $self || $self || __PACKAGE__;

  unshift @args, (ref $args[0] ? 'object' : 'message') if @args == 1;

  die $class->new(
    ref $self ? (%$self) : (), @args,
    file       => (caller(0))[1],
    line       => (caller(0))[2],
    package    => (caller(0))[0],
    subroutine => (caller(0))[3],
  );

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Exception - Exception Object for Perl 5

=head1 VERSION

version 0.61

=head1 SYNOPSIS

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new;

  $exception->throw('Something went wrong');

=head1 DESCRIPTION

Data::Object::Exception provides a functionality for creating, throwing,
catching, and introspecting generic exception objects.

=head1 METHODS

=head2 catch

  $exception->catch;

The catch method returns true if the argument is the same type of object as the
invocant.

=head2 data

  # given $exception

  $exception->data; # original value

The data method returns the original and underlying value contained by the
object. This method is an alias to the detract method.

=head2 dump

  $exception->dump;

The dump method returns a stringified version of the exception object.

=head2 throw

  $exception->throw;

The throw method terminates the program using the core die keyword, passing the
exception object as the only argument.

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
