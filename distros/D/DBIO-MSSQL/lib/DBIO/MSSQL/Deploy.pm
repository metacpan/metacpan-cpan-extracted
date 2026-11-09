package DBIO::MSSQL::Deploy;
# ABSTRACT: Deploy and upgrade MSSQL schemas via test-deploy-and-compare

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Deploy::Base::TempDatabase';

use DBIO::Exception ();
use DBIO::MSSQL::DDL;
use DBIO::MSSQL::Diff::Column ();
use DBIO::MSSQL::Introspect;
use DBIO::MSSQL::Diff;


sub _ddl_class        { 'DBIO::MSSQL::DDL' }
sub _introspect_class { 'DBIO::MSSQL::Introspect' }
sub _diff_class       { 'DBIO::MSSQL::Diff' }


sub _new_introspect {
  my ($self, $dbh) = @_;
  return $self->_introspect_class->new(
    dbh     => $dbh,
    schemas => [ DBIO::MSSQL::DDL::_schemas_of($self->schema) ],
  );
}


sub _create_temp_db {
  my ($self, $dbh) = @_;
  my $name = $self->temp_db_prefix . $$ . '_' . time();
  $self->_require_autocommit($dbh, '_create_temp_db');
  my ($collation) = $dbh->selectrow_array(
    q{SELECT CAST(DATABASEPROPERTYEX(DB_NAME(), 'Collation') AS nvarchar(128))});
  $dbh->do("CREATE DATABASE $name"
    . (defined $collation && $collation =~ /\A\w+\z/ ? " COLLATE $collation" : ''));
  return $name;
}


sub _drop_temp_db {
  my ($self, $dbh, $name) = @_;
  $self->_require_autocommit($dbh, '_drop_temp_db');
  $dbh->do("DROP DATABASE $name");
}

# CREATE/DROP DATABASE may not run in a transaction, and neither switching
# AutoCommit on nor a COMMIT would leave the caller's transaction standing:
# a handle with AutoCommit off is refused before any statement (karr k80).
sub _require_autocommit {
  my ($self, $dbh, $method) = @_;
  my $ac = $dbh->{AutoCommit};
  return unless defined $ac && $ac == 0;
  require DBIO::Exception;
  DBIO::Exception->throw(
    ref($self) . "::$method: refused -- the handle has AutoCommit off (a "
    . "transaction may be open), and CREATE DATABASE and DROP DATABASE cannot run "
    . "inside a transaction; nothing was sent and the transaction is untouched. "
    . "Pass a handle with AutoCommit on."
  );
}


sub _check_before_apply {
  my ($self, $diff) = @_;
  $self->_refuse_unfillable($diff, $self->_dbh);
  return $self->next::method($diff);
}


