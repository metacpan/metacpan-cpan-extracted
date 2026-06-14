package DBIx::QuickORM::Dialect::SQLite;
use strict;
use warnings;

our $VERSION = '0.000023';

use DBD::SQLite 1.0;

use Carp qw/croak/;
use DBIx::QuickORM::Affinity qw/affinity_from_type/;
use DBIx::QuickORM::Util qw/column_key/;

use parent 'DBIx::QuickORM::Dialect';
use Object::HashBase;

use DBIx::QuickORM::Schema;
use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::Table::Column;
use DBIx::QuickORM::Schema::View;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Dialect::SQLite - SQLite dialect for DBIx::QuickORM.

=head1 DESCRIPTION

The SQLite-specific L<DBIx::QuickORM::Dialect>. Introspects schema metadata
from SQLite's C<pragma_*> tables and C<sqlite_master>, drives transactions
and savepoints via the SQLite driver, and reports SQLite's feature set
(C<RETURNING> support, no async support).

=head1 SYNOPSIS

    my $dialect = DBIx::QuickORM::Dialect::SQLite->new(dbh => $dbh, db_name => $name);

=cut

=pod

=head1 PUBLIC METHODS

=over 4

=item $driver = $dialect->dbi_driver

=item $name = $dialect->dialect_name

=item $bool = $dialect->supports_returning_update

=item $bool = $dialect->supports_returning_insert

=item $bool = $dialect->supports_returning_delete

=item $bool = $dialect->async_supported

=item $bool = $dialect->async_cancel_supported

Feature flags and constants describing the SQLite dialect. SQLite does not
support async queries.

=item $stype = $dialect->supports_type($type)

Returns SQLite's native storage type name for a supported logical type, or
nothing. SQLite has no native JSON type; JSON-ish types fall back to C<TEXT>
via C<supports_type('text')>.

=item $dialect->async_prepare_args

=item $dialect->async_ready

=item $dialect->async_result

=item $dialect->async_cancel

SQLite does not support async queries; these C<croak>.

=item $version = $dialect->db_version

The version of the SQLite library itself (not the C<DBD::SQLite> module
version).

=cut

# {{{ Feature flags, version info, and async stubs

sub dbi_driver   { 'DBD::SQLite' }
sub dialect_name { 'SQLite' }

sub datetime_formatter { 'DateTime::Format::SQLite' }

# SQLite's real storage types. There is no native JSON type; types like JSON
# fall back to TEXT via supports_type('text').
my %TYPES = (
    text    => 'TEXT',
    integer => 'INTEGER',
    int     => 'INTEGER',
    real    => 'REAL',
    blob    => 'BLOB',
    numeric => 'NUMERIC',
);
sub supports_type {
    my $self = shift;
    my ($type) = @_;
    return undef unless defined $type;
    return $TYPES{lc($type)};
}

sub supports_returning_update { 1 }
sub supports_returning_insert { 1 }
sub supports_returning_delete { 1 }

sub async_supported        { 0 }
sub async_cancel_supported { 0 }
sub async_prepare_args     { croak "Dialect '" . $_[0]->dialect_name . "' does not support async queries" }
sub async_ready            { croak "Dialect '" . $_[0]->dialect_name . "' does not support async queries" }
sub async_result           { croak "Dialect '" . $_[0]->dialect_name . "' does not support async queries" }
sub async_cancel           { croak "Dialect '" . $_[0]->dialect_name . "' does not support async queries" }

sub db_version { my $self = shift; $self->dbh->{sqlite_version} }

# }}} Feature flags, version info, and async stubs

=pod

=item $dialect->start_txn(%params)

=item $dialect->commit_txn(%params)

=item $dialect->rollback_txn(%params)

=item $dialect->create_savepoint(%params)

=item $dialect->commit_savepoint(%params)

=item $dialect->rollback_savepoint(%params)

Transaction and savepoint control via the SQLite driver. Each accepts an
optional C<dbh> parameter, defaulting to the dialect's own handle; savepoint
methods take a C<savepoint> name.

=cut

# {{{ Transactions and savepoints

