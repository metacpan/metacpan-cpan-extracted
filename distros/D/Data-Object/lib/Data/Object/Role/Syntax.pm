# ABSTRACT: Role Declaration DSL for Perl 5
package Data::Object::Role::Syntax;

use strict;
use warnings;

use 5.014;

use Data::Object;
use Data::Object::Syntax;
use Scalar::Util;

use parent 'Exporter';

our $VERSION = '0.59'; # VERSION

our @EXPORT = @Data::Object::Syntax::EXPORT;

*import = *Data::Object::Syntax::import;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Role::Syntax - Role Declaration DSL for Perl 5

=head1 VERSION

version 0.59

=head1 SYNOPSIS

    package Persona;

    use namespace::autoclean -except => 'has';

    use Data::Object::Role;
    use Data::Object::Role::Syntax;
    use Data::Object::Library ':types';

   # ATTRIBUTES

    has firstname  => ro;
    has lastname   => ro;
    has address1   => rw;
    has address2   => rw;
    has city       => rw;
    has state      => rw;
    has zip        => rw;
    has telephone  => rw;
    has occupation => rw;

    # CONSTRAINTS

    req firstname  => Str;
    req lastname   => Str;
    req address1   => Str;
    opt address2   => Str;
    req city       => Str;
    req state      => StrMatch[qr/^[A-Z]{2}$/];
    req zip        => Int;
    opt telephone  => StrMatch[qr/^\d{10,30}$/];
    opt occupation => Str;

    # DEFAULTS

    def occupation => 'Unassigned';
    def city       => 'San Franscisco';
    def state      => 'CA';

    1;

=head1 DESCRIPTION

Data::Object::Role::Syntax exports a collection of functions that provide a DSL
(syntactic sugar) for declaring and describing Data::Object::Role roles. It is
highly recommended that you also use the L<namespace::autoclean> library to
automatically cleanup the functions exported by this library and avoid method
name collisions.

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

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
