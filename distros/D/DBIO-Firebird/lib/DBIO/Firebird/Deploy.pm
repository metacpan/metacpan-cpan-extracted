package DBIO::Firebird::Deploy;
# ABSTRACT: Deploy and upgrade Firebird schemas via test-deploy-and-compare

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Deploy::Base::TempDatabase';

use DBI;
use DBD::Firebird;
use File::Basename ();
use DBIO::Util ();
use DBIO::Exception ();
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

  my ($dsn, $user, $pass) = $self->_temp_connect_info($id);

  # create_database puts the password into the text of a CREATE DATABASE
  # statement and croaks with whatever the engine makes of it: never the
  # password (karr k39, core k297)
  eval {
    DBD::Firebird->create_database({
      db_path       => $id,
      user          => $user,
      password      => $pass,
      dialect       => 3,
      page_size     => 4096,
      character_set => 'UTF8',
    });
    1;
  } or die DBIO::Util::mask_connect_secrets($@, [ $dsn, $user, $pass ]);

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
  # DBI dies quoting the DSN it was given, and the DBD may repeat any of the
  # rest: never the password (karr k39, core k297)
  my $temp_dbh = eval {
    DBI->connect($dsn, $user, $pass, {
      RaiseError => 1, AutoCommit => 1,
    })
  } or die DBIO::Util::mask_connect_secrets(
    $@ || "Cannot connect to temp database for drop: $DBI::errstr", [ $dsn, $user, $pass ],
  );

  $temp_dbh->func("ib_drop_database");
}

