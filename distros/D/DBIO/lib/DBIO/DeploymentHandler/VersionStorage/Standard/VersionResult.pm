package DBIO::DeploymentHandler::VersionStorage::Standard::VersionResult;
# ABSTRACT: The typical way to store versions in the database

use strict;
use warnings;

use base 'DBIO::Core';

my $table = 'dbix_class_deploymenthandler_versions';

__PACKAGE__->table($table);

__PACKAGE__->add_columns (
  id => {
    data_type         => 'int',
    is_auto_increment => 1,
  },
  version => {
    data_type         => 'varchar',
    size              => '50',
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
__PACKAGE__->resultset_class('DBIO::DeploymentHandler::VersionStorage::Standard::VersionResultSet');

sub sqlt_deploy_hook {
  my ( $self, $sqlt_table ) = @_;
  my $tname = $sqlt_table->name;
  return if $tname eq $table;
  foreach my $c ( $sqlt_table->get_constraints ) {
    ( my $cname = $c->name ) =~ s/\Q$table\E/$tname/;
    $c->name($cname);
  }
}

1;

# vim: ts=2 sw=2 expandtab

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DeploymentHandler::VersionStorage::Standard::VersionResult - The typical way to store versions in the database

=head1 VERSION

version 0.900001

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
