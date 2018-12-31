# ABSTRACT: Singleton Object for Perl 5
package Data::Object::Singleton;

use strict;
use warnings;

use 5.014;

use Data::Object;
use Data::Object::Library;
use Data::Object::Signatures;
use Scalar::Util;

use parent 'Moo';

our $VERSION = '0.61'; # VERSION

fun import ($class, @args) {

  my $target = caller;
  my $state  = undef;

  eval "package $target; use Moo; 1;";

  my $new   = $target->can('new');
  my $renew = $target->can('renew');

  no strict 'refs';

  *{"${target}::new"}   = sub { $state = $new->(@_) if !$state; $state };
  *{"${target}::renew"} = sub { $state = $new->(@_) }
    if !$renew;

  return;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Singleton - Singleton Object for Perl 5

=head1 VERSION

version 0.61

=head1 SYNOPSIS

  package Registry;

  use Data::Object::Singleton;

  extends 'Environment';

  1;

=head1 DESCRIPTION

Data::Object::Singleton inherits all methods and behaviour from L<Moo>.
Please see that documentation for more usage information. Additionally, see
L<Data::Object::Class::Syntax> which provides a DSL that makes declaring
classes easier and more fun.

=head1 METHODS

=head2 renew

  Registry->new;   # returns instance
  Registry->new;   # returns instance
  Registry->renew; # returns NEW instance
  Registry->new;   # returns instance

The renew method performs the same function as the C<new> method, returning a
new instance of the class, and makes the new instance a singleton.

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
