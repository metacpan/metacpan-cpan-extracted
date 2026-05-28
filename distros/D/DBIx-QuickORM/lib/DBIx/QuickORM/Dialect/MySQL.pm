package DBIx::QuickORM::Dialect::MySQL;
use strict;
use warnings;

our $VERSION = '0.000021';

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
        if (my $vendor = $self->db_vendor) {
            if (my $class = load_class("DBIx::QuickORM::Dialect::MySQL::${vendor}")) {
                bless($self, $class);
                return $self->init();
            }
            elsif ($@ !~ m{Can't locate DBIx/QuickORM/Dialect/MySQL/${vendor}\.pm in \@INC}) {
                die $@;
            }

            warn "Could not find vendor specific dialect 'DBIx::QuickORM::Dialect::MySQL::${vendor}', using 'DBIx::QuickORM::Dialect::MySQL'. This can result in degraded capabilities compared to a dedicate dialect\n";
        }
        else {
            warn "Could not find vendor specific dialect 'DBIx::QuickORM::Dialect::MySQL::YOUR_VENDOR', using 'DBIx::QuickORM::Dialect::MySQL'. This can result in degraded capabilities compared to a dedicate dialect\n";
        }
    }

    return $self->SUPER::init();
}

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
version strings, or C<undef> when it cannot be determined.

=cut

sub db_vendor {
    my $self = shift;

    my $dbh = $self->{+DBH};

    for my $cmd ('SELECT @@version_comment', "SELECT version()") {
        my $sth = $dbh->prepare($cmd);
        $sth->execute();
        my ($val) = $sth->fetchrow_array;

        return 'MariaDB'   if $val =~ m/MariaDB/i;
        return 'Percona'   if $val =~ m/Percona/i;
        return 'Community' if $val =~ m/Community/i;
    }

    my $sth = $dbh->prepare('SHOW VARIABLES LIKE "%version%"');
    $sth->execute();

    while (my @vals = $sth->fetchrow_array) {
        for my $val (@vals) {
            return 'MariaDB'   if $val =~ m/MariaDB/i;
            return 'Percona'   if $val =~ m/Percona/i;
            return 'Community' if $val =~ m/Community/i;
        }
    }

    return undef;
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

    my %tables;

    while (my ($tname, $type) = $sth->fetchrow_array) {
        my $table = {name => $tname, db_name => $tname, is_temp => $TEMP_TYPES{$type} // 0};
        my $class = $TABLE_TYPES{$type} // 'DBIx::QuickORM::Schema::Table';
        $params{autofill}->hook(pre_table => {table => $table, class => \$class});

        $table->{columns} = $self->build_columns_from_db($tname, %params);
        $params{autofill}->hook(columns => {columns => $table->{columns}, table => $table});

        $table->{indexes} = $self->build_indexes_from_db($tname, %params);
        $params{autofill}->hook(indexes => {indexes => $table->{indexes}, table => $table});

        @{$table}{qw/primary_key unique _links/} = $self->build_table_keys_from_db($tname, %params);

        $params{autofill}->hook(post_table => {table => $table, class => \$class});
        $tables{$tname} = $class->new($table);
        $params{autofill}->hook(table => {table => $tables{$tname}});
    }

    return \%tables;
}

sub build_table_keys_from_db {
    my $self = shift;
    my ($table, %params) = @_;

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

    my ($pk, %unique, @links);

    my %keys;
    while (my $row = $sth->fetchrow_hashref) {
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
    my $dbh = $self->{+DBH};

    my $sth = $dbh->prepare(<<"    EOT");
        SELECT *
          FROM information_schema.columns
         WHERE table_name    = ?
           AND table_schema  = ?
    EOT

    $sth->execute($table, $self->{+DB_NAME});

    my (%columns, @links);
    while (my $res = $sth->fetchrow_hashref) {
        my $col = {};

        $params{autofill}->hook(pre_column => {column => $col, table_name => $table, column_info => $res});

        $col->{name} = $res->{COLUMN_NAME};
        $col->{db_name} = $res->{COLUMN_NAME};
        $col->{order} = $res->{ORDINAL_POSITION};
        $col->{type} = \"$res->{DATA_TYPE}";
        $col->{nullable} = $self->_col_field_to_bool($res->{IS_NULLABLE});

        $col->{identity} = 1 if $res->{EXTRA} && $res->{EXTRA} eq 'auto_increment';

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

    my %out;
    while (my ($name, $col, $nu, $type) = $sth->fetchrow_array) {
        my $idx = $out{$name} //= {name => $name, unique => $nu ? 0 : 1, type => $type, columns => []};
        push @{$idx->{columns}} => $col;
    }

    return [map { $params{autofill}->hook(index => {index => $out{$_}, table_name => $table}); $out{$_} } sort keys %out];
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
