package DBIx::Class::DeploymentHandler::VersionStorage::Standard::VersionResultSet;
$DBIx::Class::DeploymentHandler::VersionStorage::Standard::VersionResultSet::VERSION = '0.002234';
# ABSTRACT: Predefined searches to find what you want from the version storage

use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

use Try::Tiny;

sub version_storage_is_installed {
  my $self = shift;
  try { $self->count; 1 } catch { undef }
}

sub database_version {
  my $self = shift;
  $self->search(undef, {
    order_by => { -desc => 'id' },
    rows => 1
  })->get_column('version')->next;
}

1;

# vim: ts=2 sw=2 expandtab

__END__

=pod

=head1 NAME

DBIx::Class::DeploymentHandler::VersionStorage::Standard::VersionResultSet - Predefined searches to find what you want from the version storage

=head1 METHODS

=head2 version_storage_is_installed

True if (!!!) the version storage has been installed

=head2 database_version

The version of the database

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
