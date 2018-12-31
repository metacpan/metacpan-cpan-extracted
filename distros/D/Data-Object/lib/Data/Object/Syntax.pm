# ABSTRACT: Object Syntax DSL for Perl 5
package Data::Object::Syntax;

use strict;
use warnings;

use 5.014;

use Data::Object;
use Scalar::Util;
use Sub::Quote;

use parent 'Exporter';

our $VERSION = '0.61'; # VERSION

our @EXPORT = qw(
  alt
  builder
  clearer
  coerce
  def
  default
  defaulter
  handles
  init_arg
  is
  isa
  lazy
  opt
  optional
  predicate
  reader
  req
  required
  ro
  rw
  trigger
  weak_ref
  writer
);

sub import {

  my $class  = $_[0];
  my $target = caller;

  if (my $orig = $target->can('has')) {
    no strict 'refs';
    no warnings 'redefine';

    my $has = *{"${target}::has"} = sub {
      my ($name, @props) = @_;

      return $orig->($name, @props) if @props % 2 != 0;

      my $alt = $name =~ s/^\+//;

      my %codes = (
        builder   => 'build',
        clearer   => 'clear',
        predicate => 'has',
        reader    => 'get',
        trigger   => 'trigger',
        writer    => 'set',
      );

      my %props = @props;
      for my $code (sort keys %codes) {
        if ($props{$code} and $props{$code} eq "1") {
          my $id = $codes{$code};
          $props{$code} = "_${id}_${name}";
          $props{$code} =~ s/_${id}__/_${id}_/;
        }
      }

      if (my $method = delete $props{defaulter}) {
        if ($method eq "1") {
          $method = "_default_${name}";
          $method =~ s/_default__/_default_/;
        }
        my $routine = q{ $target->$method(@_) };
        $props{default} = Sub::Quote::quote_sub($routine,
          {'$target' => \$target, '$method' => \$method,});
      }

      return $orig->($alt ? "+$name" : $name, %props);
    };
  }

  return $class->export_to_level(1, @_);

}

sub alt ($@) {

  my ($name, @props) = @_;
  if (my $has = caller->can('has')) {
    my @name = ref $name ? @$name : $name;
    @_ = ((map "+$_", @name), @props) and goto $has;
  }

}

sub builder (;$) {

  return builder => $_[0] // 1;

}

sub clearer (;$) {

  return clearer => $_[0] // 1;

}

sub coerce () {

  return coerce => 1;

}

sub def ($$@) {

  my ($name, $code, @props) = @_;
  @_ = ($name, 'default', $code, @props) and goto &alt;

}

sub default ($) {

  return default => $_[0];

}

sub defaulter (;$) {

  return defaulter => $_[0] // 1;

}

sub handles ($) {

  return handles => $_[0];

}

sub init_arg ($) {

  return init_arg => $_[0];

}

sub is (@) {

  return (@_);

}

sub isa ($) {

  return isa => $_[0];

}

sub lazy () {

  return lazy => 1;

}

sub opt ($;$@) {

  my ($name, $type, @props) = @_;
  my @req = (required => 0);
  @_ = ($name, ref($type) ? isa($type) : (), @props, @req) and goto &alt;

}

sub optional (@) {

  return required => 0, @_;

}

sub predicate (;$) {

  return predicate => $_[0] // 1;

}

sub reader (;$) {

  return reader => $_[0] // 1;

}

sub req ($;$@) {

  my ($name, $type, @props) = @_;
  my @req = (required => 1);
  @_ = ($name, ref($type) ? isa($type) : (), @props, @req) and goto &alt;

}

sub required (@) {

  return required => 1, @_;

}

sub ro () {

  return is => 'ro';

}

sub rw () {

  return is => 'rw';

}

sub trigger (;$) {

  return trigger => $_[0] // 1;

}

sub weak_ref () {

  return weak_ref => 1;

}

