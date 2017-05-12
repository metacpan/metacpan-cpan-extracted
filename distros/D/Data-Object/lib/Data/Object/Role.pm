# ABSTRACT: Role Declaration for Perl 5
package Data::Object::Role;

use strict;
use warnings;

use 5.014;

use Data::Object;
use Scalar::Util;

use parent 'Moo::Role';

our $VERSION = '0.59'; # VERSION

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Role - Role Declaration for Perl 5

=head1 VERSION

version 0.59

=head1 SYNOPSIS

    package Persona;

    use Data::Object::Role;

    extends 'Entity';
    with    'Identity';

    has id => ( is => 'ro' );

    1;

=head1 DESCRIPTION

Data::Object::Role inherits all methods and behaviour from L<Moo::Role>. Please
see that documentation for more usage information. Additionally, see
L<Data::Object::Role::Syntax> which provides a DSL that makes declaring roles
easier and more fun.

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
