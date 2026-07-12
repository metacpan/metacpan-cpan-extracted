package DBIO::SQLite::Deploy;
# ABSTRACT: Deploy and upgrade SQLite schemas via test-deploy-and-compare

use strict;
use warnings;

use base 'DBIO::Deploy::Base';

use DBI;
use DBIO::SQLite::DDL;
use DBIO::SQLite::Introspect;
use DBIO::SQLite::Diff;


# --- hooks for Deploy::Base -------------------------------------------------

sub _ddl_class        { 'DBIO::SQLite::DDL' }
sub _introspect_class { 'DBIO::SQLite::Introspect' }
sub _diff_class       { 'DBIO::SQLite::Diff' }


sub _build_target_model {
  my ($self) = @_;

  my $temp_dbh = DBI->connect('dbi:SQLite::memory:', '', '', {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });
  $temp_dbh->do('PRAGMA foreign_keys = ON');

  $self->_execute_ddl($temp_dbh, $self->_install_ddl);

  my $model = $self->_new_introspect($temp_dbh)->model;
  $temp_dbh->disconnect;
  return $model;
}


sub apply {
  my ($self, $diff) = @_;
  my $ret = $self->SUPER::apply($diff);
  return $ret unless $ret;

  return $ret
    unless grep { $_->isa('DBIO::SQLite::Diff::Rebuild') } @{ $diff->operations };

  my $bad = $self->_dbh->selectall_arrayref('PRAGMA foreign_key_check');
  if (@$bad) {
    my %tables = map { ($_->[0] // '?') => 1 } @$bad;
    $self->schema->storage->throw_exception(
      'Foreign key violations after table rebuild: ' . join(', ', sort keys %tables)
    );
  }

  return $ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Deploy - Deploy and upgrade SQLite schemas via test-deploy-and-compare

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::SQLite::Deploy> orchestrates the deployment and upgrade of
SQLite schemas using a test-deploy-and-compare strategy.

For upgrades, instead of computing diffs from abstract class
representations, it:

=over 4

=item 1. Introspects the live database via C<sqlite_master> and PRAGMAs

=item 2. Connects to a fresh in-memory SQLite database

=item 3. Deploys the desired schema (from DBIO classes) into the in-memory DB

=item 4. Introspects the in-memory database the same way

=item 5. Computes the diff between the two models using L<DBIO::SQLite::Diff>

=back

The temp DB is in-memory and goes away when the connection drops -- much
simpler than the temp-database approach used for PostgreSQL.

The orchestration (C<install>, C<apply>, C<upgrade>) and the C<diff>
shell come from L<DBIO::Deploy::Base>; only the engine-specific
target-model build is overridden here.

    my $deploy = DBIO::SQLite::Deploy->new(
        schema => MyApp::DB->connect("dbi:SQLite:dbname=app.db"),
    );

    # Fresh install
    $deploy->install;

    # Upgrade
    $deploy->upgrade;

    # Or in steps:
    my $diff = $deploy->diff;
    print $diff->summary;
    $deploy->apply($diff) if $diff->has_changes;

=head1 METHODS

=head2 _build_target_model

Connect to a throwaway in-memory SQLite database, deploy the desired
schema into it, and return its introspected model. The in-memory
connection goes out of scope at the end of this method (and is
disconnected explicitly for predictability), so the target DB is gone
before the diff object is built.

=head2 apply

Apply the diff, then -- if it contained a table rebuild -- verify cross-table
foreign-key integrity. A rebuild runs with C<PRAGMA foreign_keys=OFF> so it
can drop and rename a referenced table; once it is back in place this runs
C<PRAGMA foreign_key_check> and throws if any dangling references remain.
Non-rebuild upgrades are untouched (no extra check).

=over 4

=item * L<DBIO::SQLite> - schema component

=item * L<DBIO::SQLite::DDL> - generates DDL used by C<install> and C<diff>

=item * L<DBIO::SQLite::Introspect> - reads live database state

=item * L<DBIO::SQLite::Diff> - compares two introspected models

=item * L<DBIO::Deploy::Base> - shared install/apply/upgrade orchestration

=item * L<DBIO::PostgreSQL::Deploy> - the PostgreSQL counterpart (temp-database variant)

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
