package DBIO::Sybase::Deploy;
# ABSTRACT: Deploy and upgrade Sybase ASE schemas via test-deploy-and-compare

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Deploy::Base::TempDatabase';

use Scope::Guard ();
use Time::HiRes ();

use DBIO::Exception ();

use DBIO::Sybase::Diff;
use DBIO::Sybase::Introspect;
use DBIO::Sybase::DDL;
use DBIO::Sybase::Quote ();


# Class-name hooks consumed by DBIO::Deploy::Base.
sub _ddl_class       { 'DBIO::Sybase::DDL' }
sub _introspect_class { 'DBIO::Sybase::Introspect' }
sub _diff_class      { 'DBIO::Sybase::Diff' }

# --- temp-database glue (engine-specific) ---------------------------------

# The n of the name: two temp databases of one process in the same minute
# (one left behind by a refused DROP, karr k75) must not share a name.
my $temp_db_serial = 0;

# Create a uniquely-named temp database and return its name. CREATE DATABASE
# cannot run inside a transaction, so the handle must have AutoCommit; one
# without it is refused before anything runs, and its transaction is left alone
# (karr k96, _require_autocommit).
#
# It is created at the size the schema to be deployed needs, or at temp_db_size
# (karr k69, see "The size of the temporary database" above); a server without
# the room for it (Msg 1810) is reported by that size.
#
# The database is handed on only with 'abort tran on log full' set (karr k69,
# see "A schema too large for the temporary database" above). One the option
# could not be set on is dropped here -- core has not heard its name yet and
# would never drop it -- and the error raised; if the drop fails too, the error
# says which database stayed, since nothing else will.
sub _create_temp_db {
  my ($self, $dbh) = @_;
  # At most 30 characters, ASE's limit for a database name (Msg 103): the time
  # is in minutes, not seconds, so that a seven-digit pid and a serial up to
  # 999 still fit (karr k97). The serial is what makes the name unique.
  my $name = $self->temp_db_prefix . $$ . '_' . int(time() / 60) . '_' . ++$temp_db_serial;

  $self->_require_autocommit($dbh, '_create_temp_db');
  my $size = $self->_temp_db_size_to_create($dbh);
  $self->_in_master($dbh, sub {
    unless (eval { $dbh->do("CREATE DATABASE $name ON default = '$size'"); 1 }) {
      my $error = $@;
      die $error unless ( $dbh->err // 0 ) == 1810 or $error =~ /\bnumber=1810\b|\bMsg 1810\b/;
      die ref($self) . ": the server has no room for the temporary database $name "
        . "at the size of $size asked for it (Msg 1810) -- make room on the default "
        . "device(s), or set temp_db_size to a size that fits:\n$error";
    }
    return if eval { $self->_abort_tran_on_log_full($dbh, $name); 1 };
    my $error = $@;
    eval { $self->_drop_temp_db($dbh, $name); 1 }
      or $error = "$error\nThe temporary database $name was left on the server: $@";
    die $error;
  });
  return $name;
}


sub temp_db_size { $_[0]->{temp_db_size} }

# The size CREATE DATABASE is sent, as 'NNM' text: temp_db_size as given, or
# the calculation. The server is asked only for the calculation.
sub _temp_db_size_to_create {
  my ($self, $dbh) = @_;

  if (defined( my $given = $self->temp_db_size )) {
    $given =~ /\A([0-9]+)([kmgt]?)\z/i
      or die ref($self) . ": temp_db_size '$given' is not a size: a whole number "
        . "and optionally K, M, G or T (28M, 1G; a number alone is megabytes)\n";
    return $1 . ( $2 ? uc $2 : 'M' );
  }

  # The page size of the server and the pages model has, in all and in use:
  # model is what a new database is copied from, and no database is smaller.
  my ($page, $model_total, $model_used) = $dbh->selectrow_array(
    'SELECT @@maxpagesize, SUM(size), '
  . 'SUM(size - curunreservedpgs(dbid, lstart, unreservedpgs)) '
  . "FROM master..sysusages WHERE dbid = db_id('model')"
  );
  die ref($self) . ": could not read the page size and the size of model from the server\n"
    unless $page && $model_total;

  my ($tables, $indexes) = $self->_temp_db_objects($self->schema);
  return $self->_temp_db_megabytes($tables, $indexes, $page, $model_total, $model_used // 0) . 'M';
}

# (tables, other indexes) the DDL of $schema writes: the objects that take
# space. What DBIO::Sybase::DDL leaves out is left out here -- a view, a source
# whose name is not a plain table, a table a second source maps to again -- and
# the indexes are those it writes: a unique column, a unique constraint, a
# declared index, none of them a second time over the columns of one written.
# The primary key is not among them; a table is counted with its key (below).
# Over-counting is safe, under-counting is the hang this class was fixed of.
sub _temp_db_objects {
  my ($class, $schema) = @_;
  my ($tables, $indexes, %seen_table) = (0, 0);

  for my $source_name (sort $schema->sources) {
    my $source = $schema->source($source_name);
    next if $source->isa('DBIO::ResultSource::View');
    my $table_name = $source->name;
    if (ref $table_name eq 'SCALAR') {
      $table_name = $$table_name;
      next if $table_name =~ /\s|\(/;
    }
    next if ref $table_name || $seen_table{$table_name}++;
    $tables++;

    my @pk_cols = $source->primary_columns;
    my %written = @pk_cols ? ( join("\0", @pk_cols) => 1 ) : ();
    my %unique  = @pk_cols ? ( join("\0", sort @pk_cols) => 1 ) : ();

    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      next unless $info->{is_unique} || $info->{is_single_unique_key};
      $unique{$col_name} = $written{$col_name} = 1;
      $indexes++;
    }

    my %uniques = $source->unique_constraints;
    for my $uname (sort keys %uniques) {
      next if $uname eq 'primary';
      my @cols = @{ $uniques{$uname} };
      next if !@cols || $unique{ join "\0", sort @cols }++;
      $written{ join "\0", @cols } = 1;
      $indexes++;
    }

    my %named = map { $_ => 1 } keys %uniques;
    for my $decl ($source->index_declarations_for('sybase', [])) {
      my @cols = @{ $decl->{columns} };
      next if $written{ join "\0", @cols };
      next if $named{ $decl->{name} };
      $written{ join "\0", @cols } = 1 if $decl->{unique};
      $indexes++;
    }
  }
  return ($tables, $indexes);
}

# The size in MB (a multiple of 4, the allocation unit of the server) of a
# database that holds $tables tables and $indexes further indexes, on a server
# with pages of $page bytes whose model has $model_total pages, $model_used of
# them in use. Measured on ASE 16.0 SP02 (16K pages): a table, its primary key
# and every further index take an extent of 8 pages each, and what is left of
# the schema (system tables, the log) took 45 more pages for 36 tables; the
# calculation (2 * tables + indexes) * 8 hit 688 of the 733 pages that schema
# needed, so a quarter and 64 pages are added to it. A database is copied from
# model, which is therefore in use already, and is never smaller than it.
sub _temp_db_megabytes {
  my ($class, $tables, $indexes, $page, $model_total, $model_used) = @_;
  my $schema_pages = ( 2 * $tables + $indexes ) * 8;
  my $pages = $schema_pages + int( $schema_pages / 4 + 0.999 ) + 64 + $model_used;
  $pages = $model_total if $pages < $model_total;

  my $unit = 4 * 1024 * 1024;
  return int( ( $pages * $page + $unit - 1 ) / $unit ) * 4;
}

# Set 'abort tran on log full' on the database $name; $dbh is in master and
# outside a transaction, which sp_dboption insists on (Msg 17428, Msg 17260).
# The procedure runs the checkpoint that puts the option into effect itself.
# It reports that and the option in two messages of severity 10, which
# DBD::Sybase prints as warnings unless the handle's syb_err_handler takes
# them: the slot is borrowed for the statement, everything above severity 10
# keeps going to the handler it displaced, and the Scope::Guard puts that one
# back also when the statement dies (the pattern of Storage::ASE::_execute_sth).
# Then the option is looked at (status2 & 1 in sysdatabases): a database
# without it is one a deploy can hang in for good, so a procedure that merely
# returned is not taken for an answer.
sub _abort_tran_on_log_full {
  my ($self, $dbh, $name) = @_;

  my $old = $dbh->{syb_err_handler};
  $dbh->{syb_err_handler} = sub { $_[1] > 10 ? ( $old ? $old->(@_) : 1 ) : 0 };
  my $restore = Scope::Guard->new(sub { $dbh->{syb_err_handler} = $old });

  $dbh->do("EXEC sp_dboption '$name', 'abort tran on log full', true");

  my ($set) = $dbh->selectrow_array(
    "SELECT status2 & 1 FROM master..sysdatabases WHERE name = '$name'"
  );
  die ref($self) . ": could not set 'abort tran on log full' on the temporary database $name"
    unless $set;
  return 1;
}

# Drop the temp database. ASE refuses that with Msg 3702 while anything is in
# it, which is over by itself (see "The temporary database is dropped more than
# once if need be" above), and core catches whatever this dies of: one refusal
# would leave the database on the server and nobody would hear of it. So Msg
# 3702, and no other error, is answered by trying again -- _drop_in_use_tries
# times in all, _drop_in_use_wait seconds apart, from master throughout
# (karr k74). After the last try the server's error propagates as before.
sub _drop_temp_db {
  my ($self, $dbh, $name) = @_;
  $self->_require_autocommit($dbh, '_drop_temp_db');
  $self->_in_master($dbh, sub {
    my $tries = $self->_drop_in_use_tries;
    while (1) {
      return if eval { $dbh->do("DROP DATABASE $name"); 1 };
      my $error = $@;
      die $error unless ( $dbh->err // 0 ) == 3702 and --$tries > 0;
      Time::HiRes::sleep($self->_drop_in_use_wait);
    }
  });
  return 1;
}

# CREATE/DROP DATABASE do not run in a transaction on ASE, and ending the
# caller's transaction (COMMIT, or switching AutoCommit on, which DBI commits
# for) is not these methods' to do (karr k96). So: refuse, first thing.
sub _require_autocommit {
  my ($self, $dbh, $method) = @_;
  return 1 if $dbh->{AutoCommit};
  DBIO::Exception->throw(ref($self) . "::$method needs a handle with AutoCommit: "
    . "CREATE DATABASE and DROP DATABASE do not run in a transaction on ASE, and "
    . "$method does not commit a transaction that is not its own");
}

# Ten seconds in all.
sub _drop_in_use_tries { 40 }
sub _drop_in_use_wait  { 0.25 }

# Run $code with $dbh's current database switched to master, then switch it
# back -- also when $code dies (karr k46). ASE refuses CREATE DATABASE from any
# other database (Msg 1809 "CREATE DATABASE must be preceded by a 'USE master'
# command", met live on ASE 16.0 SP02), and a database cannot be dropped from
# inside itself. $dbh is the live storage's handle: after the temp database is
# dropped, core's _build_target_model hands it on to introspect the live side
# and apply() runs through it, so leaving it in master would read and alter
# master instead of the target. The guard is created only after the switch
# succeeded, so a failed USE master restores nothing it did not change.
sub _in_master {
  my ($self, $dbh, $code) = @_;
  my ($orig) = $dbh->selectrow_array('SELECT db_name()');
  $dbh->do('USE master');
  my $restore = Scope::Guard->new(sub { $dbh->do("USE $orig") });
  return $code->();
}

# DBD::Sybase names the database with database=; the core fallback appends
# dbname=, which DBD::Sybase does not read, so a DSN without a database would
# connect the temp deploy to the login's default database and create the
# desired schema THERE. Replace database= in place, or append it.
sub _temp_dsn {
  my ($self, $dsn, $temp_db) = @_;
  return $dsn if $dsn =~ s/\bdatabase=[^;]*/database=$temp_db/i;
  return $dsn =~ /:$/ ? "${dsn}database=$temp_db" : "$dsn;database=$temp_db";
}




sub _check_before_apply {
  my ($self, $diff) = @_;
  $self->SUPER::_check_before_apply($diff);
  $self->_refuse_nulls($diff, $self->_dbh);
  return;
}

# A column that becomes NOT NULL in a table that holds a NULL in it is Msg 515
# half way through the batch, after the statements before it were applied and
# with no way back (the DDL is not transactional, see above). Refuse it before
# the first statement, naming table and column (karr k97). A table without a
# NULL in the column passes.
sub _refuse_nulls {
  my ($self, $diff, $dbh) = @_;
  for my $op (@{ $diff->operations }) {
    next unless $op->isa('DBIO::Sybase::Diff::Column::Alter');
    my ($from, $to) = ($op->from // {}, $op->to);
    next unless $to->{not_null} && !$from->{not_null};
    my ($table, $column) = ($op->table, $to->{column_name});
    my ($nulls) = $dbh->selectrow_array(sprintf
      'SELECT COUNT(*) FROM %s WHERE %s IS NULL',
      DBIO::Sybase::Quote::quote_ident($table), DBIO::Sybase::Quote::quote_ident($column));
    next unless $nulls;
    DBIO::Exception->throw(sprintf
      'DBIO::Sybase: table %s, column %s: making the column NOT NULL is refused: '
      . 'table %s holds rows where it is NULL (Msg 515), and nothing was sent',
      $table, $column, $table);
  }
  return;
}




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Deploy - Deploy and upgrade Sybase ASE schemas via test-deploy-and-compare

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::Sybase::Deploy> orchestrates schema deployment and upgrades for
Sybase ASE using the test-deploy-and-compare strategy.

For upgrades it:

=over 4

=item 1. Introspects the live database from the ASE system catalog

=item 2. Deploys the desired schema (from DBIO classes) to a temporary database

=item 3. Introspects the temporary database the same way

=item 4. Computes the diff between the two models using L<DBIO::Sybase::Diff>

=back

=head2 Transactional DDL -- not used, and not merely unavailable

L<DBIO::Sybase::Storage::ASE> declares C<< _use_transactional_ddl(0) >>, so
L<DBIO::Deploy::Base/_execute_ddl> never brackets this driver's DDL in
C<< $storage->txn_do >> and core emits its one-time notice,
S<C<non-transactional DDL on DBIO::Sybase::Deploy>>. The notice is correct and
is not a defect to be silenced.

What ASE does here is not what the shared description of that notice suggests.
It has no implicit C<COMMIT> on DDL: whether C<create table> may sit in a
multi-statement transaction is the per-database C<ddl in tran> option, which is
off unless a system administrator turned it on for that database, and with it
off the server B<rejects> the statement rather than committing around it. A
capability is one class-level answer given before any connection, so the only
answer true on every ASE is C<0>; the reasoning, the manual it comes from and
what a runtime probe would and would not buy are written out above the
declaration in L<DBIO::Sybase::Storage::ASE>.

For L</apply> and L</install> that means: core splits C<< $diff->as_sql >> (or
the install DDL) on C<;>, drops comment-only fragments, and runs the rest
through C<< $dbh->do >> on the live connection one after another, each
standing on its own as the connection's C<AutoCommit> lets it. A failure part
way therefore leaves everything before it applied. Nothing here is subtle
about that: an index change renders as C<DROP INDEX t.i> followed by
C<< CREATE UNIQUE INDEX i ON t (...) >>, two fragments, and a failure between
them leaves the index dropped and not rebuilt. Recovery is to re-run
L</upgrade> -- L</diff> is recomputed against live state, so the second run
picks up only what is left.

The temporary database is unaffected either way. Its schema is deployed
through a handle this Deploy opened itself, which core leaves unbracketed
whatever the capability says, and its C<CREATE DATABASE> / C<DROP DATABASE>
never reach C<_execute_ddl> at all -- C<_create_temp_db> and
C<_drop_temp_db> issue them directly on a handle with C<AutoCommit>, because
ASE forbids those two inside a transaction unconditionally (ADR 0005). Both
also run from C<master> -- ASE refuses C<CREATE DATABASE> anywhere else
(Msg 1809) -- and the handle is switched back to the database it was in
afterwards, also when the statement fails, because it is the live handle the
rest of L</diff> and L</apply> go on to use. A failed temp deploy is recovered
by dropping the whole database.

Neither method ends a transaction that is not its own. Given a
handle whose C<AutoCommit> is off, C<_create_temp_db> and C<_drop_temp_db>
refuse with a L<DBIO::Exception> naming the method and the reason, before any
statement runs -- no C<COMMIT>, no C<USE master>, no query, no change to the
handle's error handler -- so the transaction stands as it was. They neither
send C<COMMIT> nor switch C<AutoCommit> on (which in DBI commits an open
transaction as well); the caller hands them a handle with C<AutoCommit>.

=head2 The temporary database is dropped more than once if need be

ASE refuses C<DROP DATABASE> while anything is in the database, with Msg 3702
("Cannot drop or replace the database '...' because it is currently in use."
-- live, ASE 16.0 SP02). L</diff> drops its temporary database the moment core
has closed the session the schema was deployed through, and a client session
is not all that can be in a database: the server's own checkpoint process was
observed inside one that no client was connected to. What is in the way then
leaves by itself. So C<_drop_temp_db> answers Msg 3702, and no other error, by
trying again -- 40 tries in all, a quarter of a second apart, which is ten
seconds (C<_drop_in_use_tries>, C<_drop_in_use_wait>).

A database still in use after that stays where it is. C<_drop_temp_db> dies of
the server's error, L<DBIO::Deploy::Base::TempDatabase/_build_target_model>
catches it, and L</diff> returns its result all the same: nothing reports the
database left behind. It is named C<< _dbio_tmp_<pid>_<time>_<n> >> (C<time>
is in minutes since the epoch, which keeps the name within the 30 characters ASE
allows; C<n> counts the temporary databases of the process, so two in the same
minute differ) and is dropped by hand, from C<master>:

    use master
    drop database _dbio_tmp_12345_29856533_1

=head2 The size of the temporary database

The temporary database is made with the size the schema to be deployed into it
needs, not with the server's C<default database size> -- the size of
C<model>, 24 MB on the server this was measured on (ASE 16.0 SP02, 16K pages),
with 686 of its 1536 pages free, which a schema of 38 tables and 15 further
indexes (the whole of L<DBIO::Test::Schema>) did not fit into. Nothing about it
is asked of the administrator: C<CREATE DATABASE> is sent with
C<ON default = 'NNM'>, the size calculated as follows.

A table takes an extent of 8 pages, and so do its primary key and every further
index (measured). So the schema needs

    (2 * tables + other indexes) * 8 pages

where the tables and the indexes are those L<DBIO::Sybase::DDL> writes -- a view
is no table, a table two sources map to counts once, and a unique column, a
unique constraint and a declared index are one index each, not again where they
repeat the columns of one already written. What the formula leaves out (system
tables, the log) was 45 pages on 36 tables and the formula alone hit 688 of the
733 pages needed, so a quarter and 64 pages are added. The pages C<model> has in
use are in the new database from the start and are added, the sum is taken in
the server's page size (C<@@maxpagesize>), rounded up to the next 4 MB, and the
database is never smaller than C<model>. DBIO::Test::Schema, measured: 38
tables and 15 other indexes, 32 MB, of which the install used 783 pages and
left 415 free.

=head3 Setting the size

The attribute C<temp_db_size> replaces the calculation (L</temp_db_size>): given, the database
has that size, the server is not asked about C<model>, and the size is not a
minimum -- one that is too small is created as it is and the deploy dies of the
errors below. A server without the room for the database (Msg 1810: the default
device has less free than the size, or none) is not a deploy that can go on:
C<_create_temp_db> dies naming the size it asked for, C<temp_db_size>, and the
server's message. Room is made on the server (C<disk init>, C<sp_diskdefault>),
which this class does not do.

=head2 A schema too large for the temporary database

What becomes of a schema that does not fit is a database option. A database
copied from C<model> does not have C<abort tran on log full>, and without it
ASE does not refuse the statement that finds the database full: it suspends
the session until somebody frees log space (C<master..sysprocesses> shows it
C<sleeping>, with the command C<LOG SUSPEND>). In a database that exists for
one deploy nobody does, so L</diff> and L</upgrade> never returned -- without
an error, and with nothing on the client to end it. C<_create_temp_db>
therefore sets the option, from C<master>, before anything is deployed:

    exec sp_dboption '_dbio_tmp_12345_29856533_1', 'abort tran on log full', true

The procedure runs the checkpoint that puts the option into effect itself.
C<_create_temp_db> then reads C<sysdatabases> to see that it is set; a
database it could not be set on is dropped again and the error raised, and
nothing is deployed into it.

With the option, the statement that finds the database full dies of the
server's error, and L</diff> with it:

    Server message number=1105 severity=17 ... text=Can't allocate space for
    object 'syslogs' in database '_dbio_tmp_12345_29856533_1' because
    'logsegment' segment is full/has no free extents. If you ran out of space
    in syslogs, dump the transaction log. Otherwise, use ALTER DATABASE to
    increase the size of the segment.

Msg 7412 ("Space available in segment 'logsegment' has fallen critically low
in database '...'") may stand before it, and a second Msg 1105 and Msg 2761,
naming the table that was being created, after it. The database it names is
the temporary one, and its advice does not apply: by the time the error
arrives that database has been dropped. What the error means is that the
desired schema needs more room than the temporary database has -- with the
calculated size only where the schema is larger than the calculation allows for,
and with a C<temp_db_size> set too small as a matter of course. The live handle is back in its own database, and the live database was
only read -- L</upgrade> dies in L</diff>, before L</apply> (live, ASE 16.0
SP02; C<t/71-temp-db-log-full-live.t>).

=head2 Data-copying ALTER TABLE

Dropping a column, changing a column's stored type (C<INT> to C<BIGINT>) and
adding a C<NOT NULL> column make ASE copy the table, and in a database without
the C<select into/bulkcopy/pllsort> option ASE refuses that with Msg 11052
("Neither the 'select into' nor the 'full logging for alter table' database
options are enabled for database '...'. ALTER TABLE with data copy cannot be
done." -- live, ASE 16.0 SP02). The C<full logging for alter table> option the
message also names takes effect only in a database whose log has its own
device; in one with mixed data and log segments -- what a plain
C<CREATE DATABASE> gives -- ASE sets it and ignores it. The option that works
on every database is C<select into/bulkcopy/pllsort>, set by a system
administrator from C<master> and followed by a checkpoint of the database:

    use master
    exec sp_dboption 'mydb', 'select into/bulkcopy/pllsort', true
    use mydb
    checkpoint

It is a precondition of L</apply> and L</upgrade> for any diff containing such
a change, and it is the administrator's to set: it permits minimally logged
operations, after which the transaction log cannot be dumped until the next
full database dump. This class neither sets it nor checks for it.
Without it, L</apply> runs the diff up to the first data-copying statement,
which fails; since the run is not transactional (above), everything before
that statement stays applied. After the option is set, L</upgrade> recomputes
the diff against that state and applies the rest. Which statements copy is
listed in L<DBIO::Sybase::Diff::Column/DATA-COPYING ALTERS NEED A DATABASE
OPTION>.

=head1 ATTRIBUTES

=head2 temp_db_size

    DBIO::Sybase::Deploy->new(schema => $schema, temp_db_size => '64M');

The size of the temporary database, as C<CREATE DATABASE ... ON default = 'NNM'>
takes it: a whole number and optionally the unit C<K>, C<M>, C<G> or C<T> (a
number alone is megabytes). Not given, the size is calculated from the schema
(L</The size of the temporary database>). Given, it is the size of the
database: the calculation does not run, the server is not asked about C<model>,
and the size is not a minimum -- one smaller than the schema needs is created as
it is, and the deploy dies of Msg 1105. Anything else is refused.

=head1 METHODS

=head2 install

    $deploy->install;

Generates DDL via L<DBIO::Sybase::DDL/install_ddl> and executes each
statement against the connected database. Suitable for fresh installs.
Inherited from L<DBIO::Deploy::Base>.

=head2 diff

    my $diff = $deploy->diff;

Computes the difference between the live database and the desired state.
Deploys the desired schema to a temporary database, introspects both,
and returns a L<DBIO::Sybase::Diff> object.

=head2 _check_before_apply

The Sybase check of a diff against the live tables, run by
L<DBIO::Deploy::Base/apply> (and so by L<DBIO::Deploy::Base/upgrade>) once the
diff is released and before its first statement: a column that becomes C<NOT
NULL> in a table that holds a C<NULL> in it is refused with a
L<DBIO::Exception> naming table and column (Msg 515 otherwise, half way
through the batch). Nothing has been executed when it throws. C<diff>,
C<as_sql> and C<summary> stay reads and do not look.

=head2 apply

Inherited from L<DBIO::Deploy::Base/apply>, with its C<allow_destructive> and
C<dry_run> arguments: a diff with a drop or a possibly lossy column change
(L<DBIO::Sybase::Diff::Column/lossy>) runs with C<< allow_destructive => 1 >>
only. The Sybase check is L</_check_before_apply>.

=head2 upgrade

    my $diff = $deploy->upgrade;
    my $diff = $deploy->upgrade(allow_destructive => 1);

Inherited from L<DBIO::Deploy::Base/upgrade>: L</diff> then L</apply>, with the
same arguments. Returns the diff object if changes were applied, or C<undef>
if the database was already up to date.

=head1 SEE ALSO

=pod

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
