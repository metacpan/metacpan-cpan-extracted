package DBIO::DeploymentHandler::VersionStorage::Standard::VersionResultSet;
# ABSTRACT: The typical way to query versions in the database

use strict;
use warnings;

our $VERSION = '0.900005';

use base 'DBIO::ResultSet';


sub version_storage_is_installed {
  my $self = shift;
  eval { $self->count; 1 } ? 1 : 0;
}


sub database_version {
  my $self = shift;

  $self
    ->search(undef, { order_by => { -desc => 'id' }, rows => 1 })
    ->get_column('version')
    ->next;
}

1;

# vim: ts=2 sw=2 expandtab

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DeploymentHandler::VersionStorage::Standard::VersionResultSet - The typical way to query versions in the database

=head1 VERSION

version 0.900005

=head1 METHODS

=head2 version_storage_is_installed

True if the version table can be counted, i.e. exists in the database.

=head2 database_version

The C<version> of the newest row (highest C<id>), or C<undef> if there is
none.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
