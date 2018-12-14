# ABSTRACT: Signatures Object for Perl 5
package Data::Object::Signatures;

use strict;
use warnings;

use 5.014;

use Data::Object;
use Data::Object::Library;
use Scalar::Util;

use parent 'Type::Tiny::Signatures';

our @DEFAULTS = @Type::Tiny::Signatures::DEFAULTS = 'Data::Object::Library';

our $VERSION = '0.60'; # VERSION

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Signatures - Signatures Object for Perl 5

=head1 VERSION

version 0.60

=head1 SYNOPSIS

  use Data::Object::Signatures;

  method hello (Str $name) {

    say "Hello $name, how are you?";

  }

=head1 DESCRIPTION

Data::Object::Signatures is a subclass of L<Type::Tiny::Signatures> providing
method and function signatures supporting all the type constraints provided by
L<Data::Object::Library>.

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
