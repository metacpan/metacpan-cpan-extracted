package DBIx::QuickORM::Dialect::MySQL;
use strict;
use warnings;

our $VERSION = '0.000028';

use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use DBIx::QuickORM::Util qw/column_key load_class/;
use DBIx::QuickORM::Affinity qw/affinity_from_type/;

use DBI();

use DBIx::QuickORM::Schema;
use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::Table::Column;
use DBIx::QuickORM::Schema::View;

use parent 'DBIx::QuickORM::Dialect';
use Object::HashBase qw{
    +dbi_driver
    +db_vendor
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Dialect::MySQL - MySQL-family dialect for DBIx::QuickORM.

=head1 DESCRIPTION

Dialect implementation for the MySQL family of databases, covering both the
C<DBD::mysql> and C<DBD::MariaDB> drivers. It provides async query support,
transaction and savepoint control, and live schema introspection from
C<information_schema>.

At C<init> time a generic instance promotes itself to a vendor-specific
subclass (MariaDB, Percona, or Community) when the running server's vendor can
be detected, falling back to this class with a warning otherwise.

=head1 SYNOPSIS

    my $dialect = DBIx::QuickORM::Dialect::MySQL->new(dbh => $dbh, db_name => $name);

=head1 ATTRIBUTES

=over 4

=item dbi_driver

The C<DBD::*> driver class backing the connection (C<DBD::mysql> or
C<DBD::MariaDB>), resolved lazily from the live handle.

=item db_vendor

Cached result of server vendor detection; see the C<db_vendor> method.

=back

=cut

=pod

=head1 PUBLIC METHODS

=over 4

=item $bool = $dialect->async_supported

=item $bool = $dialect->async_cancel_supported

Feature flags for async query support.

=item %args = $dialect->async_prepare_args(%params)

=item $bool = $dialect->async_ready(sth => $sth)

=item $res = $dialect->async_result(sth => $sth)

=item $dialect->async_cancel

Driver-appropriate async query helpers. C<async_cancel> always croaks: the
MySQL family cannot cancel an in-flight async query.

=cut

sub datetime_formatter     { 'DateTime::Format::MySQL' }

sub async_supported        { 1 }
sub async_cancel_supported { 0 }
sub async_prepare_args     { my ($self, %params) = @_; $self->dbi_driver eq 'DBD::mysql' ? (async => 1) : (mariadb_async => 1) }
sub async_ready            { my ($self, %params) = @_; $self->dbi_driver eq 'DBD::mysql' ? $params{sth}->mysql_async_ready() : $params{sth}->mariadb_async_ready() }
sub async_result           { my ($self, %params) = @_; $self->dbi_driver eq 'DBD::mysql' ? $params{sth}->mysql_async_result() : $params{sth}->mariadb_async_result() }
sub async_cancel           { my $self = shift; croak "Dialect '" . $self->dialect_name . "' does not support canceling async queries" }

=pod

=item $bool = $dialect->cas_count_reliable(\%attrs)

The MySQL and MariaDB drivers enable the found-rows client flag by default, so
the affected-row count reflects rows matched. This returns false only when that
flag (C<mysql_client_found_rows> / C<mariadb_found_rows>) was explicitly turned
off in the connect attributes.

=cut

sub cas_count_reliable {
    my $self = shift;
    my ($attrs) = @_;
    for my $key (qw/mysql_client_found_rows mariadb_found_rows/) {
        return 0 if exists $attrs->{$key} && !$attrs->{$key};
    }
    return 1;
}

=pod

=item $dialect->start_txn(%params)

=item $dialect->commit_txn(%params)

=item $dialect->rollback_txn(%params)

=item $dialect->create_savepoint(%params)

=item $dialect->commit_savepoint(%params)

=item $dialect->rollback_savepoint(%params)

Transaction and savepoint control. Each accepts an optional C<dbh> parameter,
defaulting to the dialect's own handle; savepoint methods take a C<savepoint>
name.

=cut

sub start_txn          { my ($self, %params) = @_; my $dbh = $params{dbh} // $self->dbh; $dbh->begin_work }
sub commit_txn         { my ($self, %params) = @_; my $dbh = $params{dbh} // $self->dbh; $dbh->commit }
sub rollback_txn       { my ($self, %params) = @_; my $dbh = $params{dbh} // $self->dbh; $dbh->rollback }
sub create_savepoint   { my ($self, %params) = @_; my $dbh = $params{dbh} // $self->dbh; my $sp = $dbh->quote_identifier($params{savepoint}); $dbh->do("SAVEPOINT $sp") }
sub commit_savepoint   { my ($self, %params) = @_; my $dbh = $params{dbh} // $self->dbh; my $sp = $dbh->quote_identifier($params{savepoint}); $dbh->do("RELEASE SAVEPOINT $sp") }
sub rollback_savepoint { my ($self, %params) = @_; my $dbh = $params{dbh} // $self->dbh; my $sp = $dbh->quote_identifier($params{savepoint}); $dbh->do("ROLLBACK TO SAVEPOINT $sp") }

=pod

=item $name = $dialect->dialect_name

Returns C<'MySQL'>.

=cut

sub dialect_name { 'MySQL' }

=pod

=item $stype = $dialect->supports_type($type)

Returns the native type name for a supported logical type (e.g. C<json>),
or nothing. MariaDB stores C<JSON> as an alias for C<LONGTEXT> but accepts
the keyword.

=cut

my %TYPES = (
    json      => 'JSON',
    text      => 'TEXT',
    longtext  => 'LONGTEXT',
    blob      => 'BLOB',
    datetime  => 'DATETIME',
    timestamp => 'TIMESTAMP',
);
sub supports_type {
    my $self = shift;
    my ($type) = @_;
    return undef unless defined $type;
    return $TYPES{lc($type)};
}

=pod

=back

=cut

BEGIN {
    my $mariadb = eval { require DBD::MariaDB; 1 };
    my $mysql   = eval { require DBD::mysql; 1 };

    croak "You must install either DBD::MariaDB or DBD::mysql" unless $mariadb || $mysql;

    *DEFAULT_DBI_DRIVER = $mariadb ? sub() { 'DBD::MariaDB' } : sub() { 'DBD::mysql' };
}

=pod

=head1 PUBLIC METHODS (continued)

=over 4

=item $driver = $dialect->dbi_driver

=item $driver = DBIx::QuickORM::Dialect::MySQL->dbi_driver

The C<DBD::*> driver class. As a class method returns the installed default;
as an instance method resolves and caches it from the live handle.

=cut

sub dbi_driver {
    my $in = shift;

    return DEFAULT_DBI_DRIVER() unless blessed($in);

    return $in->{+DBI_DRIVER} if $in->{+DBI_DRIVER};

    my $dbh = $in->dbh;

    return $in->{+DBI_DRIVER} = "DBD::" . $dbh->{Driver}->{Name};
}

=pod

=item $val = $dialect->quote_binary_data

Driver-appropriate bind type for binary data: C<undef> for C<DBD::mysql>,
C<DBI::SQL_BINARY> for C<DBD::MariaDB>.

=cut

sub quote_binary_data {
    my $self = shift;
    my $driver = $self->dbi_driver;
    return undef if $driver eq 'DBD::mysql';
    return DBI::SQL_BINARY if $driver eq 'DBD::MariaDB';
    croak "Unknown DBD::Driver '$driver'";
}

=pod

=item $dialect->init

Validates the connection and, for a generic instance, promotes it to a
vendor-specific subclass when the server vendor can be detected.

=cut

sub init {
    my $self = shift;

    if (blessed($self) eq __PACKAGE__) {
        # The detected vendor is cached on the object, so the subclass init()
        # after the rebless (and anything later) does not re-probe the server.
        if (my $vendor = $self->db_vendor) {
            if (my $class = load_class("DBIx::QuickORM::Dialect::MySQL::${vendor}")) {
                bless($self, $class);
                return $self->init();
            }
            elsif ($@ !~ m{Can't locate DBIx/QuickORM/Dialect/MySQL/${vendor}\.pm in \@INC}) {
                die $@;
            }

            warn "Detected db vendor '$vendor', but no vendor-specific dialect 'DBIx::QuickORM::Dialect::MySQL::${vendor}' could be found. Using the generic 'DBIx::QuickORM::Dialect::MySQL', which can mean degraded capabilities compared to a dedicated dialect.\n";
        }
        else {
            warn "Could not detect the db vendor (MariaDB, Percona, or Community). Using the generic 'DBIx::QuickORM::Dialect::MySQL', which can mean degraded capabilities compared to a dedicated dialect.\n";
        }
    }

    return $self->SUPER::init();
}

=pod

=item $field = $dialect->dsn_dbname_field

DSN field name used to specify the database name. The MySQL family uses
C<database>: C<DBD::MariaDB> does not accept C<dbname>, while C<DBD::mysql>
accepts both.

=cut

sub dsn_dbname_field { 'database' }

=pod

=item $field = $dialect->dsn_socket_field($driver)

DSN field name used to specify a unix socket for the given driver.

=cut

sub dsn_socket_field {
    my $this = shift;
    my ($driver) = @_;

    return 'mariadb_socket' if $driver eq 'DBD::MariaDB';
    return 'mysql_socket' if $driver eq 'DBD::mysql';

    $this->SUPER::dsn_socket_field($driver);
}

=pod

=item $version = $dialect->db_version

Server version string from C<SELECT version()>.

=cut

sub db_version {
    my $self = shift;

    my $dbh = $self->{+DBH};

    my $sth = $dbh->prepare("SELECT version()");
    $sth->execute();

    my ($ver) = $sth->fetchrow_array;
    return $ver;
}

=pod

=item $vendor = $dialect->db_vendor

Detects the server vendor (C<MariaDB>, C<Percona>, or C<Community>) from the
version strings, or C<undef> when it cannot be determined. The result is
cached on the object.

=cut

sub db_vendor {
    my $self = shift;

    return $self->{+DB_VENDOR} if exists $self->{+DB_VENDOR};

    my $dbh = $self->{+DBH};

    for my $cmd ('SELECT @@version_comment', 'SELECT version()') {
        my $sth = $dbh->prepare($cmd);
        $sth->execute();
        my ($val) = $sth->fetchrow_array;

        my $vendor = $self->_vendor_from_string($val);
        return $self->{+DB_VENDOR} = $vendor if $vendor;
    }

    # Single quotes: under ANSI_QUOTES mode double quotes denote identifiers,
    # not string literals.
    my $sth = $dbh->prepare("SHOW VARIABLES LIKE '%version%'");
    $sth->execute();

    while (my @vals = $sth->fetchrow_array) {
        for my $val (@vals) {
            my $vendor = $self->_vendor_from_string($val);
            return $self->{+DB_VENDOR} = $vendor if $vendor;
        }
    }

    return $self->{+DB_VENDOR} = undef;
}

=pod

=item $sql = $dialect->upsert_statement($pk)

Returns the MySQL upsert clause C<ON DUPLICATE KEY UPDATE>.

=back

=cut

sub upsert_statement {
    my $self = shift;
    my ($pk) = @_;
    return "ON DUPLICATE KEY UPDATE";
}

###############################################################################
# {{{ Schema Builder Code
###############################################################################

=pod

=head1 SCHEMA INTROSPECTION METHODS

=over 4

=item $tables = $dialect->build_tables_from_db(%params)

=item ($pk, $unique, $links) = $dialect->build_table_keys_from_db($table, %params)

=item $columns = $dialect->build_columns_from_db($table, %params)

=item $indexes = $dialect->build_indexes_from_db($table, %params)

Introspect tables, keys, columns, and indexes for the connected database from
C<information_schema>, invoking the C<autofill> hooks supplied in C<%params> as
each piece of metadata is built.

=back

=cut

my %TABLE_TYPES = (
    'BASE TABLE' => 'DBIx::QuickORM::Schema::Table',
    'VIEW'       => 'DBIx::QuickORM::Schema::View',
    'TEMPORARY'  => 'DBIx::QuickORM::Schema::Table',
);

my %TEMP_TYPES = (
    'BASE TABLE' => 0,
    'VIEW'       => 0,
    'TEMPORARY'  => 1,
);

sub build_tables_from_db {
    my $self = shift;
    my %params = @_;

    my $dbh = $self->{+DBH};

    my $sth = $dbh->prepare('SELECT table_name, table_type FROM information_schema.tables WHERE table_schema = ?');
    $sth->execute($self->{+DB_NAME});
    my @table_list = @{$sth->fetchall_arrayref};

    # Sweep all columns, indexes, and constraints for the database in one query
    # each, grouped by table, rather than a query-per-table. The per-table
    # builders below consume these pre-fetched rows.
    my $all_columns = $self->_fetch_all_columns;
    my $all_indexes = $self->_fetch_all_indexes;
    my $all_keys    = $self->_fetch_all_keys;

    my %tables;

    for my $row (@table_list) {
        my ($tname, $type) = @$row;
        next if $params{autofill}->skip(table => $tname);

        my $table = {name => $tname, db_name => $tname, is_temp => $TEMP_TYPES{$type} // 0};
        my $class = $TABLE_TYPES{$type} // 'DBIx::QuickORM::Schema::Table';
        $params{autofill}->hook(pre_table => {table => $table, class => \$class});

        $table->{columns} = $self->build_columns_from_db($tname, %params, column_rows => $all_columns->{$tname} // []);
        $params{autofill}->hook(columns => {columns => $table->{columns}, table => $table});

        $table->{indexes} = $self->build_indexes_from_db($tname, %params, index_rows => $all_indexes->{$tname} // []);
        $params{autofill}->hook(indexes => {indexes => $table->{indexes}, table => $table});

        @{$table}{qw/primary_key unique _links/} = $self->build_table_keys_from_db($tname, %params, key_rows => $all_keys->{$tname} // []);

        $params{autofill}->hook(post_table => {table => $table, class => \$class});

        # Hooks may rename the table; key by the final name.
        my $final_name = $table->{name};
        $tables{$final_name} = $class->new($table);
        $params{autofill}->hook(table => {table => $tables{$final_name}});
    }

    return \%tables;
}

sub build_table_keys_from_db {
    my $self = shift;
    my ($table, %params) = @_;

    my $rows = $params{key_rows} // $self->_query_keys($table);

    my ($pk, %unique, @links);

    my %keys;
    for my $row (@$rows) {
        my $item = $keys{$row->{con}} //= {type => lc($row->{type})};

        push @{$item->{columns} //= []} => $row->{col};

        next unless $row->{type} eq 'FOREIGN KEY';

        my $link = $item->{link} //= [[$table, $item->{columns}],[$row->{ftab},[]]];
        push @{$link->[1]->[1]} => $row->{fcol};
    }

    for my $key (sort keys %keys) {
        my $item = $keys{$key};

        my $type = delete $item->{type};
        if ($type eq 'foreign key') {
            push @links => $item->{link};
        }
        elsif ($type eq 'unique' || $type eq 'primary key') {
            $unique{column_key(@{$item->{columns}})} = $item->{columns};
            $pk = $item->{columns} if $type eq 'primary key';
        }
    }

    $params{autofill}->hook(links       => {links       => \@links, table_name => $table});
    $params{autofill}->hook(primary_key => {primary_key => $pk, table_name => $table});
    $params{autofill}->hook(unique_keys => {unique_keys => \%unique, table_name => $table});

    return ($pk, \%unique, \@links);
}

sub build_columns_from_db {
    my $self = shift;
    my ($table, %params) = @_;

    croak "A table name is required" unless $table;

    my $rows = $params{column_rows} // $self->_query_columns($table);

    my %columns;
    for my $res (@$rows) {
        next if $params{autofill}->skip(column => ($table, $res->{COLUMN_NAME}));

        my $col = {};

        $params{autofill}->hook(pre_column => {column => $col, table_name => $table, column_info => $res});

        $col->{name} = $res->{COLUMN_NAME};
        $col->{db_name} = $res->{COLUMN_NAME};
        $col->{order} = $res->{ORDINAL_POSITION};
        $col->{type} = \"$res->{DATA_TYPE}";
        $col->{nullable} = $self->_col_field_to_bool($res->{IS_NULLABLE});

        # EXTRA can carry more than one token (e.g. "auto_increment DEFAULT_GENERATED"),
        # so match the word rather than the whole string.
        $col->{identity} = 1 if $res->{EXTRA} && $res->{EXTRA} =~ m/\bauto_increment\b/i;

        # Both MySQL (5.7+) and MariaDB (10.2+) populate GENERATION_EXPRESSION
        # for stored/virtual GENERATED columns and leave it null/empty for
        # ordinary columns. EXTRA strings vary between vendors and may include
        # DEFAULT_GENERATED (a default expression, not a generated column), so
        # GENERATION_EXPRESSION is the canonical signal.
        $col->{generated} = 1
            if defined($res->{GENERATION_EXPRESSION}) && length $res->{GENERATION_EXPRESSION};

        $col->{affinity} //= affinity_from_type($res->{DATA_TYPE});
        $col->{affinity} //= 'string'  if grep { $self->_col_field_to_bool($res->{$_}) } grep { m/CHARACTER/ } keys %$res;
        $col->{affinity} //= 'numeric' if grep { $self->_col_field_to_bool($res->{$_}) } grep { m/NUMERIC/ } keys %$res;
        $col->{affinity} //= 'string';

        $params{autofill}->process_column($col);
        $params{autofill}->hook(post_column => {column => $col, table_name => $table, column_info => $res});

        $columns{$col->{name}} = DBIx::QuickORM::Schema::Table::Column->new($col);
        $params{autofill}->hook(column => {column => $columns{$col->{name}}, table_name => $table, column_info => $res});
    }

    return \%columns;
}

=pod

=head1 PRIVATE METHODS

=over 4

=item $vendor_or_undef = $dialect->_vendor_from_string($val)

Maps a server version/comment string to a vendor name, or undef when the
string (possibly undefined) names no known vendor.

=cut

sub _vendor_from_string {
    my $self = shift;
    my ($val) = @_;

    return undef unless defined $val;

    return 'MariaDB' if $val =~ m/MariaDB/i;
    return 'Percona' if $val =~ m/Percona/i;

    # Oracle ships both "MySQL Community Server" and "MySQL Enterprise
    # Server"; both are upstream MySQL, which the Community dialect covers.
    return 'Community' if $val =~ m/(?:Community|Enterprise)/i;

    return undef;
}

=pod

=item $bool = $dialect->_col_field_to_bool($val)

Interprets an C<information_schema> string field as a boolean, treating
C<no>/C<undef>/C<never> and empty/undefined values as false.

=back

=cut

sub _col_field_to_bool {
    my $self = shift;
    my ($val) = @_;

    return 0 unless defined $val;
    return 0 unless $val;
    $val = lc($val);
    return 0 if $val eq 'no';
    return 0 if $val eq 'undef';
    return 0 if $val eq 'never';
    return 1;
}

sub build_indexes_from_db {
    my $self = shift;
    my ($table, %params) = @_;

    my $rows = $params{index_rows} // $self->_query_indexes($table);

    my %out;
    for my $r (@$rows) {
        my ($name, $col, $nu, $type) = @$r;
        my $idx = $out{$name} //= {name => $name, unique => $nu ? 0 : 1, type => $type, columns => []};
        push @{$idx->{columns}} => $col;
    }

    return [map { $params{autofill}->hook(index => {index => $out{$_}, table_name => $table}); $out{$_} } sort keys %out];
}

=pod

=head1 PRIVATE METHODS (schema introspection)

=over 4

=item $by_table = $dialect->_fetch_all_columns

=item $by_table = $dialect->_fetch_all_indexes

=item $by_table = $dialect->_fetch_all_keys

Sweep all column, index, and constraint metadata for the connected database in
a single query each, returning a hashref of table name to the rows for that
table (in the same shape the matching single-table C<_query_*> helper returns).

=item $rows = $dialect->_query_columns($table)

=item $rows = $dialect->_query_indexes($table)

=item $rows = $dialect->_query_keys($table)

Single-table fallbacks used when the per-table builders are called without
pre-fetched rows. Each issues one query scoped to C<$table>.

=back

=cut

sub _fetch_all_columns {
    my $self = shift;

    my $dbh = $self->{+DBH};
    my $sth = $dbh->prepare(<<"    EOT");
        SELECT *
          FROM information_schema.columns
         WHERE table_schema = ?
      ORDER BY table_name, ordinal_position
    EOT
    $sth->execute($self->{+DB_NAME});

    my %by_table;
    while (my $res = $sth->fetchrow_hashref) {
        my $tname = $res->{TABLE_NAME} // $res->{table_name};
        push @{$by_table{$tname} //= []} => $res;
    }

    return \%by_table;
}

sub _query_columns {
    my $self = shift;
    my ($table) = @_;

    my $dbh = $self->{+DBH};
    my $sth = $dbh->prepare(<<"    EOT");
        SELECT *
          FROM information_schema.columns
         WHERE table_name    = ?
           AND table_schema  = ?
    EOT
    $sth->execute($table, $self->{+DB_NAME});

    return $sth->fetchall_arrayref({});
}

sub _fetch_all_indexes {
    my $self = shift;

    my $dbh = $self->dbh;
    my $sth = $dbh->prepare(<<"    EOT");
        SELECT table_name,
               index_name,
               column_name,
               non_unique,
               index_type
          FROM INFORMATION_SCHEMA.STATISTICS
         WHERE table_schema = ?
      ORDER BY table_name, index_name, seq_in_index
    EOT
    $sth->execute($self->{+DB_NAME});

    my %by_table;
    while (my ($tname, $name, $col, $nu, $type) = $sth->fetchrow_array) {
        push @{$by_table{$tname} //= []} => [$name, $col, $nu, $type];
    }

    return \%by_table;
}

sub _query_indexes {
    my $self = shift;
    my ($table) = @_;

    my $dbh = $self->dbh;
    my $sth = $dbh->prepare(<<"    EOT");
        SELECT index_name,
               column_name,
               non_unique,
               index_type
          FROM INFORMATION_SCHEMA.STATISTICS
         WHERE table_name = ?
           AND table_schema = ?
      ORDER BY index_name, seq_in_index
    EOT
    $sth->execute($table, $self->{+DB_NAME});

    return $sth->fetchall_arrayref;
}

sub _fetch_all_keys {
    my $self = shift;

    my $dbh = $self->{+DBH};
    my $sth = $dbh->prepare(<<"    EOT");
        SELECT tco.table_name             AS tab,
               tco.constraint_name        AS con,
               tco.constraint_type        AS type,
               kcu.column_name            AS col,
               kcu.referenced_table_name  AS ftab,
               kcu.referenced_column_name AS fcol
          FROM information_schema.table_constraints tco
          JOIN information_schema.key_column_usage  kcu
            ON tco.constraint_schema = kcu.constraint_schema
           AND tco.constraint_name   = kcu.constraint_name
           AND tco.table_name        = kcu.table_name
         WHERE tco.table_schema NOT IN ('sys','information_schema', 'mysql', 'performance_schema')
           AND tco.table_schema = ?
      ORDER BY tco.table_name, tco.constraint_name, kcu.ordinal_position
    EOT
    $sth->execute($self->{+DB_NAME});

    my %by_table;
    while (my $row = $sth->fetchrow_hashref) {
        push @{$by_table{$row->{tab}} //= []} => $row;
    }

    return \%by_table;
}

sub _query_keys {
    my $self = shift;
    my ($table) = @_;

    my $dbh = $self->{+DBH};
    my $sth = $dbh->prepare(<<"    EOT");
        SELECT tco.constraint_name          AS con,
               tco.constraint_type          AS type,
               kcu.column_name              AS col,
               kcu.referenced_table_name    AS ftab,
               kcu.referenced_column_name   AS fcol
          FROM information_schema.table_constraints tco
          JOIN information_schema.key_column_usage  kcu
            ON tco.constraint_schema = kcu.constraint_schema
           AND tco.constraint_name   = kcu.constraint_name
           AND tco.table_name        = kcu.table_name
         WHERE tco.table_schema NOT IN ('sys','information_schema', 'mysql', 'performance_schema')
           AND tco.table_name        = ?
           AND tco.table_schema      = ?
      ORDER BY tco.table_schema, tco.table_name, tco.constraint_name, kcu.ordinal_position
    EOT
    $sth->execute($table, $self->{+DB_NAME});

    return $sth->fetchall_arrayref({});
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
