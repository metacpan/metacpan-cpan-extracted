package DBIO::Oracle::Deploy;
# ABSTRACT: Deploy and upgrade Oracle schemas via test-deploy-and-compare

use strict;
use warnings;

use base 'DBIO::Deploy::Base';

use DBI;
use DBIO::Oracle::DDL       ();
use DBIO::Oracle::Introspect ();
use DBIO::Oracle::Diff      ();


# --- class-name hooks for DBIO::Deploy::Base -------------------------------

sub _ddl_class        { 'DBIO::Oracle::DDL'        }
sub _introspect_class { 'DBIO::Oracle::Introspect' }
sub _diff_class       { 'DBIO::Oracle::Diff'       }


sub _build_target_model {
  my ($self) = @_;
  my $dbh = $self->_dbh;

  $dbh->do('SAVEPOINT _dbio_deploy');

  my $target_model;
  my $err;
  eval {
    $self->_execute_ddl($dbh, $self->_install_ddl);
    $target_model = $self->_new_introspect($dbh)->model;
    1;
  } or $err = $@;

  # Always restore the live connection, even on failure.
  eval { $dbh->do('ROLLBACK TO SAVEPOINT _dbio_deploy'); };

  die $err if $err;
  return $target_model;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Deploy - Deploy and upgrade Oracle schemas via test-deploy-and-compare

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

C<DBIO::Oracle::Deploy> orchestrates schema deployment and upgrades for
Oracle using the test-deploy-and-compare strategy.

For upgrades it:

=over 4

=item 1. Introspects the live database via C<all_*> views

=item 2. Opens a C<SAVEPOINT> on the live connection (Oracle has no
cheap throwaway database like PostgreSQL's C<CREATE DATABASE>)

=item 3. Deploys the desired schema (from DBIO classes) into that context

=item 4. Introspects that schema the same way

=item 5. Computes the diff between the two models using L<DBIO::Oracle::Diff>

=item 6. Rolls back to the savepoint so the test deploy never persists

=back

The shared orchestration (L<install|/install>, L<apply|/apply>,
L<upgrade|/upgrade>) is inherited from L<DBIO::Deploy::Base>; this class
supplies the three class-name hooks and the SAVEPOINT-based
L</_build_target_model> -- the real engine seam.

    my $deploy = DBIO::Oracle::Deploy->new(
        schema => MyApp::DB->connect($dsn),
    );
    $deploy->install;                       # fresh
    my $diff = $deploy->diff;              # or step-by-step
    $deploy->apply($diff) if $diff->has_changes;
    $deploy->upgrade;                      # convenience

=head1 METHODS

=head2 _build_target_model

The desired-state model. Oracle has no cheap throwaway database, so
test-deploy-and-compare runs against the live connection inside a
C<SAVEPOINT>: deploy the install DDL, introspect the result, then
C<ROLLBACK TO SAVEPOINT> to undo the partial deploy. The rollback runs
unconditionally inside the eval -- even when introspect or deploy
throws, the connection state must be restored.

=seealso

=over 4

=item * L<DBIO::Oracle> - schema component

=item * L<DBIO::Oracle::DDL> - generates DDL

=item * L<DBIO::Oracle::Introspect> - reads live database state

=item * L<DBIO::Oracle::Diff> - compares two introspected models

=item * L<DBIO::Deploy::Base> - inherited orchestration

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
