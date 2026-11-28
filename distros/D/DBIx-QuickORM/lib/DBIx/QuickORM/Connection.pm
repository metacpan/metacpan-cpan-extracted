package DBIx::QuickORM::Connection;
use strict;
use warnings;

our $VERSION = '0.000031';

use Carp qw/croak confess/;
use Scalar::Util qw/blessed refaddr weaken/;

use DBIx::QuickORM::Dialect();
use DBIx::QuickORM::Exception::DB();
use DBIx::QuickORM::LookupTable();
use DBIx::QuickORM::Map();
use DBIx::QuickORM::Txn();

use Object::HashBase qw{
    <dbh
    <db_map
    <time_zone
    <datetime_parsers
    <retain_cache
    <enforce_canon
    <isolation
    <dialect
    <namespace
    <pid
    +lookup
    <txns
    +txn_count
    +busy
    +statements
};

# Connections with an async query pending, so a forked child can release them at exit (see END).
my %PENDING;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Connection - One database handle and the state tied to it.

=head1 DESCRIPTION

A Connection holds one database handle and everything that must be reset when
that handle is replaced: its dialect, its namespace, the pid that opened it,
the open transactions (L<DBIx::QuickORM::Txn>), and the lookup table of canon
rows (L<DBIx::QuickORM::LookupTable>). The ORM replaces the whole Connection
at once, as it does in a forked child. The new one starts with no transaction
and an empty lookup table.

It implements the ORM's CRUD operations on plain row data and knows nothing of
the ORM: it returns hashrefs, which L<DBIx::QuickORM> wraps. A row object
given is read through its C<row_data>. The rules shared by every CRUD
operation (row data, C<raw>, value markers, what comes back with and without
C<RETURNING>) are in L<DBIx::QuickORM/"CRUD operations">. The entries here add
what the Connection itself does.

Construction prepares the handle:

=over 4

=item *

C<RaiseError> must be on. C<PrintError> is turned off and
C<AutoInactiveDestroy> on.

=item *

C<AutoCommit> must be on, with no transaction open: the ORM manages
transactions.

=item *

Every database error on the handle is thrown as a
L<DBIx::QuickORM::Exception::DB>, classified by the dialect.

=item *

The dialect sets up the session.

=item *

The connection must have a current schema or database, or construction
croaks.

=back

Rows read go through the lookup table's C<ingest>. Rows written replace its
entry.

The single-row CRUD operations build their SQL once per table and set of fields
and run it through C<prepare_cached>. SQL holding an C<sql()> or C<binary()>
marker, C<insert_many>, and queries built elsewhere are prepared each time.

In a forked child, a Connection that is freed, or still held at exit, lets go
of its inherited handle (C<release_inherited>), so the parent's session
survives.

=head1 SYNOPSIS

    my $conn = $orm->connection;    # the ORM's current Connection (a forked child gets a new one)

    my $dialect = $conn->dialect;
    my $schema  = $conn->namespace;
    my $lookup  = $conn->lookup;

=head1 ATTRIBUTES

=over 4

=item $dbh = $conn->dbh

The database handle. Required.

=item $map = $conn->db_map

The L<DBIx::QuickORM::Map>. When none is given the database is scanned into a
new one, which the ORM then adjusts in place.

=item $tz = $conn->time_zone

The session time zone, C<UTC> unless given.

=item \@parsers = $conn->datetime_parsers

The ORM's C<datetime_parsers>, for the DateTime type. Empty unless given.
Checked as the ORM's C<new> describes. C<set_datetime_parsers> changes it.

=item $bool = $conn->retain_cache

Passed to the lookup table as C<retain>. 0 unless given.

=item $bool = $conn->enforce_canon

The default C<enforce_canon> for C<update_row> and C<delete_row> outside a
transaction. 1 unless given. C<set_enforce_canon> changes it.

=item $level = $conn->isolation

The isolation level a root transaction opens at when C<txn> names none, in
lower case: a level C<txn> takes, or C<'server'>. Undef unless given: then
C<'read committed'> where the dialect C<supports_isolation>, otherwise
C<'server'>. An unknown level croaks.

=item $dialect = $conn->dialect

The L<DBIx::QuickORM::Dialect> object for the handle, holding the server
version.

=item $ns = $conn->namespace

The current schema or database, from the dialect.

=item $pid = $conn->pid

The process that opened the connection.

=item \@txns = $conn->txns

The open transactions, outermost first, as L<DBIx::QuickORM::Txn> objects
(held weakly). Empty outside a transaction.

=back

=cut

sub init {
    my $self = shift;

    my $dbh = $self->{+DBH};
    croak "The connection did not produce a DBI database handle" unless blessed($dbh) && $dbh->isa('DBI::db');
    croak "The database handle must have RaiseError on"          unless $dbh->{RaiseError};
    croak "The database handle must have AutoCommit on and no transaction open; the ORM manages transactions"
        unless $dbh->{AutoCommit};

    $self->{+TIME_ZONE} //= 'UTC';
    $self->{+DATETIME_PARSERS} = exists($self->{+DATETIME_PARSERS}) ? $self->_check_datetime_parsers($self->{+DATETIME_PARSERS}) : [];
    $self->{+RETAIN_CACHE}  //= 0;
    $self->{+ENFORCE_CANON} //= 1;
    $self->{+ISOLATION} = $self->_isolation($self->{+ISOLATION}) if defined $self->{+ISOLATION};

    $dbh->{PrintError}          = 0;
    $dbh->{AutoInactiveDestroy} = 1;

    my $dialect = $self->{+DIALECT} = DBIx::QuickORM::Dialect->for_dbh($dbh);
    $dbh->{HandleError} = $self->_error_handler($dialect, $self->{+TXNS} = []);
    $dialect->init_session($dbh, $self->{+TIME_ZONE});

    my $ns = $self->{+NAMESPACE} = $dialect->namespace($dbh);
    croak "The connection has no current schema or database; select one in the DSN" unless defined $ns;

    $self->{+DB_MAP} //= DBIx::QuickORM::Map->new(tables => $dialect->scan($dbh));
    $self->{+PID} = $$;
}

=head1 PUBLIC METHODS

=over 4

=item $conn->set_enforce_canon($bool)

Changes C<enforce_canon>. Each C<update_row> and C<delete_row> reads it when
it runs.

=item $conn->set_datetime_parsers(\@parsers)

Replaces C<datetime_parsers> with a copy of C<@parsers>, checked as the ORM's
C<new> checks them: it loads each class, and croaks on a bad parser.

Values read after the call use the new parsers. A DateTime field read before
the call keeps the parsers it was read with, even while still unparsed.

=back

=cut

sub set_enforce_canon { $_[0]->{+ENFORCE_CANON} = $_[1] }

sub set_datetime_parsers {
    my $self = shift;
    my ($parsers) = @_;
    $self->{+DATETIME_PARSERS} = $self->_check_datetime_parsers($parsers);
}

=over 4

=item $lookup = $conn->lookup

The Connection's L<DBIx::QuickORM::LookupTable>, built on first use.

=back

=cut

sub lookup {
    my $self = shift;
    return $self->{+LOOKUP} //= DBIx::QuickORM::LookupTable->new(db_map => $self->{+DB_MAP}, connection => $self, retain => $self->{+RETAIN_CACHE});
}

=over 4

=item $bool = $conn->is_canon($table, $row_or_data)

