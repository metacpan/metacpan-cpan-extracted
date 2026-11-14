package DBIO::DeploymentHandler::HandlesVersionStorage;
# ABSTRACT: Interface for version storage methods

use strict;
use warnings;

our $VERSION = '0.900005';

use DBIO::Exception;

use namespace::clean;


my @REQUIRED = qw(
  add_database_version
  database_version
  delete_database_version
  version_storage_is_installed
);

sub assert_implemented {
  my ($class, $target) = @_;

  DBIO::Exception->throw(
    "$class->assert_implemented called without a target object"
  ) unless defined $target;

  my @missing = grep { !$target->can($_) } @REQUIRED;

  return 1 unless @missing;

  DBIO::Exception->throw(
    (ref($target) || $target)
    . " does not implement the $class interface: missing method(s) "
    . join(', ', @missing)
  );
}

1;

# vim: ts=2 sw=2 expandtab

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DeploymentHandler::HandlesVersionStorage - Interface for version storage methods

=head1 VERSION

version 0.900005

=head1 DESCRIPTION

Interface contract for a C<version_storage> collaborator, as consumed by the
native L<DBIO::DeploymentHandler>. A conforming version storage MUST implement:

  add_database_version
  database_version
  delete_database_version
  version_storage_is_installed

=head1 METHODS

=head2 assert_implemented

  DBIO::DeploymentHandler::HandlesVersionStorage->assert_implemented($version_storage);

Class method. Verifies that C<$target> (a version-storage object or class)
C<can> every required method. Throws a L<DBIO::Exception> naming B<all>
missing methods, the target class, and this interface when the contract is
not satisfied. Returns true otherwise.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
