package DBIx::Class::DeploymentHandler::VersionStorage::Standard::VersionResult;
$DBIx::Class::DeploymentHandler::VersionStorage::Standard::VersionResult::VERSION = '0.002220';
# ABSTRACT: The typical way to store versions in the database

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->table('dbix_class_deploymenthandler_versions');

__PACKAGE__->add_columns (
  id => {
    data_type         => 'int',
    is_auto_increment => 1,
  },
  version => {
    data_type         => 'varchar',
    # size needs to be at least
    # 40 to support SHA1 versions
    size              => '50'
  },
  ddl => {
    data_type         => 'text',
    is_nullable       => 1,
  },
  upgrade_sql => {
    data_type         => 'text',
    is_nullable       => 1,
  },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(['version']);
__PACKAGE__->resultset_class('DBIx::Class::DeploymentHandler::VersionStorage::Standard::VersionResultSet');

1;

# vim: ts=2 sw=2 expandtab

__END__

=pod

=head1 NAME

DBIx::Class::DeploymentHandler::VersionStorage::Standard::VersionResult - The typical way to store versions in the database

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