sub start_txn          { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; $dbh->begin_work }
sub commit_txn         { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; $dbh->commit }
sub rollback_txn       { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; $dbh->rollback }
sub create_savepoint   { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; my $sp = $dbh->quote_identifier($p{savepoint}); $dbh->do("SAVEPOINT $sp") }
sub commit_savepoint   { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; my $sp = $dbh->quote_identifier($p{savepoint}); $dbh->do("RELEASE SAVEPOINT $sp") }
sub rollback_savepoint { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; my $sp = $dbh->quote_identifier($p{savepoint}); $dbh->do("ROLLBACK TO SAVEPOINT $sp") }

# }}} Transactions and savepoints

=pod

=item $dsn = $dialect->dsn($db)

Builds a SQLite DSN string from a database config object.

=back

=cut

sub dsn {
    my $self_or_class = shift;
    my ($db) = @_;

    my $driver = $db->dbi_driver // $self_or_class->dbi_driver;
    $driver =~ s/^DBD:://;

    my $db_name = $db->db_name;

    return "dbi:${driver}:dbname=${db_name}";
}

###############################################################################
# {{{ Schema Builder Code
###############################################################################


my %TABLE_TYPES = (
    'table' => 'DBIx::QuickORM::Schema::Table',
    'view'  => 'DBIx::QuickORM::Schema::View',
);

=pod

=head1 PUBLIC METHODS

=over 4

=item $tables = $dialect->build_tables_from_db(%params)

Introspects all tables and views (including temp ones) and returns a hashref
of name to schema-table object.

=cut

sub build_tables_from_db {
    my $self = shift;
    my %params = @_;

    my $dbh = $self->{+DBH};

    my @queries = (
        "SELECT name, type, 0 FROM sqlite_master      WHERE type IN ('table', 'view')",
        "SELECT name, type, 1 FROM sqlite_temp_master WHERE type IN ('table', 'view')",
    );

    my %tables;

    for my $q (@queries) {
        my $sth = $dbh->prepare($q);
        $sth->execute();

        while (my ($tname, $type, $temp) = $sth->fetchrow_array) {
            next if $tname =~ m/^sqlite_/;
            next if $params{autofill}->skip(table => $tname);

            my $table = {name => $tname, db_name => $tname, is_temp => $temp};
            my $class = $TABLE_TYPES{lc($type)} // 'DBIx::QuickORM::Schema::Table';
            $params{autofill}->hook(pre_table => {table => $table, class => \$class});

            $table->{columns} = $self->build_columns_from_db($tname, %params);
            $params{autofill}->hook(columns => {columns => $table->{columns}, table => $table});

            $table->{indexes} = $self->build_indexes_from_db($tname, %params);
            $params{autofill}->hook(indexes => {indexes => $table->{indexes}, table => $table});

            @{$table}{qw/primary_key unique _links/} = $self->build_table_keys_from_db($tname, %params);

            $params{autofill}->hook(post_table => {table => $table, class => \$class});

            # Hooks may rename the table; key by the final name.
            my $final_name = $table->{name};
            $tables{$final_name} = $class->new($table);
            $params{autofill}->hook(table => {table => $tables{$final_name}});
        }
    }

    return \%tables;
}

=pod

=item ($pk, $unique, $links) = $dialect->build_table_keys_from_db($table, %params)

Introspects a table's primary key, unique keys, and foreign-key links.

=cut

