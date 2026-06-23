package DBIO::Sybase::Deploy;
# ABSTRACT: Deploy and upgrade Sybase ASE schemas via test-deploy-and-compare

use strict;
use warnings;

use base 'DBIO::Deploy::Base::TempDatabase';

use DBIO::Sybase::Diff;
use DBIO::Sybase::Introspect;
use DBIO::Sybase::DDL;


# Class-name hooks consumed by DBIO::Deploy::Base.
sub _ddl_class       { 'DBIO::Sybase::DDL' }
sub _introspect_class { 'DBIO::Sybase::Introspect' }
sub _diff_class      { 'DBIO::Sybase::Diff' }

# --- temp-database glue (engine-specific) ---------------------------------

# Create a uniquely-named temp database and return its name. CREATE DATABASE
# cannot run inside a transaction, so AutoCommit is forced on for the call.
sub _create_temp_db {
  my ($self, $dbh) = @_;
  my $name = $self->temp_db_prefix . $$ . '_' . time();

  $dbh->do('COMMIT') if $dbh->{AutoCommit} == 0;
  local $dbh->{AutoCommit} = 1;
  $dbh->do("CREATE DATABASE $name");
  return $name;
}

sub _drop_temp_db {
  my ($self, $dbh, $name) = @_;
  local $dbh->{AutoCommit} = 1;
  $dbh->do("DROP DATABASE $name");
  return 1;
}






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Deploy - Deploy and upgrade Sybase ASE schemas via test-deploy-and-compare

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

C<DBIO::Sybase::Deploy> orchestrates schema deployment and upgrades for
Sybase ASE using the test-deploy-and-compare strategy.

For upgrades it:

=over 4

=item 1. Introspects the live database via C<INFORMATION_SCHEMA>

=item 2. Deploys the desired schema (from DBIO classes) to a temporary database

=item 3. Introspects the temporary database the same way

=item 4. Computes the diff between the two models using L<DBIO::Sybase::Diff>

=back

=head1 METHODS

=head2 install

    $deploy->install;

Generates DDL via L<DBIO::Sybase::DDL/install_ddl> and executes each
statement against the connected database. Suitable for fresh installs.

B<NOTE>: L<DBIO::Sybase::DDL> does not yet exist. This method currently
falls back to the SQL::Translator codepath via L<DBIO::Schema/deploy>.

=head2 diff

    my $diff = $deploy->diff;

Computes the difference between the live database and the desired state.
Deploys the desired schema to a temporary database, introspects both,
and returns a L<DBIO::Sybase::Diff> object.

=head2 apply

    $deploy->apply($diff);

Applies a L<DBIO::Sybase::Diff> object by executing each statement from
C<< $diff->as_sql >>. No-op if the diff has no changes.

=head2 upgrade

    my $diff = $deploy->upgrade;

Convenience: calls L</diff> then L</apply>. Returns the diff object if
changes were applied, or C<undef> if the database was already up to date.

=seealso

=over 4

=item * L<DBIO::Sybase> - schema component

=item * L<DBIO::Sybase::Introspect> - reads live database state

=item * L<DBIO::Sybase::Diff> - compares two introspected models

=item * L<DBIO::DuckDB::Deploy> - reference implementation

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
