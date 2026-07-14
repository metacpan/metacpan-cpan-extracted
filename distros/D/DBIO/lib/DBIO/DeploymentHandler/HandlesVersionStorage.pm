package DBIO::DeploymentHandler::HandlesVersionStorage;
# ABSTRACT: Interface for version storage methods

use strict;
use warnings;

# This is an interface - implementing classes must provide:
#   add_database_version
#   database_version
#   delete_database_version
#   version_storage_is_installed

1;

# vim: ts=2 sw=2 expandtab

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DeploymentHandler::HandlesVersionStorage - Interface for version storage methods

=head1 VERSION

version 0.900002

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
