package DBIx::Class::DeploymentHandler::VersionStorage::Deprecated::VersionResult;
$DBIx::Class::DeploymentHandler::VersionStorage::Deprecated::VersionResult::VERSION = '0.002234';
# ABSTRACT: (DEPRECATED) The old way to store versions in the database

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->table('dbix_class_schema_versions');

__PACKAGE__->add_columns (
   version => {
      data_type         => 'VARCHAR',
      is_nullable       => 0,
      size              => '10'
   },
   installed => {
      data_type         => 'VARCHAR',
      is_nullable       => 0,
      size              => '20'
   },
);

__PACKAGE__->set_primary_key('version');

__PACKAGE__->resultset_class('DBIx::Class::DeploymentHandler::VersionStorage::Deprecated::VersionResultSet');

1;

# vim: ts=2 sw=2 expandtab

__END__

=pod

=head1 NAME

DBIx::Class::DeploymentHandler::VersionStorage::Deprecated::VersionResult - (DEPRECATED) The old way to store versions in the database

=head1 DEPRECATED

This component has been suplanted by
L<DBIx::Class::DeploymentHandler::VersionStorage::Standard::VersionResult>.
In the next major version (1) we will begin issuing a warning on it's use.
In the major version after that (2) we will remove it entirely.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