True when the row data (or a row object's C<row_data>) is the lookup table's
entry for its primary key. Croaks when the primary key cannot be determined.

=back

=cut

sub is_canon {
    my $self = shift;
    my ($table, $data) = @_;
    return $self->lookup->is_canon($table, $self->_row_data($data));
}

=over 4

=item $data = $conn->insert($table, \%fields, raw => $bool, as_given => $bool, void => $bool)

Inserts one row and returns its new row data, now the lookup table's entry.
Where the primary key comes from, C<as_given>, and the croaks, are as
L<DBIx::QuickORM/"CRUD operations"> describes for C<insert>.

Primary key fields left out may get generated values first (see
C<_generate_keys>). C<as_given> includes them.

A table without a primary key returns the C<RETURNING> row without storing it
in the lookup table.

With C<as_given>, C<RETURNING> names only the primary key fields, and the
result is never stored.

C<< void => 1 >> is what the ORM passes in void context: the row is inserted
without C<RETURNING>, nothing is stored or returned, and none of the primary
key croaks apply.

=back

=cut

my %INSERT_ARGS = map { $_ => 1 } qw/raw void as_given/;

sub insert {
    my $self = shift;
    my ($table, $fields, %params) = @_;

    $self->_check_params(insert => \%INSERT_ARGS, \%params);
    my $t      = $self->_table($table);
    my $values = $self->_row_data($fields);
    confess "insert() into '$table' needs at least one field" unless %$values;
    my $generated = $self->_generate_keys($t, $values);
    $values = {%{$self->deflate($table, $values, raw => $params{raw})}, %{$self->deflate($table, $generated)}};
    my @names = sort keys %$values;

    my $void      = $params{void};
    my $as_given  = $params{as_given};
    my $dialect   = $self->{+DIALECT};
    my $pk        = $t->{pk} && @{$t->{pk}} ? $t->{pk} : undef;
    my $returning = !$void   && ($pk || !$as_given) && $dialect->supports_returning_insert;
    my $given_pk  = $pk      && !grep { !defined($values->{$_}) || $self->_is_sql($values->{$_}) } @$pk;
    unless ($void || $returning) {
        confess "insert() into '$table' has nothing to return: the table has no primary key and the database cannot return the row; call it in void context" unless $pk || $as_given;
        confess "insert() into '$table' needs every primary key field, since the database cannot return a compound key it generates" if $pk && !$given_pk && @$pk > 1;
    }

    my ($places, $binds, $marked) = $self->_value_sql($values, @names);
    my $shape = $marked ? undef : join("\0" => 'insert', $table, ($returning ? ($as_given ? 'pk' : 'all') : ''), @names);
    my $sql   = $self->_statement(
        $shape,
        sub {
            my $sql = 'INSERT INTO ' . $dialect->quote_identifier($table) . ' (' . join(', ' => map { $dialect->quote_identifier($_) } @names) . ') VALUES (' . join(', ' => @$places) . ')';
            $returning ? $sql . $self->_returning_sql($table, $as_given ? $pk : undef) : $sql;
        }
    );
    my $sth = $self->_run($t->{fields}, $sql, $binds, undef, defined $shape);
    return if $void;

    my $data = $returning ? $self->_fetch($t->{fields}, $sth)->[0] : undef;
    if ($pk && !$data && $given_pk) {
        $data = $self->_plain({map { $_ => $values->{$_} } @$pk});
    }
    elsif ($pk && !$data) {
        # Only MySQL gets here (no RETURNING). DBD::MariaDB gives 0 when the insert
        # generated no key, and AUTO_INCREMENT never generates 0, so 0 is "none".
        my $id = $dialect->last_insert_id($self->{+DBH}, $table, $pk->[0]) or confess "insert() into '$table' did not give a value for the primary key '$pk->[0]', and the database generated none";
        $data = {$pk->[0] => $id};
    }

    my $lookup = $self->lookup;
    my $out;
    if ($as_given) {
        my %copy = map { $_ => $values->{$_} } grep { !$self->_is_sql($values->{$_}) } @names;
        $out = {%{$self->_plain(\%copy)}, %{$data // {}}};
    }
    else {
        $out = $pk ? $lookup->store($table, $data) : $data;
    }

    $lookup->mark_inserted($out);
    return $out;
}

=over 4

=item \@data = $conn->insert_many($table, \@rows, raw => $bool)

=item $count = $conn->insert_many($table, \@rows, count => 1, raw => $bool)

=item $conn->insert_many($table, \@rows, void => 1, raw => $bool)

Generates missing primary key values for each row as C<insert> does, then
inserts the rows in multi-row C<INSERT> statements, each holding as many rows
as the dialect's C<bind_limit> allows. The batching, the transaction around
it, and the croaks are as L<DBIx::QuickORM/"CRUD operations"> describes for
C<insert_many>.

It returns an arrayref of the new rows' row data, now the lookup table's
entries (a table without a primary key bypasses it). Without C<RETURNING> each
holds the primary key taken from the given values.

C<< count => 1 >> returns how many rows the database reports inserted
instead, and C<< void => 1 >> (what the ORM passes in void context) returns
nothing useful. Neither sends C<RETURNING> or stores anything.

An empty C<\@rows> sends nothing and returns an empty arrayref, or 0 with
C<count>.

The field list is checked once per call. Each value is deflated as
C<deflate> would, through C<_deflate_value>.

=back

=cut

my %INSERT_MANY_ARGS = map { $_ => 1 } qw/raw count void/;

sub insert_many {
    my $self = shift;
    my ($table, $rows, %params) = @_;

    $self->_check_params(insert_many => \%INSERT_MANY_ARGS, \%params);
    my $t = $self->_table($table);
    confess "insert_many() needs an arrayref of rows" unless ref($rows) eq 'ARRAY';
    my $returning = !$params{void} && !$params{count};
    return $returning ? [] : 0 unless @$rows;
    my @values = map { $self->_row_data($_) } @$rows;
    my @names  = sort keys %{$values[0]};
    confess "insert_many() into '$table' needs at least one field in each row" unless @names;

    for my $i (1 .. $#values) {
        my $v = $values[$i];
        confess "insert_many() into '$table' needs the same fields in every row, but row $i differs from the first" unless keys(%$v) == @names && !grep { !exists $v->{$_} } @names;
    }

    # The fields are checked once, and each value deflated as deflate() would, with its field record at hand.
    $self->_check_fields($table, @names);
    my ($fields, $raw) = ($t->{fields}, $params{raw});
    @values = map {
        my $v         = $_;
        my $generated = $self->_generate_keys($t, $v);
        my %out       = map { ($_ => $self->_deflate_value($table, $_, $fields->{$_}, $v->{$_}, $raw)) } @names;
        $out{$_} = $self->_deflate_value($table, $_, $fields->{$_}, $generated->{$_}) for keys %$generated;
        \%out;
    } @values;
    @names = sort keys %{$values[0]};

    my $dialect = $self->{+DIALECT};
    my $pk      = $t->{pk}   && @{$t->{pk}} ? $t->{pk} : undef;
    my $sql_ret = $returning && $dialect->supports_returning_insert;
    if ($returning && !$sql_ret) {
        confess "insert_many() into '$table' cannot return rows: the table has no primary key and the database cannot return them; pass count => 1 for how many went in" unless $pk;
        my @short = grep {
            my $v = $_;
            grep { !defined($v->{$_}) || $self->_is_sql($v->{$_}) } @$pk
        } @values;
        confess "insert_many() into '$table' cannot return rows unless every row carries its whole primary key, since the database cannot return the keys it generates; pass count => 1 for how many went in" if @short;
    }

    my $into    = 'INSERT INTO ' . $dialect->quote_identifier($table) . ' (' . join(', ' => map { $dialect->quote_identifier($_) } @names) . ') VALUES ';
    my @batches = $self->_batches(\@values, \@names);
    my $send    = sub {
        my ($count, @got) = (0);
        for my $batch (@batches) {
            my ($places, $binds) = @$batch;
            my $sth = $self->_run($t->{fields}, $into . join(', ' => @$places) . ($sql_ret ? $self->_returning_sql($table) : ''), $binds);
            if ($sql_ret) { push @got => @{$self->_fetch($t->{fields}, $sth)} }
            else          { $count += $sth->rows }
        }
        return $sql_ret ? \@got : $count;
    };

    my $own_txn = @{$self->{+TXNS}} ? $dialect->supports_savepoints : @batches > 1;
    my $out     = $own_txn          ? $self->txn($send)             : $send->();
    return $out unless $returning;

    # Without RETURNING each row is its primary key, taken from the given values.
    my @got = $sql_ret ? @$out : map {
        my $v = $_;
        $self->_plain({map { ($_ => $v->{$_}) } @$pk})
    } @values;

    my $lookup = $self->lookup;
    @got = map { $lookup->store($table, $_) } @got if $pk;
    $lookup->mark_inserted(@got);
    return \@got;
}

=over 4

=item $data = $conn->update_row($table, \%data, \%changes, %opts)

Updates one row, found by the primary key in the row data, and returns its new
row data, or undef when no row matched.

The new row data replaces the old in the lookup table, re-keyed when the
primary key changed. Undef leaves the lookup table alone. At least one change
is required. Setting a primary key field with C<sql()> croaks on a database
without C<RETURNING> for C<UPDATE>, since the new key could not be known.

The options C<enforce_canon>, C<cas>, and C<auto_cas> are as
L<DBIx::QuickORM/"CRUD operations"> describes for C<update_row>. Each C<cas>
field must be in the row data.

=back

=cut

my %UPDATE_ARGS = map { $_ => 1 } qw/enforce_canon cas auto_cas raw/;

sub update_row {
    my $self = shift;
    my ($table, $data, $changes, %params) = @_;

    $self->_check_params(update_row => \%UPDATE_ARGS, \%params);
    my $t = $self->_table($table);
    $data = $self->_row_data($data);
    confess "update_row() needs a hashref of at least one change" unless ref($changes) eq 'HASH' && %$changes;
    my @set = sort keys %$changes;

    my $pk = $self->_pk_values($table, $data, $params{raw});
    $self->_enforce_canon($table, $data, $params{enforce_canon});
    my $where = {%{$self->deflate($table, {$self->_cas_values($table, $data, $changes, \%params)}, raw => $params{raw})}, %$pk};
    $changes = $self->deflate($table, $changes, raw => $params{raw});

    my $dialect   = $self->{+DIALECT};
    my $returning = $dialect->supports_returning_update;
    my @sql_pk    = grep { $self->_is_sql($changes->{$_}) } keys %$pk;
    confess "update_row() cannot set the primary key of '$table' with sql() on a database without RETURNING for UPDATE, since the new key could not be known" if @sql_pk && !$returning;

    my ($where_sql, $where_binds, $where_marked) = $self->_where_sql($where);
    my ($places, $set_binds, $marked)            = $self->_value_sql($changes, @set);
    my $shape = $marked || $where_marked ? undef : join("\0" => 'update', $table, @set, $where_sql);
    my $sql   = $self->_statement(
        $shape,
        sub {
            my $sql = 'UPDATE ' . $dialect->quote_identifier($table) . ' SET ' . join(', ' => map { $dialect->quote_identifier($set[$_]) . " = $places->[$_]" } 0 .. $#set) . " WHERE $where_sql";
            $returning ? $sql . $self->_returning_sql($table) : $sql;
        }
    );
    my $sth = $self->_run($t->{fields}, $sql, [@$set_binds, @$where_binds], undef, defined $shape);

    my $new;
    if ($returning) {
        $new = $self->_fetch($t->{fields}, $sth)->[0] or return undef;
    }
    else {
        return undef unless $sth->rows > 0;
        $new = $self->_plain({map { $_ => exists($changes->{$_}) ? $changes->{$_} : $pk->{$_} } keys %$pk});
    }

    my $lookup = $self->lookup;
    $lookup->forget($table, $self->_plain($pk));
    $lookup->carry_inserted($data, $new);
    return $lookup->store($table, $new);
}

=over 4

=item $count = $conn->delete_row($table, \%data, enforce_canon => $bool, raw => $bool)

Deletes one row, found by the primary key in the row data, and returns how
many rows were deleted (0 or 1). Its lookup table entry is removed, and the
row data and that entry are marked deleted (see L<DBIx::QuickORM::LookupTable/Row state>).
C<enforce_canon> is as for C<update_row>.

=back

=cut

my %DELETE_ARGS = map { $_ => 1 } qw/enforce_canon raw/;

sub delete_row {
    my $self = shift;
    my ($table, $data, %params) = @_;

    $self->_check_params(delete_row => \%DELETE_ARGS, \%params);
    my $t = $self->_table($table);
    $data = $self->_row_data($data);
    my $pk = $self->_pk_values($table, $data, $params{raw});
    $self->_enforce_canon($table, $data, $params{enforce_canon});

    my ($where_sql, $where_binds, $marked) = $self->_where_sql($pk);
    my $sql = $self->_statement($marked ? undef : join("\0" => 'delete', $table, $where_sql), sub { 'DELETE FROM ' . $self->{+DIALECT}->quote_identifier($table) . " WHERE $where_sql" });
    my $sth = $self->_run($t->{fields}, $sql, $where_binds, undef, !$marked);

    $self->lookup->gone($table, $self->_plain($pk), $data);
    return $sth->rows;
}

=over 4

=item $data = $conn->refresh_row($table, $pk, cache => $bool, db => $bool, fields => \@fields, raw => $bool)

The canon row data for the primary key, or undef when there is no such row.
C<$pk> is the key in any form C<_pk_values> takes, so row data works and its
other fields are ignored. This is also C<find>.

C<fields> must be fields of the table. C<cache>, C<db>, and C<fields> are as
L<DBIx::QuickORM/"CRUD operations"> describes for C<refresh_row>: the lookup
table's entry when it holds every field asked for, otherwise those fields read
from the database and ingested.

A row the database no longer has is removed from the lookup table, and the
row data given and that entry are marked deleted.

=back

=cut

my %REFRESH_ARGS = map { $_ => 1 } qw/cache db fields raw/;

sub refresh_row {
    my $self = shift;
    my ($table, $data, %params) = @_;

    $self->_check_params(refresh_row => \%REFRESH_ARGS, \%params);
    my $t     = $self->_table($table);
    my $pk    = $self->_pk_values($table, $data, $params{raw});
    my $key   = $self->_plain($pk);
    my $cache = $params{cache} // 1;
    my $db    = $params{db}    // 1;
    confess "refresh_row() needs 'cache' or 'db' to be true" unless $cache || $db;

    my $fields = $params{fields};
    confess "'fields' must be an arrayref of field names" if defined($fields) && ref($fields) ne 'ARRAY';
    $self->_check_fields($table, @$fields)                if $fields;

    my %seen;
    my @select = $fields ? grep { !$seen{$_}++ } sort(@$fields, @{$t->{pk}}) : @{$self->_default_fields($table)};

    my $lookup = $self->lookup;
    if ($cache) {
        my $canon = $lookup->lookup($table, $key);
        return $canon if $canon && (!$db || !grep { !exists $canon->{$_} } @select);
    }
    return undef unless $db;

    my $dialect = $self->{+DIALECT};
    my ($where_sql, $where_binds, $marked) = $self->_where_sql($pk);
    my $sql = $self->_statement(
        $marked ? undef : join("\0" => 'select', $table, @select, $where_sql),
        sub {
            'SELECT ' . join(', ' => map { $dialect->quote_identifier($_) } @select) . ' FROM ' . $dialect->quote_identifier($table) . " WHERE $where_sql";
        }
    );

    my $row   = $self->_fetch($t->{fields}, $self->_run($t->{fields}, $sql, $where_binds, undef, !$marked))->[0];
    my $given = blessed($data) && $data->can('row_data') ? $data->row_data : ref($data) eq 'HASH' ? $data : undef;
    if ($row) {
        my $canon = $lookup->ingest($table, $row);
        $lookup->carry_inserted($given, $canon) if $given;
        return $canon;
    }

    $lookup->gone($table, $key, $given);
    return undef;
}

=over 4

=item \@rows = $conn->select($source, $sql, \@binds)

=item \%pending = $conn->select($source, $sql, \@binds, async => 1)

Runs SQL built elsewhere for a source (a L<DBIx::QuickORM::Role::Source>) and
returns every row as fetched.

Binds are C<[$name, $value]> pairs. The name (undef for none) is one of the
source's C<field_records>, which also decide how fetched columns are read.
Nothing is ingested here. The source's C<results> ingests the rows that
belong to a table.

With C<async>, on a dialect that C<supports_async>, the query is started
without waiting for it and a hash of three code references is returned:
C<ready> (true once the result has arrived), C<collect> (waits for the result
and returns the rows), and C<cancel> (gives up on the query). Call C<collect>
or C<cancel> once. A dialect without async queries croaks.

While the query is pending the Connection is busy: every query, CRUD operation,
and transaction statement that would send SQL croaks (a C<find> answered from
the cache does not), including an explicit C<rollback>.

A rollback forced by a block's exception, or by a L<DBIx::QuickORM::Txn>
going out of scope, cancels the query first. After that C<collect> throws and
C<cancel> does nothing.

=back

=cut

my %SELECT_ARGS = (async => 1);

sub select {
    my $self = shift;
    my ($source, $sql, $binds, %params) = @_;

    $self->_check_params(select => \%SELECT_ARGS, \%params);
    confess "select() needs a source (a DBIx::QuickORM::Role::Source)" unless blessed($source) && $source->DOES('DBIx::QuickORM::Role::Source');
    confess "'binds' must be an arrayref" if defined($binds) && ref($binds) ne 'ARRAY';

    my $fields = $source->field_records;
    $binds = $self->_resolve_binds($source, $binds);
    return $self->_fetch($fields, $self->_run($fields, $sql, $binds)) unless $params{async};

    my ($dbh, $dialect) = @{$self}{+DBH, +DIALECT};
    confess "The " . $dialect->name . " dialect has no async queries" unless $dialect->supports_async;
    my $sth = $self->_run($fields, $sql, $binds, $dialect->async_prepare_attrs);
    weaken($PENDING{refaddr($self)} = $self);

    # The statement is freed as soon as the query is over, before another can start beside it.
    my $done    = sub { undef $sth; delete $self->{+BUSY}; delete $PENDING{refaddr($self)} };
    my $pending = {
        ready   => sub { $sth ? $dialect->async_ready($dbh, $sth) : 1 },
        collect => sub {
            die "This async query was cancelled when the transaction it ran in was rolled back\n" unless $sth;
            my $rows;
            my $ok  = eval { $dialect->async_result($dbh, $sth); $rows = $self->_fetch($fields, $sth); 1 };
            my $err = $@;
            $done->();
            die $err unless $ok;
            return $rows;
        },
        cancel => sub {
            return unless $sth;
            my $ok  = eval { $dialect->cancel_async($dbh, $sth); 1 };
            my $err = $@;
            $done->();
            die $err unless $ok;
        },
    };
    $self->{+BUSY} = {sth => $sth, cancel => $pending->{cancel}};
    return $pending;
}

=over 4

=item $count = $conn->bulk_write($source, $sql, \@binds)

=item $count = $conn->bulk_write($source, $sql, \@binds, mark_deleted => 1, keys => [$select_sql, \@select_binds])

Runs an C<UPDATE> or C<DELETE> built elsewhere for a table source and returns
the number of rows the database reports. Binds are as for C<select>.

It cannot tell which rows changed, so it clears the table from the lookup
table's top level and, inside a transaction, from its outside level. A source
without a table croaks.

With C<mark_deleted>, C<$sql> must be a C<DELETE>. The deleted rows' primary
keys are also learned, and each is passed to the lookup table's C<gone>
before the table is cleared: held rows for those keys are marked deleted (a
rollback unmarks them).

The count is still the rows the database reports deleted. With C<RETURNING>
that equals the keys returned. On MySQL it can exceed them (see below).

=over 4

=item *

Where the dialect C<supports_returning_delete>, C<$sql> gets C<RETURNING>
and the key columns.

=item *

Otherwise (MySQL) C<keys> is required: a C<SELECT> of the key columns with
the same C<where>. It runs with C<FOR UPDATE>, locking those rows, then
C<$sql> runs. Both run in a transaction of their own when none is open.
Nothing is marked unless the C<DELETE> succeeds. At C<READ COMMITTED> a row
another session commits between the two is deleted and counted, but not
marked.

=back

=back

=cut

my %BULK_ARGS = map { $_ => 1 } qw/mark_deleted keys/;

sub bulk_write {
    my $self = shift;
    my ($source, $sql, $binds, %params) = @_;

    $self->_check_params(bulk_write => \%BULK_ARGS, \%params);
    confess "bulk_write() needs a source (a DBIx::QuickORM::Role::Source)" unless blessed($source) && $source->DOES('DBIx::QuickORM::Role::Source');
    my $table = $source->table;
    confess "bulk_write() needs a source with a table" unless defined $table;
    confess "'binds' must be an arrayref" if defined($binds) && ref($binds) ne 'ARRAY';

    my $fields = $source->field_records;
    $binds = $self->_resolve_binds($source, $binds);
    my $lookup = $self->lookup;

    unless ($params{mark_deleted}) {
        my $sth = $self->_run($fields, $sql, $binds);
        $lookup->forget($table);
        return $sth->rows;
    }

    my $dialect = $self->{+DIALECT};
    if ($dialect->supports_returning_delete) {
        my $returning = join ', ' => map { $dialect->quote_identifier($_) } @{$self->_table($table)->{pk}};
        my $keys      = $self->_fetch($fields, $self->_run($fields, "$sql RETURNING $returning", $binds));
        $lookup->gone($table, $_) for @$keys;
        $lookup->forget($table);
        return scalar @$keys;
    }

    my $select = $params{keys};
    confess "bulk_write() needs 'keys' to mark deleted rows: the " . $dialect->name . " dialect has no RETURNING on DELETE" unless ref($select) eq 'ARRAY';
    my $run = sub {
        my $keys = $self->_fetch($fields, $self->_run($fields, "$select->[0] FOR UPDATE", $self->_resolve_binds($source, $select->[1])));
        my $sth  = $self->_run($fields, $sql, $binds);
        $lookup->gone($table, $_) for @$keys;
        $lookup->forget($table);
        return $sth->rows;
    };
    return @{$self->{+TXNS}} ? $run->() : $self->txn($run);
}

=pod

=over 4

=item $txn = $conn->txn(caller => \@frame)

=item $txn = $conn->txn(isolation => $level, caller => \@frame)

=item @result = $conn->txn(sub { my $txn = shift; ... }, retry => $n, isolation => $level, caller => \@frame)

Opens a transaction, or a savepoint when one is already open, and returns its
L<DBIx::QuickORM::Txn>. Given a block, runs it in the transaction and returns
what the block returns.

The transaction statements are sent as SQL, never through DBI's
C<begin_work>. Nesting croaks on a dialect without savepoints (DuckDB).
C<caller> is where it was opened, for warnings and errors. It is the caller of
this method unless given.

Opening one begins a lookup table level (see L<DBIx::QuickORM::LookupTable>).

The block is called in list context when C<txn> is, otherwise in scalar
context. A normal return commits,
unless the block already committed or rolled back itself. An exception rolls
back and is rethrown.

With C<retry>, the block of a root transaction runs again in a new
transaction, up to C<$n> more times, while the exception is a
L<DBIx::QuickORM::Exception::DB> whose C<retriable> is true. A
C<retry> above 0 croaks inside another transaction or without a block. One
that is not a count croaks.

C<isolation> is the root transaction's level: C<read uncommitted>, C<read
committed>, C<repeatable read>, or C<serializable>, in any case, or
C<'server'> for the database's own default. Without it the Connection's
C<isolation> applies. Every retry begins at the same level. It croaks inside
another transaction and for any other value. A level on a database without
settable levels (SQLite, DuckDB) croaks when the transaction opens.

=back

=cut

my %TXN_ARGS  = map { $_ => 1 } qw/retry isolation caller/;
my @ISOLATION = ('read committed', 'read uncommitted', 'repeatable read', 'serializable', 'server');
my %ISOLATION = map { $_ => 1 } @ISOLATION;

sub txn {
    my $self   = shift;
    my $code   = ref($_[0]) eq 'CODE' ? shift : undef;
    my %params = @_;

    $self->_check_params(txn => \%TXN_ARGS, \%params);
    my $caller = $params{caller} // [caller];
    my $retry  = $params{retry}  // 0;
    confess "'retry' must be a count of retries" unless $retry =~ m/^\d+\z/;
    confess "'retry' needs a block: txn(sub { ... }, retry => \$n)"                     if $retry && !$code;
    confess "'retry' is only for a root transaction, and a transaction is already open" if $retry && @{$self->{+TXNS}};

    my $level = $params{isolation};
    if (defined $level) {
        $level = $self->_isolation($level);
        confess "'isolation' is only for a root transaction, and a transaction is already open" if @{$self->{+TXNS}};
    }
    return $self->_begin($caller, $level) unless $code;

    my $list = wantarray;
    for (my $tries = 0;; $tries++) {
        my ($ok, $err, @out) = $self->_run_block($code, $caller, $list, $level);
        return $list ? @out : $out[0] if $ok;
        die $err unless $tries < $retry && $self->_retriable($err);
    }
}

=pod

=over 4

=item $conn->commit_txn($txn)

=item $conn->rollback_txn($txn)

What C<< $txn->commit >> and C<< $txn->rollback >> do (see
L<DBIx::QuickORM::Txn>).

Either croaks unless the transaction is open and innermost, this is the
process that opened it, and no async query is pending.

Committing a transaction marked failed rolls it back instead, then croaks
(see C<_run>).

Ending a transaction ends its lookup table level, as
L<DBIx::QuickORM::LookupTable> describes. A failed commit or rollback is
handled as L<DBIx::QuickORM::Txn> describes.

=back

=cut

sub commit_txn {
    my $self = shift;
    my ($txn) = @_;

    $self->_check_open($txn, 'commit');
    $self->_check_idle;    # Before the commit, whose failure would roll back.
    if (defined(my $failed = $txn->failed)) {
        $self->_unwind($txn);
        confess "The transaction opened at " . $txn->opened_at . " was rolled back instead of committed, since a statement in it failed.\nThe failure: $failed\n";
    }
    my $sql = $txn->depth == 1 ? 'COMMIT' : 'RELEASE SAVEPOINT ' . $txn->name;
    unless (eval { $self->_do($sql); 1 }) {
        my $err = $@;
        die $err if eval { $self->_unwind($txn); 1 };
        my $rollback_err = $@;
        $self->_abandon($txn);
        chomp($err, $rollback_err);
        die "The outcome of the transaction opened at " . $txn->opened_at . " is unknown: committing it failed, and so did rolling it back.\nCommit error: $err\nRollback error: $rollback_err\n";
    }

    pop @{$self->{+TXNS}};
    $self->lookup->commit_level;
    return 1;
}

sub rollback_txn {
    my $self = shift;
    my ($txn) = @_;
    $self->_check_open($txn, 'roll back');
    $self->_check_idle;
    $self->_unwind($txn);
    return 1;
}

=pod

=over 4

=item \%values = $conn->deflate($table, \%values, raw => $bool)

The values in a new hashref (under C<raw> with no marker, the one given),
deflated as L<DBIx::QuickORM/"CRUD operations"> describes. The CRUD operations
use it on every value they send. Row objects use it for the changes they send
raw.

Value markers (L<DBIx::QuickORM::Value>) are handled even under C<raw>: a
C<raw> marker is unwrapped, an C<inflated> one is deflated through the type
whatever C<is_inflated> says, and C<binary> and C<sql> markers are kept for
the SQL. With C<raw> nothing else changes, and values holding no marker are
returned as they are.

Croaks for a table not in the map, or a field the table does not have, before
deflating anything.

=back

=cut

sub deflate {
    my $self = shift;
    my ($table, $values, %params) = @_;
    my $fields = $self->_table($table)->{fields};
    $self->_check_fields($table, sort keys %$values);

    my $raw = $params{raw};
    return $values if $raw && !grep { $self->_is_marker($_) } values %$values;

    return {map { $_ => $self->_deflate_value($table, $_, $fields->{$_}, $values->{$_}, $raw) } keys %$values};
}

=over 4

=item $conn->release_inherited

In a forked child, lets go of the handle inherited from the parent without
touching the parent's session.

An async query the parent left pending is cleared too, so nothing the child
does later, or at exit, waits on it. It does nothing in the process that
opened the Connection, and calling it again is harmless.

=back

=cut

sub release_inherited {
    my $self = shift;
    return if $self->{+PID} == $$;
    $self->{+DIALECT}->release_inherited($self->{+DBH});

    my $busy = delete $self->{+BUSY} or return;
    my $sth  = $busy->{sth};
    delete $PENDING{refaddr($self)};
    @{$sth}{qw/InactiveDestroy RaiseError PrintError PrintWarn HandleError/} = (1, 0, 0, 0, sub { 1 });
    local $@;
    eval { $sth->finish; 1 } or warn $@;    # Against the released socket: it reads nothing of the parent's.
    return;
}

=head1 PRIVATE METHODS

=over 4

=item $code = $conn->_error_handler($dialect, \@txns)

The C<HandleError> callback: dies with a L<DBIx::QuickORM::Exception::DB>
built from the failing handle. First it marks the innermost open transaction
failed, with the error (see C<_run>). It holds the dialect and the
transaction stack, not the Connection.

=back

=cut

sub _error_handler {
    my $self = shift;
    my ($dialect, $txns) = @_;

    return sub {
        my ($msg, $h) = @_;
        my ($native, $state, $errstr) = ($h->err, $h->state, $h->errstr);
        $state = undef unless defined($state) && length($state);

        my $txn = $txns->[-1];
        $txn->{failed} //= $errstr // $msg if $txn;

        die DBIx::QuickORM::Exception::DB->new(
            kind      => $dialect->error_kind($native, $state, $errstr),
            state     => $state,
            native    => $native,
            errstr    => $errstr,
            statement => $h->{Statement},
            message   => $msg,
        );
    };
}

=pod

=over 4

=item \%generated = $conn->_generate_keys(\%table, \%values)

New values for the table's primary key fields missing from C<%values>, from
each field's type's C<generate_key_value>. A field's C<generate> hint
decides: C<none> never, C<prefer_orm> always, and C<prefer_db> (the default)
unless the column has C<db_fills> and the dialect can return the inserted
key (C<supports_returning_insert>). Fields without a type, or whose
type cannot generate, are left out. The values are inflated. The caller
deflates them, even for C<raw> inserts.

=back

=cut

sub _generate_keys {
    my $self = shift;
    my ($t, $values) = @_;

    my %generated;
    for my $name (@{$t->{pk} // []}) {
        next if exists $values->{$name};
        my $field = $t->{fields}->{$name};
        my $type  = $field->{orm_type};
        next unless $type && $type->can('generate_key_value');

        my $mode = $field->{generate} // 'prefer_db';
        next if $mode eq 'none' || ($mode eq 'prefer_db' && $field->{db_fills} && $self->{+DIALECT}->supports_returning_insert);
        $generated{$name} = $type->generate_key_value($field, $self);
    }

    return \%generated;
}

=pod

=over 4

=item \%data = $conn->_row_data($row_or_data)

The row data: a hashref as given, or a row object's C<row_data>. Croaks on
anything else.

=back

=cut

sub _row_data {
    my $self = shift;
    my ($data) = @_;
    $data = $data->row_data if blessed($data) && $data->can('row_data');
    confess "Expected row data (a hashref) or a row object, got " . ($data // 'undef') unless ref($data) eq 'HASH';
    return $data;
}

=pod

=over 4

=item $value = $conn->_deflate_value($table, $name, \%field, $value, $raw)

One value deflated as C<deflate> describes. C<\%field> is undef for a name
that is not a field.

A value the type deflated to plain text then goes through the field's
C<format>, if it has one and is not binary.

=back

=cut

sub _deflate_value {
    my $self = shift;
    my ($table, $name, $field, $value, $raw) = @_;
    my $type = $field ? $field->{orm_type} : undef;

    if (ref($value) && $self->_is_marker($value)) {
        my $kind = $value->kind;
        return $value if $kind eq 'binary' || $kind eq 'sql';
        $value = $value->value;
        return $value if $kind eq 'raw' || !defined($value);
    }
    elsif ($raw || !defined($value)) {
        return $value;
    }
    elsif ($type && !ref($value)) {
        return $value unless $type->can('is_inflated') && $type->is_inflated($value);
    }

    unless ($type) {
        confess "The field '$name' of '$table' has no type to deflate a reference with; deflate it yourself and pass raw => 1" if ref $value;
        return $value;
    }

    my $out    = $type->deflate($value, $field, $self);
    my $format = $field->{format};
    return $out unless $format && defined($out) && !ref($out) && ($field->{affinity} // '') ne 'binary';
    return $format->($out);
}

=pod

=over 4

=item $bool = $conn->_is_marker($value)

=item $bool = $conn->_is_sql($value)

True for a value marker, or an C<sql> marker.

=back

=cut

sub _is_marker { blessed($_[1])           && $_[1]->isa('DBIx::QuickORM::Value') ? 1 : 0 }
sub _is_sql    { $_[0]->_is_marker($_[1]) && $_[1]->kind eq 'sql'                ? 1 : 0 }

=pod

=over 4

=item \%values = $conn->_plain(\%values)

A copy with each C<binary> marker replaced by its value, for lookup keys and
row data.

=back

=cut

sub _plain {
    my $self = shift;
    my ($values) = @_;
    return {map { my $v = $values->{$_}; ($_ => $self->_is_marker($v) ? $v->value : $v) } keys %$values};
}

=pod

=over 4

=item (\@places, \@binds, $marked) = $conn->_value_sql(\%values, @names)

The SQL for each named value, C<?> or an C<sql> marker's SQL, and the binds,
in order. C<$marked> is true when any value was a marker: its SQL or bind
attributes make the statement one of a kind, never cached.

=back

=cut

sub _value_sql {
    my $self = shift;
    my ($values, @names) = @_;

    my (@places, @binds, $marked);
    for my $name (@names) {
        my $value = $values->{$name};
        $marked = 1 if ref($value) && $self->_is_marker($value);
        if (ref($value) && $self->_is_sql($value)) {
            push @places => $value->value;
            push @binds  => map { [undef, $_] } @{$value->binds};
            next;
        }
        push @places => '?';
        push @binds  => [$name => $value];
    }

    return (\@places, \@binds, $marked);
}

=pod

=over 4

=item @batches = $conn->_batches(\@values, \@names)

The rows of a multi-row insert, as C<[\@places, \@binds]> pairs: each place is
one row's C<(...)>, and each pair holds as many rows as fit in the dialect's
C<bind_limit>, at least one.

=back

=cut

sub _batches {
    my $self = shift;
    my ($values, $names) = @_;

    my $limit   = $self->{+DIALECT}->bind_limit;
    my $plain   = '(' . join(', ' => ('?') x @$names) . ')';
    my @batches = ([[], []]);
    for my $row (@$values) {
        my ($places, $binds, $marked) = $self->_value_sql($row, @$names);
        push @batches             => [[], []] if @{$batches[-1]->[0]} && @{$batches[-1]->[1]} + @$binds > $limit;
        push @{$batches[-1]->[0]} => $marked ? '(' . join(', ' => @$places) . ')' : $plain;
        push @{$batches[-1]->[1]} => @$binds;
    }

    return @batches;
}

=pod

=over 4

=item \@binds = $conn->_resolve_binds($source, \@binds)

Binds built elsewhere with their C<raw> and C<inflated> markers resolved, as
C<deflate> with C<raw> resolves them, by the source's field each bind names.

=back

=cut

sub _resolve_binds {
    my $self = shift;
    my ($source, $binds) = @_;

    my $table  = $source->table // '';
    my $fields = $source->field_records;
    return [map { my ($name, $value) = @$_; [$name, $self->_deflate_value($table, $name // '', defined($name) ? $fields->{$name} : undef, $value, 1)] } @{$binds // []}];
}

=pod

=over 4

=item $conn->_check_params($name, \%known, \%params)

Croaks naming every key of C<%params> not in C<%known>.

=back

=cut

sub _check_params {
    my $self = shift;
    my ($name, $known, $params) = @_;
    my @unknown = sort grep { !$known->{$_} } keys %$params;
    confess "Unknown argument(s) to $name(): " . join(', ' => @unknown) if @unknown;
}

=pod

=over 4

=item \%table = $conn->_table($table)

The map's record for the table. Croaks when there is none.

=back

=cut

sub _table {
    my $self = shift;
    my ($table) = @_;
    confess "A table name is required" unless defined($table) && length($table);
    return $self->_map->table($table) // confess "The table '$table' is not in the database map";
}

=pod

=over 4

=item $conn->_check_fields($table, @fields)

Croaks for the first field not in the table.

=back

=cut

sub _check_fields {
    my $self = shift;
    my ($table, @fields) = @_;
    my $known = $self->_map->table($table)->{fields};
    for my $field (@fields) {
        confess "The table '$table' has no field '$field'" unless $known->{$field};
    }
}

=pod

=over 4

=item \%pk = $conn->_pk_values($table, $pk)

=item \%pk = $conn->_pk_values($table, $pk, $raw)

The key-field hash from a primary key in any form C<normalize_pk> in
L<DBIx::QuickORM::Map> takes, each value put through C<deflate> (with C<raw>
when C<$raw> is true). Every key argument takes this path. A C<binary> marker
is kept for binding. C<_plain> of the hash is the raw key the lookup table
takes. Croaks as C<normalize_pk> does, and on an C<sql> marker.

=back

=cut

sub _pk_values {
    my $self = shift;
    my ($table, $pk, $raw) = @_;

    my $map    = $self->_map;
    my $values = $map->normalize_pk($table, $pk);
    my $fields = $map->pk($table);
    my $out    = $self->deflate($table, {map { $fields->[$_] => $values->[$_] } 0 .. $#$fields}, raw => $raw);
    for my $field (@$fields) {
        confess "sql() cannot be used in a primary key (the field '$field')" if $self->_is_sql($out->{$field});
    }
    return $out;
}

=pod

=over 4

=item \@copy = $conn->_check_datetime_parsers(\@parsers)

A copy of C<@parsers> once each is a code reference, an object with
C<parse_datetime>, or a class name. Loads each class not yet loaded. Croaks
when the shape is wrong, or a class cannot be loaded or has no
C<parse_datetime>.

=back

=cut

sub _check_datetime_parsers {
    my $self = shift;
    my ($parsers) = @_;

    croak "'datetime_parsers' must be an arrayref of parsers: classes or objects with parse_datetime, or code references"
        unless ref($parsers) eq 'ARRAY' && !grep { ref($_) ne 'CODE' && !(blessed($_) ? $_->can('parse_datetime') : defined($_) && !ref($_) && m/^\w+(?:::\w+)*\z/) } @$parsers;

    for my $parser (grep { !ref($_) } @$parsers) {
        next if $parser->can('parse_datetime');
        require DBIx::QuickORM;
        DBIx::QuickORM->load_class("'datetime_parsers' names the class '$parser', which", $parser);
        croak "'datetime_parsers' names the class '$parser', which has no parse_datetime" unless $parser->can('parse_datetime');
    }

    return [@$parsers];
}

=pod

=over 4

=item $conn->_enforce_canon($table, \%data, $flag)

Croaks unless the data is canon, when C<$flag> (or its default) says to check.

=back

=cut

sub _enforce_canon {
    my $self = shift;
    my ($table, $data, $flag) = @_;

    my $lookup = $self->lookup;
    $flag //= $lookup->in_txn ? 1 : $self->{+ENFORCE_CANON};
    return unless $flag;
    return if $lookup->is_canon($table, $data);
    confess "The row data for '$table' is not canon (not the ORM's current copy of that row); refresh the row, or pass enforce_canon => 0; for an update, a row's cas_update() writes only while the database still holds what the row read";
}

=pod

=over 4

=item %cas = $conn->_cas_values($table, \%data, \%changes, \%params)

The compare-and-swap fields and their values from the row data.

=back

=cut

sub _cas_values {
    my $self = shift;
    my ($table, $data, $changes, $params) = @_;

    my $cas = $params->{cas} // [];
    confess "'cas' must be an arrayref of field names" unless ref($cas) eq 'ARRAY';
    my @fields = @$cas;
    push @fields => grep { exists $data->{$_} } keys %$changes if $params->{auto_cas};
    $self->_check_fields($table, @fields);

    for my $field (@fields) {
        confess "The 'cas' field '$field' is not in the row data" unless exists $data->{$field};
    }

    return map { $_ => $data->{$_} } @fields;
}

=pod

=over 4

=item $map = $conn->_map

The map.

=back

=cut

sub _map { $_[0]->{+DB_MAP} }

=pod

=over 4

=item \@fields = $conn->_default_fields($table)

The fields a table's queries select: C<default_fields>, or every field.

=back

=cut

sub _default_fields {
    my $self    = shift;
    my ($table) = @_;
    my $t       = $self->_map->table($table);
    return $t->{default_fields} // [sort keys %{$t->{fields}}];
}

=pod

=over 4

=item $sql = $conn->_returning_sql($table)

=item $sql = $conn->_returning_sql($table, \@fields)

A C<RETURNING> clause, with a leading space, naming the fields, or the
table's default fields, quoted.

=back

=cut

sub _returning_sql {
    my $self = shift;
    my ($table, $fields) = @_;
    my $dialect = $self->{+DIALECT};
    return ' RETURNING ' . join(', ' => map { $dialect->quote_identifier($_) } @{$fields // $self->_default_fields($table)});
}

=pod

=over 4

=item ($sql, \@binds, $marked) = $conn->_where_sql(\%pairs)

A C<WHERE> body comparing each field to its value, in field order. An undef
value becomes C<IS NULL>. Binds are C<[$field, $value]> pairs. An C<sql>
marker croaks. C<$marked> is true when a value is another marker, as for
C<_value_sql>. The SQL is built once per set of fields and null values (see
C<_statement>).

=back

=cut

sub _where_sql {
    my $self = shift;
    my ($pairs) = @_;

    my (@shape, @binds, $marked);
    for my $field (sort keys %$pairs) {
        my $value = $pairs->{$field};
        confess "sql() cannot be used in a primary key or compare-and-swap value (the field '$field')" if $self->_is_sql($value);
        $marked = 1                                                                                    if ref($value) && $self->_is_marker($value);
        if (defined $value) {
            push @shape => $field;
            push @binds => [$field => $value];
        }
        else {
            push @shape => "\x01$field";
        }
    }

    my $dialect = $self->{+DIALECT};
    my $sql     = $self->_statement(
        join("\0" => 'where', @shape),
        sub {
            join ' AND ' => map { m/^\x01(.*)\z/s ? $dialect->quote_identifier($1) . ' IS NULL' : $dialect->quote_identifier($_) . ' = ?' } @shape;
        }
    );

    return ($sql, \@binds, $marked);
}

=pod

=over 4

=item $sql = $conn->_statement($shape, \&build)

The SQL C<build> returns, kept by C<$shape> so it is built once per shape: a
key naming the statement kind, the table, and its fields in order. An undef
shape (a statement with a marker, see C<_value_sql>) builds it every time.

=back

=cut

sub _statement {
    my $self = shift;
    my ($shape, $build) = @_;
    return $build->() unless defined $shape;
    return $self->{+STATEMENTS}->{$shape} //= $build->();
}

=pod

=over 4

=item $sth = $conn->_run(\%fields, $sql, \@binds)

=item $sth = $conn->_run(\%fields, $sql, \@binds, \%prepare_attrs, $cached)

Prepares and executes the SQL, the one place the CRUD operations bind values.
With C<$cached> the statement comes from C<prepare_cached>, for the
single-row CRUD operations' fixed SQL only.

Every statement the Connection sends comes through here, so here it croaks
while an async query is pending (see C<select>), and while the innermost
transaction is marked failed, unless the statement rolls it back. Each bind is
C<[$name, $value]>. The field record C<$fields{$name}> (none for an undef
name) decides the bind attributes, except that a C<binary> marker is bound as
binary. The SQL and every value not going to a binary field pass through the
dialect's C<text_to_db>.

=back

=cut

sub _run {
    my $self = shift;
    my ($fields, $sql, $binds, $attrs, $cached) = @_;

    $self->_check_idle;
    if (my $txn = $self->{+TXNS}->[-1]) {
        # RELEASE SAVEPOINT reaches a failed level only after ROLLBACK TO it: commit_txn rolls a failed level back first.
        confess "A statement in the transaction opened at " . $txn->opened_at . " failed, so the transaction can only be rolled back; to recover from a failure and go on, run the work that may fail in a nested transaction.\nThe failure: " . $txn->failed . "\n"
            if defined($txn->failed) && $sql !~ m/^(?:ROLLBACK|RELEASE SAVEPOINT)\b/;
    }
    my $dialect = $self->{+DIALECT};

    my (@values, @attrs, @text, %attrs_of);
    for my $bind (@$binds) {
        my ($name, $value) = @$bind;
        my $field = defined($name) ? $fields->{$name}                                            : undef;
        my $attrs = $field         ? ($attrs_of{$field} //= [$dialect->bind_attrs($field)])->[0] : undef;    # once per field record
        if (ref($value) && $self->_is_marker($value)) {
            confess "A " . $value->kind . "() marker cannot be bound here" unless $value->kind eq 'binary';
            ($field, $value) = ({affinity => 'binary'}, $value->value);
            $attrs = $dialect->bind_attrs($field);
        }
        push @text   => scalar(@values) unless $field && $field->{affinity} eq 'binary';
        push @values => $value;
        push @attrs  => $attrs;
    }
    $dialect->text_to_db($sql, @values[@text]);

    # 3: a cached statement still active is left alone and a new one prepared.
    my $sth = $cached ? $self->{+DBH}->prepare_cached($sql, $attrs, 3) : $self->{+DBH}->prepare($sql, $attrs);
    $sth->bind_param($_ + 1, $values[$_], $attrs[$_]) for 0 .. $#values;
    $sth->execute;

    return $sth;
}

=pod

=over 4

=item $conn->_check_idle

Croaks while an async query is pending.

=back

=cut

sub _check_idle {
    my $self = shift;
    confess "An async query is still pending on this connection; collect its iterator (ready, next, or all) first" if $self->{+BUSY};
}

=pod

=over 4

=item $conn->_do($sql)

Runs a transaction statement through C<_run>.

=back

=cut

sub _do { $_[0]->_run({}, $_[1], []) }

=pod

=over 4

=item \@rows = $conn->_fetch(\%fields, $sth)

Every remaining row of an executed statement, as hashes keyed by column name.
It is the one place the CRUD operations fetch rows. The names and every value
not from a binary field (by C<$fields{$name}>) pass through the dialect's
C<text_from_db>.

=back

=cut

sub _fetch {
    my $self = shift;
    my ($fields, $sth) = @_;

    my $dialect = $self->{+DIALECT};

    my @names = @{$sth->{NAME}};
    $dialect->text_from_db(@names);
    my @text = grep { (($fields->{$names[$_]} // {})->{affinity} // '') ne 'binary' } 0 .. $#names;

    my @rows;
    while (my $row = $sth->fetchrow_arrayref) {
        my @values = @$row;
        $dialect->text_from_db(@values[@text]);
        push @rows => {map { $names[$_] => $values[$_] } 0 .. $#names};
    }

    return \@rows;
}

=pod

=over 4

=item $level = $conn->_isolation($level)

The level in lower case. Confesses unless it is one C<txn> takes or
C<'server'>.

=back

=cut

sub _isolation {
    my $self = shift;
    my ($level) = @_;
    return lc $level if defined($level) && !ref($level) && $ISOLATION{lc $level};
    confess "'isolation' must be one of: " . join(', ' => map { "'$_'" } @ISOLATION);
}

=pod

=over 4

=item $txn = $conn->_begin(\@caller, $level)

Opens a transaction or savepoint and pushes it onto the stack. C<$level> is
the root transaction's isolation level from C<txn>, or undef.

A root transaction always states its level: C<$level>, else the Connection's
C<isolation>, else C<'read committed'> where the dialect
C<supports_isolation>. C<'server'> sends the dialect's plain C<begin_sql>.

=back

=cut

sub _begin {
    my $self = shift;
    my ($caller, $level) = @_;

    my $txns    = $self->{+TXNS};
    my $dialect = $self->{+DIALECT};
    my $name    = 'qorm_txn_' . ++$self->{+TXN_COUNT};
    if (@$txns) {
        confess "The " . $dialect->name . " dialect has no savepoints, so transactions cannot be nested" unless $dialect->supports_savepoints;
        $self->_do("SAVEPOINT $name");
        $self->lookup->push_level;
    }
    else {
        $level //= $self->{+ISOLATION} // ($dialect->supports_isolation ? 'read committed' : 'server');
        $self->_do($_) for $dialect->begin_sql($level eq 'server' ? undef : uc $level);
        $self->lookup->begin_root;
    }

    my $txn = DBIx::QuickORM::Txn->new(connection => $self, name => $name, depth => @$txns + 1, caller => $caller);
    weaken($txns->[@$txns] = $txn);
    return $txn;
}

=pod

=over 4

=item ($ok, $err, @out) = $conn->_run_block($code, \@caller, $list, $level)

Runs one attempt of a transaction block, as C<txn> describes, and reports how
it ended, including a failure to open the transaction. A failed rollback after
the block threw is a warning, so the block's exception is what propagates. The
transaction is then abandoned (C<_abandon>).

=back

=cut

sub _run_block {
    my $self = shift;
    my ($code, $caller, $list, $level) = @_;

    my $txn = eval { $self->_begin($caller, $level) } or return (0, $@);
    my @out;
    my $ok = eval {
        if   ($list) { @out    = $code->($txn) }
        else         { $out[0] = $code->($txn) }
        $self->commit_txn($txn) if $self->_is_open($txn);
        1;
    };
    return (1, undef, @out) if $ok;

    my $err = $@;
    if ($self->_is_open($txn) && !eval { $self->_unwind($txn); 1 }) {
        warn "Rolling back the transaction opened at " . $txn->opened_at . " after its block threw an exception failed: $@";
        $self->_abandon($txn);
    }
    return (0, $err);
}

=pod

=over 4

=item $bool = $conn->_retriable($err)

True for a L<DBIx::QuickORM::Exception::DB> whose C<retriable> is true.

=back

=cut

sub _retriable {
    my $self = shift;
    my ($err) = @_;
    return 0 unless blessed($err) && $err->isa('DBIx::QuickORM::Exception::DB');
    return $err->retriable ? 1 : 0;
}

=pod

=over 4

=item $bool = $conn->_is_open($txn)

True while the transaction is on the stack.

=back

=cut

sub _is_open {
    my $self  = shift;
    my ($txn) = @_;
    my $open  = $self->{+TXNS}->[$txn->depth - 1];
    return $open && $open == $txn ? 1 : 0;
}

=pod

=over 4

=item $conn->_check_open($txn, $action)

Croaks unless the transaction is open and innermost, and this is the process
that opened it.

=back

=cut

sub _check_open {
    my $self = shift;
    my ($txn, $action) = @_;

    my $where = $txn->opened_at;
    confess "Cannot $action the transaction opened at $where from process $$; process $self->{+PID} opened it" unless $self->{+PID} == $$;
    confess "Cannot $action the transaction opened at $where: it is already finished"                          unless $self->_is_open($txn);
    confess "Cannot $action the transaction opened at $where: a transaction opened inside it is still open"    unless $txn->depth == @{$self->{+TXNS}};
}

=pod

=over 4

=item $conn->_unwind($txn)

Rolls the transaction back, with every transaction open inside it, then drops
them from the stack and the lookup table. An async query still pending is
cancelled first, warning if that fails. Nothing is dropped when the database
refuses the rollback.

=back

=cut

sub _unwind {
    my $self = shift;
    my ($txn) = @_;

    # A query left pending inside it cannot be collected any more. On PostgreSQL the cancel aborts the transaction.
    if (my $busy = $self->{+BUSY}) {
        local $@;
        eval { $busy->{cancel}->(); 1 } or warn "Cancelling the async query pending in the transaction opened at " . $txn->opened_at . " failed: $@";
    }

    if ($txn->depth == 1) {
        $self->_do('ROLLBACK');
    }
    else {
        $self->_do('ROLLBACK TO SAVEPOINT ' . $txn->name);
        $self->_do('RELEASE SAVEPOINT ' . $txn->name);
    }

    $self->_drop_levels($txn);
}

=pod

=over 4

=item $conn->_drop_levels($txn)

Drops the transaction, and every transaction open inside it, from the stack
and the lookup table, without SQL.

=back

=cut

sub _drop_levels {
    my $self = shift;
    my ($txn) = @_;

    my $txns   = $self->{+TXNS};
    my $lookup = $self->lookup;
    while (@$txns >= $txn->depth) {
        pop @$txns;
        $lookup->rollback_level;
    }
}

=pod

=over 4

=item $conn->_abandon($txn)

For a transaction whose outcome is unknown: drops it as C<_drop_levels> does,
then empties every remaining transaction lookup level, so no row held from
inside the transaction is canon. The outside level is kept.

=back

=cut

sub _abandon {
    my $self = shift;
    my ($txn) = @_;
    $self->_drop_levels($txn);
    $self->lookup->clear_txn_levels;
}

sub DESTROY {
    my $self = shift;
    return if !$self->{+PID} || $self->{+PID} == $$;

    # By now DBI has torn its handles down. Any still alive at exit were released before that.
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';

    $self->release_inherited;
}

# A child that exits with the parent's async query still pending would otherwise free the handle and the
# statement in any order during global destruction. DBD::Pg 3.21.2, freeing the statement after its handle,
# reads freed memory (https://github.com/bucardo/dbdpg/issues/218) and can wait on the query, taking the
# parent's result off the shared socket.
END {
    local ($?, $@, $!);
    $_->release_inherited for grep { $_ } values %PENDING;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
