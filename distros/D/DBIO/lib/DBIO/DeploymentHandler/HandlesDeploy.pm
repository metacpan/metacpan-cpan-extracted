package DBIO::DeploymentHandler::HandlesDeploy;
# ABSTRACT: Interface for deploy methods

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Exception;

use namespace::clean;


my @REQUIRED = qw(
  prepare_deploy
  deploy
  prepare_resultsource_install
  install_resultsource
  prepare_upgrade
  txn_do
  upgrade
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

DBIO::DeploymentHandler::HandlesDeploy - Interface for deploy methods

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Interface contract for a C<deploy_method> collaborator, as consumed by the
native L<DBIO::DeploymentHandler>. A conforming deploy method MUST implement:

  prepare_deploy
  deploy
  prepare_resultsource_install
  install_resultsource
  prepare_upgrade
  txn_do
  upgrade

This is the B<native> contract -- exactly the methods the native handler
invokes on its deploy method. It is intentionally narrower than the upstream
L<DBIx::Class::DeploymentHandler> deploy-method contract:

=over 4

=item *

C<upgrade_single_step>, C<prepare_downgrade>, and C<downgrade_single_step>
belonged to the old loop-based L<DBIO::DeploymentHandler::Dad> contract, which
walked discrete version transitions. The native handler overrides C<upgrade>
with a single-shot driver reconcile and throws on C<downgrade>, so it never
calls those three -- they are deliberately B<not> part of this interface. (See
F<t/deployment_handler.t>, which asserts their removal.)

=item *

C<initialize> is B<not> required. The native handler never calls it;
L<DBIO::DeploymentHandler::DeployMethod::Native> still provides it as a no-op
for legacy C<Dad> compatibility, but a conforming deploy method does not have
to.

=back

=head1 METHODS

=head2 assert_implemented

  DBIO::DeploymentHandler::HandlesDeploy->assert_implemented($deploy_method);

Class method. Verifies that C<$target> (a deploy-method object or class)
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
