package DBIO::DeploymentHandler::HandlesDeploy;
# ABSTRACT: Interface for deploy methods

use strict;
use warnings;

# This is an interface role - implementing classes must provide:
#   initialize
#   prepare_deploy, deploy
#   prepare_resultsource_install, install_resultsource
#   prepare_upgrade, upgrade_single_step
#   prepare_downgrade, downgrade_single_step
#   txn_do

1;

# vim: ts=2 sw=2 expandtab

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DeploymentHandler::HandlesDeploy - Interface for deploy methods

=head1 VERSION

version 0.900000

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
