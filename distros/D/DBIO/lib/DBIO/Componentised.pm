package DBIO::Componentised;
# ABSTRACT: Component loading and management for DBIO

use strict;
use warnings;

our $VERSION = '0.900005';

use base 'Class::C3::Componentised';
use mro 'c3';

use DBIO::Util ();


sub ensure_class_loaded {
  my ($class, $name) = @_;
  DBIO::Util::assert_class_name($name);
  return $class->next::method($name);
}


sub load_optional_class {
  my ($class, $name) = @_;
  DBIO::Util::assert_class_name($name);
  return $class->next::method($name);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Componentised - Component loading and management for DBIO

=head1 VERSION

version 0.900005

=head1 METHODS

=head2 ensure_class_loaded

  $class->ensure_class_loaded($name);

Loads C<$name> unless it is loaded already. C<$name> is a class name -- Perl
identifiers joined by C<::> -- or the call throws C<'...' is not a class name>
(L<DBIO::Util/assert_class_name>). Components given as C<+Foo::Bar> are
resolved to C<Foo::Bar> by C<load_components> before they get here.

=head2 load_optional_class

  $class->load_optional_class($name);

As L</ensure_class_loaded> for the name: it must be a class name. A class
that is not installed answers false.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