sub build_table_keys_from_db {
    my $self = shift;
    my ($table, %params) = @_;

    my $dbh = $self->{+DBH};

    my $sth = $dbh->prepare(<<"    EOT");
        SELECT il.name     AS grp,
               il.origin   AS type,
               il.`unique` AS uniq,
               ii.name     AS column
         FROM pragma_index_list(?)       AS il,
              pragma_index_info(il.name) AS ii
     ORDER BY seq, il.name, seqno, cid
    EOT

    $sth->execute($table);

    my ($pk, %unique, @links);

    my %index;
    while (my $row = $sth->fetchrow_hashref()) {
        my $idx = $index{$row->{grp}} //= {};
        $idx->{type}   = $row->{type};
        $idx->{unique} = $row->{uniq};
        push @{$idx->{cols} //= []} => $row->{column};
    }

    # Only indexes flagged unique are unique constraints; a plain CREATE INDEX
    # must not be recorded as one. The flag (not the origin) is the signal:
    # CREATE UNIQUE INDEX also has origin 'c'.
    for my $grp (sort keys %index) {
        my $idx = $index{$grp};
        $unique{column_key(@{$idx->{cols}})} = $idx->{cols} if $idx->{unique};
        $pk = $idx->{cols} if $idx->{type} eq 'pk';
    }

    unless ($pk && @$pk) {
        my @found = $self->_primary_key($table);

        if (@found) {
            $pk = \@found;
            $unique{column_key(@found)} = \@found;
        }
        else {
            $pk = undef;
        }
    }

    %index = ();
    $sth = $dbh->prepare("SELECT `id`, `table`, `from`, `to` FROM pragma_foreign_key_list(?) order by id, seq");
    $sth->execute($table);
    while (my $row = $sth->fetchrow_hashref()) {
        my $idx = $index{$row->{id}} //= {};

        push @{$idx->{columns} //= []} => $row->{from};

        $idx->{ftable} //= $row->{table};
        push @{$idx->{fcolumns} //= []} => $row->{to};
    }

    @links = map { [[$table, $_->{columns}], [$_->{ftable}, $_->{fcolumns}]] } values %index;

    $params{autofill}->hook(links       => {links       => \@links, table_name => $table});
    $params{autofill}->hook(primary_key => {primary_key => $pk, table_name => $table});
    $params{autofill}->hook(unique_keys => {unique_keys => \%unique, table_name => $table});

    return($pk, \%unique, \@links);
}

=pod

=item $bool = $dialect->table_has_autoinc($table)

True if the named table declares an C<AUTOINCREMENT> column.

=cut

sub table_has_autoinc {
    my $self = shift;
    my ($table) = @_;

    croak "A table name is required" unless $table;

    my $ddl = $self->_table_ddl($table) // return 0;

    # AUTOINCREMENT is only valid as part of a column definition's PRIMARY KEY
    # constraint, so match that grammar in the table's own CREATE TABLE DDL.
    # Matching the bare word against every sqlite_master row for the table
    # would false-positive on triggers (separate rows, excluded by the
    # type='table' filter in _table_ddl) and on comments or string literals
    # (stripped by _strip_sql_noise).
    return $self->_strip_sql_noise($ddl) =~ m/\bPRIMARY\s+KEY(?:\s+(?:ASC|DESC))?(?:\s+ON\s+CONFLICT\s+\w+)?\s+AUTOINCREMENT\b/i ? 1 : 0;
}

=pod

=item $columns = $dialect->build_columns_from_db($table, %params)

Introspects a table's columns and returns a hashref of column name to
column object.

=cut

sub build_columns_from_db {
    my $self = shift;
    my ($table, %params) = @_;

    croak "A table name is required" unless $table;
    my $dbh = $self->{+DBH};

    # pragma_table_xinfo (SQLite 3.31.0+, 2020-01-22) lists every column
    # including hidden virtual-table columns and GENERATED columns; the
    # older pragma_table_info silently omits them. The `hidden` flag
    # distinguishes them: 0 ordinary, 1 hidden virtual-table column,
    # 2 virtual generated column, 3 stored generated column.
    my $sth = $dbh->prepare("SELECT * FROM pragma_table_xinfo(?)");
    $sth->execute($table);

    # A rowid-alias column auto-assigns on insert (with or without
    # AUTOINCREMENT, which only changes rowid allocation policy), matching the
    # identity semantics of the other engines.
    my $identity_col = $self->_rowid_alias_column($table);

    my (%columns, @links);
    while (my $res = $sth->fetchrow_hashref) {
        my $hidden = $res->{hidden} // 0;
        next if $hidden == 1;    # hidden virtual-table columns are not part of the ORM schema

        next if $params{autofill}->skip(column => ($table, $res->{name}));

        my $col = {};

        $params{autofill}->hook(pre_column => {column => $col, table_name => $table, column_info => $res});

        $col->{name}    = $res->{name};
        $col->{db_name} = $res->{name};
        $col->{order}   = $res->{cid} + 1;
        $col->{identity}  = 1 if defined($identity_col) && $res->{name} eq $identity_col;
        $col->{generated} = 1 if $hidden >= 2;

        my $type = $res->{type};
        $type =~ s/\(.*$//;
        $col->{type} = \$type;

        $col->{nullable} = $res->{notnull} ? 0 : 1;
        $col->{affinity} //= affinity_from_type($type) // 'string';

        $params{autofill}->process_column($col);
        $params{autofill}->hook(post_column => {column => $col, table_name => $table, column_info => $res});

        $columns{$col->{name}} = DBIx::QuickORM::Schema::Table::Column->new($col);
        $params{autofill}->hook(column => {column => $columns{$col->{name}}, table_name => $table, column_info => $res});
    }

    return \%columns;
}

=pod

=item $indexes = $dialect->build_indexes_from_db($table, %params)

Introspects a table's indexes and returns an arrayref of index specs.

=back

=cut

sub build_indexes_from_db {
    my $self = shift;
    my ($table, %params) = @_;

    my $dbh = $self->dbh;

    my $sth = $dbh->prepare(<<"    EOT");
        SELECT il.`name`   AS name,
               il.`unique` AS u,
               ii.`name`   AS column
          FROM pragma_index_list(?)       AS il,
               pragma_index_info(il.name) AS ii
      ORDER BY il.name, ii.seqno
    EOT

    $sth->execute($table);

    my %out;
    while (my ($name, $u, $col) = $sth->fetchrow_array) {
        my $idx = $out{$name} //= {name => $name, columns => [], unique => $u ? 1 : 0};
        push @{$idx->{columns}} => $col;
    }

    if (my @pk = $self->_primary_key($table)) {
        $out{"${table}:pk"} = {name => "${table}:pk", unique => 1, columns => \@pk};
    }

    return [map { $params{autofill}->hook(index => {index => $out{$_}, table_name => $table}); $out{$_} } sort keys %out];
}

=pod

=head1 PRIVATE METHODS

=over 4

=item @cols = $dialect->_primary_key($table)

Returns the primary-key column names for a table, ordered by key position.

=cut

sub _primary_key {
    my $self = shift;
    my ($table) = @_;

    my $sth = $self->dbh->prepare("SELECT name FROM pragma_table_xinfo(?) WHERE pk > 0 AND (hidden IS NULL OR hidden < 2) ORDER BY pk ASC");
    $sth->execute($table);

    my @out;
    while (my $row = $sth->fetchrow_hashref()) {
        push @out => $row->{name};
    }

    return @out;
}

=pod

=item $ddl_or_undef = $dialect->_table_ddl($table)

The stored C<CREATE TABLE> statement for the named table (permanent or temp),
or undef when the table does not exist.

=cut

sub _table_ddl {
    my $self = shift;
    my ($table) = @_;

    my $dbh = $self->dbh;

    my ($ddl) = $dbh->selectrow_array("SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?", undef, $table);
    ($ddl) = $dbh->selectrow_array("SELECT sql FROM sqlite_temp_master WHERE type = 'table' AND name = ?", undef, $table) unless defined $ddl;

    return $ddl;
}

=pod

=item $sql = $dialect->_strip_sql_noise($sql)

Returns the SQL with string literals replaced by empty strings and comments
removed, so keyword matching cannot false-positive on either.

=cut

sub _strip_sql_noise {
    my $self = shift;
    my ($sql) = @_;

    # One left-to-right pass so a quote inside a comment (or a comment marker
    # inside a string) cannot derail the other rule.
    $sql =~ s{('(?:[^']|'')*')|(--[^\n]*)|(/\*.*?\*/)}{defined $1 ? "''" : " "}ges;

    return $sql;
}

=pod

=item $col_or_undef = $dialect->_rowid_alias_column($table)

The name of the column that aliases SQLite's rowid, or undef if the table has
none. The alias rule: a rowid table (no C<WITHOUT ROWID>) with a single-column
primary key whose declared type is exactly C<INTEGER> (C<INT>, C<BIGINT>, etc.
do not alias). Not handled: the obscure C<x INTEGER PRIMARY KEY DESC>
column-definition form, which SQLite does not treat as an alias.

=back

=cut

sub _rowid_alias_column {
    my $self = shift;
    my ($table) = @_;

    my $sth = $self->dbh->prepare("SELECT name, type FROM pragma_table_xinfo(?) WHERE pk > 0 AND (hidden IS NULL OR hidden < 2)");
    $sth->execute($table);

    my @pk;
    while (my $row = $sth->fetchrow_hashref()) {
        push @pk => $row;
    }

    return undef unless @pk == 1;
    return undef unless uc($pk[0]->{type} // '') eq 'INTEGER';

    my $ddl = $self->_table_ddl($table);
    return undef if defined($ddl) && $self->_strip_sql_noise($ddl) =~ m/\bWITHOUT\s+ROWID\b/i;

    return $pk[0]->{name};
}

###############################################################################
# }}} Schema Builder Code
###############################################################################

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