sub _refuse_unfillable {
  my ($self, $diff, $dbh) = @_;

  my $has_rows = sub {
    my ($table, $where) = @_;
    return scalar $dbh->selectrow_array(sprintf 'SELECT TOP 1 1 FROM %s%s',
      DBIO::MSSQL::DDL::_quote_table($table), $where // '');
  };

  for my $op (@{ $diff->operations }) {
    next unless $op->isa('DBIO::MSSQL::Diff::Column');
    my ($table, $column) = ($op->table_name, $op->column_name);

    if ($op->action eq 'add') {
      my $new = $op->new_info || {};
      next unless $new->{not_null} && !defined $new->{default_value};
      next unless $has_rows->($table);
      DBIO::Exception->throw(sprintf
        'SQL Server refuses to add the column %s.%s: it is NOT NULL without a '
        . 'default, and table %s holds rows that would have no value for it',
        $table, $column, $table);
    }
    elsif ($op->action eq 'alter') {
      my ($old, $new) = ($op->old_info || {}, $op->new_info || {});
      my $nn = defined $new->{not_null} ? $new->{not_null} : $old->{not_null};
      next unless $nn && !$old->{not_null};
      next unless $has_rows->($table,
        ' WHERE ' . DBIO::MSSQL::DDL::_quote_ident($column) . ' IS NULL');
      DBIO::Exception->throw(sprintf
        'SQL Server refuses to make the column %s.%s NOT NULL: table %s holds '
        . 'rows where it is NULL', $table, $column, $table);
    }
  }
  return;
}


sub _temp_dsn {
  my ($self, $dsn, $temp_db) = @_;

  return $dsn if $dsn =~ s/\b((?:Database|dbname)=)[^;]*/$1$temp_db/i;

  my $key = $dsn =~ /^dbi:Sybase:/i ? 'database' : 'Database';
  $dsn =~ s/;\z//;
  return "$dsn;$key=$temp_db";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Deploy - Deploy and upgrade MSSQL schemas via test-deploy-and-compare

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::MSSQL::Deploy> orchestrates schema deployment and upgrades for
Microsoft SQL Server using the test-deploy-and-compare strategy.

The orchestration (C<install>, C<diff>, C<apply>, C<upgrade>) and the
temp-database lifecycle are inherited from
L<DBIO::Deploy::Base::TempDatabase>: C<diff> introspects the live database,
deploys the desired DDL into a throwaway database, introspects that, and
diffs the two models. This class supplies only the MSSQL-specific seams: the
three class-name hooks and the C<CREATE>/C<DROP DATABASE> dialect.

    my $deploy = DBIO::MSSQL::Deploy->new(
        schema => MyApp::DB->connect($dsn),
    );
    $deploy->install;                       # fresh
    my $diff = $deploy->diff;               # or step-by-step
    $deploy->apply($diff) if $diff->has_changes;
    $deploy->upgrade;                       # convenience

=head2 Transactional DDL -- used, and bounded

L<DBIO::MSSQL::Storage> declares C<< _use_transactional_ddl(1) >>, alone among
this family's drivers apart from PostgreSQL. So C<install> and C<apply> hand
their whole batch to L<DBIO::Deploy::Base/_execute_ddl>, which brackets it in
C<< $storage->txn_do >>: a statement the server rejects half way through takes
the earlier ones with it, and core's one-time "non-transactional DDL" notice
does not appear. The reasoning, the statement inventory it rests on and the
Transact-SQL sources are in L<DBIO::MSSQL::Storage>; the short version is that
Microsoft documents the rule as a closed list of statements that may B<not>
appear in an explicit transaction, and nothing this driver emits is on it.

Three boundaries are worth knowing, because the bracket is narrower than the
capability sounds.

B<The temporary database is never inside it.> C<_build_target_model> connects
to the throwaway database itself, and C<_execute_ddl> only brackets a handle
the storage owns (core 0.900004). The install DDL deployed into the temp
database therefore runs statement at a time, silently and correctly: that
database is dropped whole on any failure, which is its unit of recovery.
C<_create_temp_db> and C<_drop_temp_db> are outside the batch path
altogether -- C<CREATE DATABASE> and C<DROP DATABASE> are two of the statements
on Microsoft's list, and both are issued straight to a handle that must already be in
autocommit mode, which their reference pages require; a handle with
C<< AutoCommit => 0 >> is refused, never committed or switched.

B<The deployment handler reads the same capability and wraps more.>
L<DBIO::DeploymentHandler>, seeing it true, brackets the B<entire> body of its
C<upgrade> -- the diff as well as the apply -- in one transaction on the live
connection, and the diff is what creates the temporary database. C<CREATE
DATABASE> cannot run inside that transaction, and this class does not end it:
C<_create_temp_db> and C<_drop_temp_db> refuse a handle with C<AutoCommit>
off. The core base class L<DBIO::Deploy::Base::TempDatabase> hands them a
connection of its own with C<AutoCommit> on while the storage holds a
transaction (C<_admin_dbh>), so the live transaction is not touched and the
refusal is the guard for any other caller that passes the handle of an open
transaction. Driving C<upgrade> on B<this> class has no such problem either:
the temp database is created, used and dropped before C<apply> opens its
bracket.

B<Snapshot isolation is the documented way to break it.> SQL Server does not
version metadata, so under C<SET TRANSACTION ISOLATION LEVEL SNAPSHOT> the
statements C<ALTER TABLE>, C<CREATE INDEX>, C<ALTER INDEX> and C<DROP INDEX>
are refused after a C<BEGIN TRANSACTION> with error 3961 -- roughly half of
what a diff emits. Nothing in this driver or in core asks for that isolation
level, and a hand-written C<txn_do> around the same DDL would fail identically,
but a session that opts into it will see a bracketed deploy fail where an
unbracketed one succeeded.

=head1 METHODS

=head2 _new_introspect

    my $intro = $self->_new_introspect($dbh);

The introspector reads C<dbo> and every other schema the classes name (a table
C<schema.table>), in the live database and in the throwaway one
alike. A schema the classes do not name is not looked at: its tables are
neither compared nor dropped.

=head2 _create_temp_db

    my $name = $self->_create_temp_db($dbh);

Creates a uniquely-named throwaway database with T-SQL C<CREATE DATABASE>,
with the collation of the database the handle is connected to: the
desired schema is deployed under the rules the live database has, not the
server's default -- names that differ in case only are two objects in a
case-sensitive database and a refusal (Msg 2714) in the default one.
MSSQL cannot run C<CREATE DATABASE> inside a transaction, and this method
neither commits nor switches the handle to autocommit: a handle with
C<AutoCommit> off is refused with a L<DBIO::Exception> naming the method,
before any statement (the collation query included) is sent. The transaction
stays as it was. The caller passes a handle with C<AutoCommit> on.

=head2 _drop_temp_db

    $self->_drop_temp_db($dbh, $name);

Drops the throwaway database with T-SQL C<DROP DATABASE>. Refuses a handle
with C<AutoCommit> off like L</_create_temp_db>, before any statement.

=head2 _check_before_apply

    $self->_check_before_apply($diff);

The driver's check of L<DBIO::Deploy::Base/apply>, run for a released diff
before its first statement: L</_refuse_unfillable> against the live
connection. C<apply> and C<upgrade> are L<DBIO::Deploy::Base>'s as they are
(the guard for destructive and lossy operations C<allow_destructive>,
C<dry_run>, the statements through C<_execute_diff>).

=head2 _refuse_unfillable

    $self->_refuse_unfillable($diff, $dbh);

Refuses -- a L<DBIO::Exception> naming table and column, nothing sent -- what
SQL Server would refuse for the rows a table holds half way through the diff:

=over 4

=item * a C<NOT NULL> column without a default that the diff adds to a table
        that holds rows: "ALTER TABLE only allows columns to be added that can
        contain nulls, or have a DEFAULT definition specified" (Msg 4901);

=item * a column that becomes C<NOT NULL> in a table that has a C<NULL> in it
        (Msg 515, C<ALTER COLUMN>).

=back

An empty table and a table with no C<NULL> in the column pass. Without the
check the server's error dooms the transaction C<_execute_ddl> brackets the
batch in; the rollback is refused, core discards the handle and runs the body
again on the dead handle, and the caller got "Cannot allocate statement when
disconnected from the database" instead of the cause.

=head2 _temp_dsn

MSSQL DSNs name the database with C<Database=> (DBD::ODBC) or C<database=>
(DBD::Sybase); the key is replaced in its own spelling, or appended in the
DBD's spelling when the DSN names none. The spelling matters: DBD::Sybase does
not read C<Database=>, ignores it, and connects to the login's default
database -- the diff would then compare against that database instead of the
temporary one. (The base default appends C<dbname=>, which neither DBD
honours.)

=head1 SEE ALSO

=pod

=over

=item * L<DBIO::Deploy::Base::TempDatabase> - shared temp-database orchestration

=item * L<DBIO::MSSQL> - schema component

=item * L<DBIO::MSSQL::DDL> - generates DDL

=item * L<DBIO::MSSQL::Introspect> - reads live database state

=item * L<DBIO::MSSQL::Diff> - compares two introspected models

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
