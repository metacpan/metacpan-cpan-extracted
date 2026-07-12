package DBIO::MySQL::Deploy;
# ABSTRACT: Deploy and upgrade MySQL/MariaDB schemas via test-deploy-and-compare

use strict;
use warnings;

use base 'DBIO::Deploy::Base::TempDatabase';

use DBIO::MySQL::DDL        ();
use DBIO::MySQL::Introspect ();
use DBIO::MySQL::Diff       ();

# The three class-name hooks DBIO::Deploy::Base needs.

sub _ddl_class       { 'DBIO::MySQL::DDL' }
sub _introspect_class { 'DBIO::MySQL::Introspect' }
sub _diff_class      { 'DBIO::MySQL::Diff' }



# --- MySQL-specific temp-database dialect ---

sub _create_temp_db {
  my ($self, $dbh) = @_;
  my $name = $self->temp_db_prefix . $$ . '_' . time();
  $dbh->do(sprintf 'CREATE DATABASE `%s`', $name);
  return $name;
}

sub _drop_temp_db {
  my ($self, $dbh, $name) = @_;
  $dbh->do(sprintf 'DROP DATABASE IF EXISTS `%s`', $name);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Deploy - Deploy and upgrade MySQL/MariaDB schemas via test-deploy-and-compare

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::MySQL::Deploy> orchestrates the deployment and upgrade of
MySQL/MariaDB schemas using a test-deploy-and-compare strategy: it
deploys the desired schema into a freshly created temporary
C<CREATE DATABASE> database, introspects it, and diffs the result
against the live database. See L<DBIO::Deploy::Base> for the shared
install/apply/upgrade flow; see L<DBIO::Deploy::Base::TempDatabase>
for the temp-database orchestration this driver inherits.

    my $deploy = DBIO::MySQL::Deploy->new(
        schema => MyApp::DB->connect($dsn, $user, $pass),
    );

    $deploy->install;     # fresh install
    $deploy->upgrade;     # diff + apply

=head1 ATTRIBUTES

=head2 temp_db_prefix

Prefix for temporary databases created during C<diff>. Defaults to
C<_dbio_tmp_>. The full name includes the PID and current timestamp.
Inherited from L<DBIO::Deploy::Base::TempDatabase>.

=over 4

=item * L<DBIO::MySQL>

=item * L<DBIO::MySQL::DDL>

=item * L<DBIO::MySQL::Introspect>

=item * L<DBIO::MySQL::Diff>

=item * L<DBIO::PostgreSQL::Deploy> - the PostgreSQL counterpart

=item * L<DBIO::SQLite::Deploy> - the SQLite counterpart

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