sub writer (;$) {

  return writer => $_[0] // 1;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Syntax - Object Syntax DSL for Perl 5

=head1 VERSION

version 0.61

=head1 SYNOPSIS

  use Data::Object::Syntax;

=head1 DESCRIPTION

Data::Object::Class::Syntax exports a collection of functions that provide a
DSL (syntactic sugar) for declaring and describing Data::Object::Class classes.
This package is used as a template for L<Data::Object::Class::Syntax> and
L<Data::Object::Role::Syntax>. It is highly recommended that you also use the
L<namespace::autoclean> library to automatically cleanup the functions exported
by this library and avoid method name collisions.

=head1 FUNCTIONS

=head2 alt

  alt attr => (is => 'ro');

  # equivalent to

  has '+attr' => (..., is => 'ro');

The alt function alters the preexisting attribute definition for the attribute
specified.

=head2 builder

  builder;
  builder '_build_attr';

  # equivalent to

  has attr => ..., builder => '_build_attr';

The builder function returns a list suitable for configuring the builder
portion of the attribute declaration.

=head2 clearer

  clearer;
  clearer '_clear_attr';

  # equivalent to

  has attr => ..., clearer => '_clean_attr';

The clearer function returns a list suitable for configuring the clearer
portion of the attribute declaration.

=head2 coerce

  coerce;

  # equivalent to

  has attr => ..., coerce => 1;

The coerce function return a list suitable for configuring the coerce portion
of the attribute declaration.

=head2 def

  def attr => sub { 1 };

  # equivalent to

  has '+attr' => (..., default => sub { 1 });

The def function alters the preexisting attribute definition setting and/or
overriding the default value property.

=head2 default

  default sub { ... };

  # equivalent to

  has attr => ..., default => sub { ... };

The default function returns a list suitable for configuring the default
portion of the attribute declaration.

=head2 defaulter

  defaulter;
  defaulter '_default_attr';

  # equivalent to

  has attr => ..., default => sub { $class->_default_attr(...) };

The defaulter function returns a list suitable for configuring the default
portion of the attribute declaration. The argument must be the name of an
existing routine available to the class.

=head2 handles

  handles { ... };

  # equivalent to

  has attr => ..., handles => { ... };

The handles function returns a list suitable for configuring the handles
portion of the attribute declaration.

=head2 init_arg

  init_arg;
  init_arg 'altattr';

  # equivalent to

  has attr => ..., init_arg => 'altattr';

The init_arg function returns a list suitable for configuring the init_arg
portion of the attribute declaration.

=head2 is

  is;

The is function returns a list from a list, and acts merely as a pass-through,
for the purpose of being a visual/descriptive aid.

=head2 isa

  isa sub { ... };

  # equivalent to

  has attr => ..., isa => sub { ... };

The isa function returns a list suitable for configuring the isa portion of the
attribute declaration.

=head2 lazy

  lazy;

  # equivalent to

  has attr => ..., lazy => 1;

The lazy function returns a list suitable for configuring the lazy portion of
the attribute declaration.

=head2 opt

  opt attr => sub { ... };

  # equivalent to

  has '+attr' => ..., required => 0, isa => sub { ... };

The opt function alters the preexisting attribute definition for the attribute
specified using a list suitable for configuring the required and isa portions
of the attribute declaration.

=head2 optional

  optional;

  # equivalent to

  has attr => ..., required => 0;

The optional function returns a list suitable for configuring the required
portion of the attribute declaration.

=head2 predicate

  predicate;
  predicate '_has_attr';

  # equivalent to

  has attr => ..., predicate => '_has_attr';

The predicate function returns a list suitable for configuring the predicate
portion of the attribute declaration.

=head2 reader

  reader;
  reader '_get_attr';

  # equivalent to

  has attr => ..., reader => '_get_attr';

The reader function returns a list suitable for configuring the reader portion
of the attribute declaration.

=head2 req

  req attr => sub { ... };

  # equivalent to

  has '+attr' => ..., required => 1, isa => sub { ... };

The req function alters the preexisting attribute definition for the attribute
specified using a list suitable for configuring the required and isa portions
of the attribute declaration.

=head2 required

  required;

  # equivalent to

  has attr => ..., required => 1;

The required function returns a list suitable for configuring the required
portion of the attribute declaration.

=head2 ro

  ro;

  # equivalent to

  has attr => ..., is => 'ro';

The ro function returns a list suitable for configuring the is portion of the
attribute declaration.

=head2 rw

  rw;

  # equivalent to

  has attr => ..., is => 'rw';

The rw function returns a list suitable for configuring the rw portion of the
attribute declaration.

=head2 trigger

  trigger;
  trigger '_trigger_attr';

  # equivalent to

  has attr => ..., trigger => '_trigger_attr';

The trigger function returns a list suitable for configuring the trigger
portion of the attribute declaration.

=head2 weak_ref

  weak_ref;

  # equivalent to

  has attr => ..., weak_ref => 1;

The weak_ref function returns a list suitable for configuring the weak_ref
portion of the attribute declaration.

=head2 writer

  writer;
  writer '_set_attr';

  # equivalent to

  has attr => ..., writer => '_set_attr';

The writer function returns a list suitable for configuring the writer portion
of the attribute declaration.

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

=cut

=head1 AUTHOR

Al Newkirk <al@iamalnewkirk.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
