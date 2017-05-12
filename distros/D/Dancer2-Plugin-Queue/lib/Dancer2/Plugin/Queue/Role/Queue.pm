use 5.008001;
use strict;
use warnings;

package Dancer2::Plugin::Queue::Role::Queue;
# ABSTRACT: Dancer2::Plugin::Queue implementation API

our $VERSION = '0.006';

use Moo::Role;

requires 'add_msg';

requires 'get_msg';

requires 'remove_msg';

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::Queue::Role::Queue - Dancer2::Plugin::Queue implementation API

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  package Dancer2::Plugin::Queue::Array;

  use Moo;
  with 'Dancer2::Plugin::Queue::Role::Queue';

  sub add_msg { ... }

  sub get_msg { ... }

  sub remove_msg { ... }

  1;

=head1 DESCRIPTION

This module describes the interface role of L<Dancer2::Plugin::Queue>.  Backend
implementations must provide the C<add_msg>, C<get_msg> and C<remove_msg>
methods.

=for Pod::Coverage method_names_here

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
