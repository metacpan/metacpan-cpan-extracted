package DBIO::Firebird::Deploy;
# ABSTRACT: Deploy and upgrade Firebird schemas via test-deploy-and-compare

use strict;
use warnings;

use base 'DBIO::Deploy::Base::TempDatabase';

use DBI;
use DBD::Firebird;
use File::Basename ();
use DBIO::Firebird::DDL;
use DBIO::Firebird::Introspect;
use DBIO::Firebird::Diff;



sub _ddl_class        { 'DBIO::Firebird::DDL' }
sub _introspect_class { 'DBIO::Firebird::Introspect' }
sub _diff_class       { 'DBIO::Firebird::Diff' }

# --- Firebird-specific temp-database seam ---

# DSQL cannot prepare a CREATE DATABASE statement (SQLCODE -530), so the temp
# database is created out-of-band with DBD::Firebird->create_database -- a class
# method that croaks on error and runs no transaction. The temp file is placed
# server-side, co-located with the live database (same host[/port] and the same
# directory as the live db file), so it lands somewhere predictable and
# writable. The full host/port:/abs/path.fdb identifier is returned and is what
# _temp_dsn / _temp_connect_info consume, keeping create, connect and drop all
# referring to the same database.
sub _create_temp_db {
  my ($self, $dbh) = @_;

  my ($hostport, $dir) = $self->_live_db_location;
  my $name = $self->temp_db_prefix . $$ . '_' . time() . '.fdb';
  my $id   = ($hostport eq '' ? '' : "$hostport:") . "$dir/$name";

  my (undef, $user, $pass) = $self->_temp_connect_info($id);
  DBD::Firebird->create_database({
    db_path       => $id,
    user          => $user,
    password      => $pass,
    dialect       => 3,
    page_size     => 4096,
    character_set => 'UTF8',
  });

  return $id;
}

sub _drop_temp_db {
  my ($self, $dbh, $name) = @_;

  # DROP DATABASE in Firebird drops whatever database the handle is connected
  # to -- it takes no name. Running it on the production $dbh would drop the
  # live database. Connect a throw-away handle to the temp database and drop
  # that instead. DSQL cannot prepare DROP DATABASE (SQLCODE -104), so the drop
  # goes through $temp_dbh->func("ib_drop_database"); the handle is invalid
  # afterwards, so it is not disconnected.
  my ($dsn, $user, $pass) = $self->_temp_connect_info($name);
  my $temp_dbh = DBI->connect($dsn, $user, $pass, {
    RaiseError => 1, AutoCommit => 1,
  }) or die "Cannot connect to temp database for drop: $DBI::errstr";

  $temp_dbh->func("ib_drop_database");
}

# Resolve the live database's server-side location from the storage connect_info:
# the host[/port] and the directory of the live db file, so the temp database is
# co-located with it. Returns ($hostport, $dir); $hostport is '' for a host-less
# (purely local) DSN.
sub _live_db_location {
  my ($self) = @_;
  my @info = @{ $self->schema->storage->connect_info };
  my $dsn  = ref $info[0] eq 'HASH' ? $info[0]{dsn} : $info[0];

  die ref($self) . ' does not support coderef DSN for temp database connections'
    if ref $dsn eq 'CODE';

  my ($db) = $dsn =~ /(?:database|dbname)=([^;]+)/i
    or die ref($self) . ": cannot find dbname=/database= in DSN '$dsn'";

  my ($hostport, $abs);
  if ($db =~ m{^([^/].*?):(/.*)$}) { ($hostport, $abs) = ($1, $2) }
  else                             { ($hostport, $abs) = ('', $db) }

  return ($hostport, File::Basename::dirname($abs));
}

# $_[2] is the temp-db identifier passed by _temp_connect_info, which is already
# the full host/port:/abs/path.fdb spelling (built by _create_temp_db); connect
# to it with the same dbname= DSN form the live DSN uses. Only the DSN form
# differs from the base -- the connect-info shape handling, user/password
# extraction and coderef-DSN guard are inherited from _temp_connect_info.
sub _temp_dsn { "dbi:Firebird:dbname=$_[2]" }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Deploy - Deploy and upgrade Firebird schemas via test-deploy-and-compare

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::Firebird::Deploy> orchestrates the deployment and upgrade of Firebird
schemas using a test-deploy-and-compare strategy. The orchestration
(C<install>, C<diff>, C<apply>, C<upgrade>, and the create-temp /
deploy-introspect / drop-temp flow) is inherited from
L<DBIO::Deploy::Base::TempDatabase>; this class supplies only the
Firebird-specific seams:

=over 4

=item * the three class-name hooks (L<DBIO::Deploy::Base/_ddl_class>,
C<_introspect_class>, C<_diff_class>);

=item * L</_create_temp_db> / L</_drop_temp_db> -- Firebird creates the temp
database out-of-band via C<< DBD::Firebird->create_database >> and drops it via
C<< $dbh->func("ib_drop_database") >>, because DSQL cannot prepare
database-level DDL (C<do("CREATE DATABASE")> / C<do("DROP DATABASE")> fail);

=item * L</_temp_dsn> -- Firebird's C<dbi:Firebird:dbname=$id> DSN form, where
C<$id> is the full C<host/port:/abs/path.fdb> identifier returned by
L</_create_temp_db>.

=back

    my $deploy = DBIO::Firebird::Deploy->new(
        schema => MyApp::DB->connect($dsn),
    );

    $deploy->install;            # fresh install
    $deploy->upgrade;            # test-deploy + compare + apply

    my $diff = $deploy->diff;    # or in steps
    print $diff->summary;
    $deploy->apply($diff) if $diff->has_changes;

=head1 ATTRIBUTES

=head2 schema

A connected L<DBIO::Schema> instance using the L<DBIO::Firebird> component.
Required. (Inherited from L<DBIO::Deploy::Base>.)

=seealso

=over 4

=item * L<DBIO::Deploy::Base::TempDatabase> - shared temp-database orchestration

=item * L<DBIO::Firebird> - schema component

=item * L<DBIO::Firebird::DDL> - generates the DDL used by C<install> and C<diff>

=item * L<DBIO::Firebird::Introspect> - reads the live and temp database state

=item * L<DBIO::Firebird::Diff> - compares the two introspected models

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
