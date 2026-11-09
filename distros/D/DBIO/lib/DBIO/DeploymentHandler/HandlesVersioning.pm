package DBIO::DeploymentHandler::HandlesVersioning;
# ABSTRACT: Interface for version methods

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Exception;

use namespace::clean;


my @REQUIRED = qw(
  next_version_set
  previous_version_set
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

DBIO::DeploymentHandler::HandlesVersioning - Interface for version methods

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Interface contract for a C<version_handler> collaborator, as consumed by the
native L<DBIO::DeploymentHandler>. A conforming version handler MUST implement:

  next_version_set
  previous_version_set

=head1 METHODS

=head2 assert_implemented

  DBIO::DeploymentHandler::HandlesVersioning->assert_implemented($version_handler);

Class method. Verifies that C<$target> (a version-handler object or class)
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