# Resolve the live database's server-side location from the storage connect_info:
# the host[/port] and the directory of the live db file, so the temp database is
# co-located with it. Returns ($hostport, $dir); $hostport is '' for a host-less
# (purely local) DSN.
# The live connection's ($dsn, $user, $pass). With an AccessBroker the storage's
# connect_info is [ $broker ] and holds nothing of its answer; the answer of
# this moment is what _dbi_connect_info reads, normalised to
# [ $dsn, $user, $pass, \%attrs ] (karr k42). Without a broker, connect_info
# as given.
sub _live_connect_info {
  my ($self) = @_;
  my $storage = $self->schema->storage;

  # A user or password the connect info does not give is '' (core karr k392:
  # DBI_USER / DBI_PASS stand in for nothing).
  my @live;
  if ($storage->can('access_broker') && $storage->access_broker) {
    @live = @{ $storage->_dbi_connect_info }[0 .. 2];
  }
  else {
    my @info = @{ $storage->connect_info };
    @live = ref $info[0] eq 'HASH'
      ? ( $info[0]{dsn}, $info[0]{user}, $info[0]{password} // $info[0]{pass} )
      : @info[0 .. 2];
  }
  return ( $live[0], $live[1] // '', $live[2] // '' );
}

sub _live_db_location {
  my ($self) = @_;
  my ($dsn, $user, $pass) = $self->_live_connect_info;

  die ref($self) . ' does not support coderef DSN for temp database connections'
    if ref $dsn eq 'CODE';

  # The attribute names DBD::Firebird's own DSN parser accepts: db/dbname/
  # database for the path, host/hostname, port. The host may also ride in the
  # path as host[/port]:/abs/path, or in host= as host/port.
  my %attr;
  for my $part (split /;/, $dsn =~ s/^dbi:[^:]*://ir) {
    my ($k, $v) = split /=/, $part, 2;
    $attr{lc $k} = $v if defined $v;
  }
  my $db = $attr{dbname} // $attr{db} // $attr{database};
  # the DSN is the caller's and may carry a password (karr k39, core k297)
  die DBIO::Util::mask_connect_secrets(
    ref($self) . ": cannot find dbname=/database= in DSN '$dsn'", [ $dsn, $user, $pass ],
  ) unless defined $db && length $db;
  my $host = $attr{host} // $attr{hostname};

  my ($hostport, $abs);
  if ($db =~ m{^([^/].*?):(/.*)$}) { ($hostport, $abs) = ($1, $2) }
  else {
    $abs      = $db;
    $hostport = '';
    if (defined $host && length $host) {
      $hostport = $host;
      $hostport .= "/$attr{port}"
        if defined $attr{port} && length $attr{port} && $host !~ m{/};
    }
  }

  return ($hostport, File::Basename::dirname($abs));
}

# $_[2] is the temp-db identifier passed by core's _temp_connect_info, which is
# already the full host/port:/abs/path.fdb spelling (built by _create_temp_db);
# connect to it with the same dbname= DSN form the live DSN uses. Only the DSN
# form differs from the base -- the connect-info shape handling (also an
# AccessBroker's answer, karr k42), user/password extraction and coderef-DSN
# guard are inherited from core's _temp_connect_info.
sub _temp_dsn { "dbi:Firebird:dbname=$_[2]" }


sub _check_before_apply {
  my ($self, $diff) = @_;
  $diff->as_sql;
  $self->_refuse_unfillable($diff, $self->_dbh);
  return $self->SUPER::_check_before_apply($diff);
}


sub _refuse_unfillable {
  my ($self, $diff, $dbh) = @_;

  my $q = \&DBIO::Firebird::DDL::_firebird_quote_ident;
  my $has_rows = sub {
    my ($table, $where) = @_;
    return scalar $dbh->selectrow_array(sprintf 'SELECT FIRST 1 1 FROM %s%s',
      $q->($table), $where // '');
  };

  my @found;
  for my $op (@{ $diff->operations }) {
    next unless $op->isa('DBIO::Firebird::Diff::Column');
    my ($table, $column) = ($op->table_name, $op->column_name);
    my $new = $op->new_info // {};

    if ($op->action eq 'add') {
      next unless $new->{not_null} && !$new->{is_auto_increment};
      my $default = $new->{default_value};
      next if ref $default
        || (defined $default && $default =~ /\S/ && $default !~ /^\s*NULL\s*$/i);
      next unless $has_rows->($table);
      push @found, sprintf
        '  %s.%s: added NOT NULL without a default, and the table holds rows that would have no value for it',
        $q->($table), $q->($column);
    }
    elsif ($op->action eq 'alter') {
      next unless $new->{not_null} && !($op->old_info // {})->{not_null};
      next unless $has_rows->($table, ' WHERE ' . $q->($column) . ' IS NULL');
      push @found, sprintf
        '  %s.%s: becomes NOT NULL, and the table holds rows where it is NULL',
        $q->($table), $q->($column);
    }
  }

  DBIO::Exception->throw(join "\n",
    sprintf('refusing to apply the diff: the Firebird server would refuse %s half way, with its own error',
      @found == 1 ? 'this change' : 'these changes'),
    '',
    @found,
    '',
    'No statement was run. Fill the column (or give it a default) first, or empty the table.',
    '',
  ) if @found;

  return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Deploy - Deploy and upgrade Firebird schemas via test-deploy-and-compare

=head1 VERSION

version 0.900004

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

=item * C<_create_temp_db> / C<_drop_temp_db> -- Firebird creates the temp
database out-of-band via C<< DBD::Firebird->create_database >> and drops it via
C<< $dbh->func("ib_drop_database") >>, because DSQL cannot prepare
database-level DDL (C<do("CREATE DATABASE")> / C<do("DROP DATABASE")> fail);

=item * C<_temp_dsn> -- Firebird's C<dbi:Firebird:dbname=$id> DSN form, where
C<$id> is the full C<host/port:/abs/path.fdb> identifier returned by
C<_create_temp_db>.

=back

    my $deploy = DBIO::Firebird::Deploy->new(
        schema => MyApp::DB->connect($dsn),
    );

    $deploy->install;            # fresh install
    $deploy->upgrade;            # test-deploy + compare + apply

    my $diff = $deploy->diff;    # or in steps
    print $diff->summary;
    $deploy->apply($diff) if $diff->has_changes;

=head2 Errors do not quote the password

This class creates the temporary database, connects to it once more to drop
it, and reads the live DSN to find out where to put it. What fails there
fails with a text that is not this module's: L<DBI> dies quoting the data
source it was given, C<create_database> croaks with whatever the engine makes
of a C<CREATE DATABASE> statement that carries the password in its text, and
the DSN is the caller's. Each of these messages goes through core's
C<DBIO::Util::mask_connect_secrets> together with the connect info it is
about: the password is replaced by C<***> wherever the text repeats it, and
so is the value of a C<password=> part of a DSN. The database, the host and
the user name stay -- the message still says which connection failed.

=head2 A schema on an AccessBroker

With an L<DBIO::AccessBroker> the storage's C<connect_info> is C<[ $broker ]>
and holds nothing of the broker's answer. Deploy reads the answer of the moment
from the storage (C<_dbi_connect_info>, normalised to DSN, user and password)
to find the live database's server and directory and to connect to the temp
database, so C<diff>, C<upgrade> and C<install> work as with a plain DSN. A
broker whose answer has a coderef for the DSN (or a C<dbh_maker>) is refused as
a coderef DSN is, with a message that carries no DSN and no password.

=head2 Names that differ only in case -- refused

A database whose objects were created unquoted (by hand or with another
tool) holds C<ARTIST> where the schema says C<artist>. Diffed name by name that is a table
to drop and a table to create, and C<upgrade> would empty it. It does not:
C<upgrade> and C<apply> die before they send a statement, and the object
C<diff> returns dies on first use (C<has_changes>, C<as_sql>, C<summary>),
with an error that lists every such table, column and index. What it says,
and the ways out:
L<DBIO::Firebird::Diff/NAMES THAT DIFFER ONLY IN CASE>.

=head2 Transactional DDL -- not claimed

Firebird I<has> transactional DDL and this deploy still does not use it.
L<DBIO::Firebird::Storage::Common> declares C<< _use_transactional_ddl(0) >>,
so L<DBIO::Deploy::Base/_execute_ddl> runs the statements one at a time and
core emits its one-time "non-transactional DDL" notice. The C<0> is a decision,
not a report about the engine: metadata in Firebird lives in ordinary MVCC
records in the C<rdb$> system tables, a DDL statement stays in the user
transaction until it ends, and a C<ROLLBACK> takes it back -- which is exactly
why C<isql> carries C<SET AUTODDL> (default C<ON>, committing each DDL
statement as it runs; C<isql -n> hands DDL back to the transaction).

What is withheld is narrower and is the only thing C<_execute_ddl> acts on:
that this driver's whole batch may be bracketed in one
C<< $storage->txn_do >> and come out atomic. Three things were thought to stand in the way; the
first and the third were measured on Firebird 5.0.4 (see B<Measured> below),
the value stays C<0>.

=over 4

=item 1. The diff contains a same-name C<DROP> / C<CREATE> pair.

L<DBIO::Firebird::Diff::Index> renders a changed index as C<DROP INDEX "n">
followed by C<CREATE INDEX "n"> -- one name, two adjacent statements. Today a
real C<COMMIT> separates them. Inside one transaction the re-create stores an
C<rdb$indices> row whose name duplicates one this transaction has deleted
without committing, and Firebird polices that name through its own unique index
C<rdb$index_5>, whose violation is spelled I<attempt to store duplicate value
(visible to active transactions)>.

This one decides the question rather than merely raising it, because it is a
constraint on a B<pair>. The per-statement companion of the capability,
C<_ddl_statement_is_transactional>, can say "this statement may not be inside a
transaction"; it cannot say "these two may not be inside the B<same> one".
Answering false for C<DROP INDEX> would break the pair apart by accident, while
asserting something untrue about the statement and taking every index drop out
of the atomic batch anyway.

=item 2. C<CREATE INDEX> does its work at C<COMMIT>.

Firebird 5.0 Language Reference, C<ALTER INDEX>: "if our C<ALTER INDEX>
succeeds and starts to rebuild the index at C<COMMIT>, other transactions
modifying that table will fail or wait, according to their C<WAIT>/C<NO WAIT>
attributes. The situation is the same for C<CREATE INDEX>." (Same wording in
the 2.5 reference, so it is not version-bounded.) Under a bracket every index
build in the batch lands on the single commit at the end: a failing
C<CREATE UNIQUE INDEX> is then reported by the commit rather than by the
statement that caused it, and concurrent writers are held against for the
length of the whole deploy instead of one statement.

=item 3. C<ib_softcommit> makes both the commit and the rollback I<retaining>.

L<DBIO::Firebird::Storage::InterBase> tells you to switch it on -- without it
a commit closes the cursors still open on the connection -- and it
makes L<DBD::Firebird> use C<isc_commit_retaining> and
C<isc_rollback_retaining>. Per the Firebird 5.0 Language Reference, C<RETAIN>
means the transaction "is restarted transparently with the same Transaction
ID" and, on the rollback side, that "the transaction context is to be
retained". Nothing depends on that today, because nothing ever rolls DDL back.
A C<1> would make recovery depend on a retaining rollback undoing a batch of
B<metadata> changes, which no documentation covers. Jaybird, the official
Firebird JDBC driver, declines to use commit retaining during normal execution
at all.

=back

The notice core prints is accurate: an L<apply|DBIO::Deploy::Base/apply> that
fails half way leaves the earlier statements applied. Re-running C<upgrade> is
safe, because the diff is recomputed against live state and the second run
picks up only what is left.

Either way only the live connection was ever in question.
L<diff|DBIO::Deploy::Base/diff> builds its
target model by deploying into a handle L<DBIO::Deploy::Base::TempDatabase>
opened itself, and C<_execute_ddl> never brackets a handle the storage does not
own -- so that half runs unwrapped and silent whatever this capability says,
and the throwaway database is dropped whole on failure.

Both questions were measured on Firebird 5.0.4: C<DROP INDEX "n"> plus
C<CREATE INDEX "n"> survives one transaction, and a C<txn_do> rollback under
C<ib_softcommit> takes a batch of C<rdb$> changes back. The value nevertheless
stays C<0> (maintainer's decision); the second point still holds.
Should the pair ever fail on another version, the fix belongs in
L<DBIO::Firebird::Diff::Index> -- rename through a distinct index name -- not
in the per-statement hook, which cannot express the constraint.

B<Measured> (Firebird 5.0.4, L<DBD::Firebird> 1.39, a table with an index C<i>
on column C<a>; Firebird 3 and 4 were not available and are not covered; the
value stays C<0>, flipping it is the maintainer's decision). Through C<<
$storage->txn_do >>, each time with C<ib_softcommit> off and on, with the same
result:

=over 4

=item *

C<DROP INDEX i>, C<CREATE INDEX i> on column C<b> and a C<CREATE TABLE> in one
C<txn_do> that dies: the index is back on column C<a> and the table does not
exist. The same three statements in a C<txn_do> that returns: the index is on
C<b> and the table exists. So point 1 above does not occur on 5.0.4 -- the
same name is stored again in the transaction that deleted it -- and a
retaining rollback does take the C<rdb$> changes back.

=item *

Point 2 holds: C<CREATE UNIQUE INDEX> over duplicate values B<succeeds as a
statement> and fails at C<COMMIT>, with the server's
I<attempt to store duplicate value ... in unique index> error. Through
C<txn_do> DBI itself reports the failed commit as I<DBD driver has not
implemented the AutoCommit attribute>, the server's text being only in
C<< $dbh->errstr >>; L<DBIO::Firebird::Storage::InterBase>
raises the server's text instead, as a L<DBIO::Exception::Server> (C<DBI
Exception: ...>, as a refused statement is). The index does not exist
afterwards and the connection goes on working.

=back

Not measured: Firebird 3 and 4, and anything with another transaction
writing to the table at the time.

=head1 ATTRIBUTES

=head2 schema

A connected L<DBIO::Schema> instance using the L<DBIO::Firebird> component.
Required. (Inherited from L<DBIO::Deploy::Base>.)

=head1 METHODS

=head2 _check_before_apply

    $self->_check_before_apply($diff);

The driver's checks of L<DBIO::Deploy::Base/apply> (core ADR 0080), run for a
released diff before its first statement. C<apply> and C<upgrade> are
L<DBIO::Deploy::Base>'s as they are: the guard for destructive and lossy
operations (C<allow_destructive>; L<DBIO::Firebird::Diff::Column/lossy> says
which column changes need it), C<dry_run>, and the statements run through its
C<_execute_diff>.

The hook renders the whole diff first (a refused column change or table-view
change dies here, and a refusal of the diff itself comes before one that needs
the rows), then looks at the rows of the live tables with
L</_refuse_unfillable>. C<dry_run> checks nothing and asks the server nothing.

=head2 _refuse_unfillable

    $self->_refuse_unfillable($diff, $dbh);

Looks at the rows of the live tables before the first statement runs and
refuses -- a L<DBIO::Exception> naming table and column, every such column in
one message -- what the Firebird server would answer half way through the
diff (measured on Firebird 5.0.4):

=over 4

=item * a C<NOT NULL> column without a default (or with C<DEFAULT NULL>) that
        the diff adds to a table that holds rows: the server has no value for
        the rows already there. A column with a default is not refused (the
        server fills the rows with it), nor an identity column (its own rule,
        L<DBIO::Firebird::Diff::Column/COLUMN CHANGES THE SERVER REFUSES>);

=item * a column that becomes C<NOT NULL> in a table that has a C<NULL> in it
        (I<Cannot make field NOT NULL because there are NULLs present>).

=back

An empty table, and a table with no C<NULL> in the column, pass: nothing is
refused that the server takes. The ops before the failing one in the diff are
applied by then and an upgrade would stand half done, which is why the rows
are asked first.

=head1 SEE ALSO

=pod

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
