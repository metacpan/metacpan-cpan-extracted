package DBIx::QuickORM::Dialect;
use strict;
use warnings;

use Carp qw/croak confess/;
use Scalar::Util qw/blessed/;
use DBI();

our $VERSION = '0.000025';

use DBIx::QuickORM::Util qw/load_class find_modules/;

use Object::HashBase qw{
    <dbh
    <db_name
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Dialect - Base class for database-specific dialects.

=head1 DESCRIPTION

A dialect adapts the ORM to a specific database engine. It owns the live
database handle, knows how to build a DSN, introspects schema metadata from
the live database, generates SQL from a schema, and brokers transactions,
savepoints, and (where supported) async queries.

This class is the abstract base: most of its database-specific methods are
stubs that C<confess>/C<croak> until overridden by a concrete subclass such
as L<DBIx::QuickORM::Dialect::SQLite> or L<DBIx::QuickORM::Dialect::PostgreSQL>.

=head1 SYNOPSIS

    my $dialect = DBIx::QuickORM::Dialect::SQLite->new(dbh => $dbh, db_name => $name);

    my $schema = $dialect->build_schema_from_db(autofill => $autofill);

=head1 ATTRIBUTES

=over 4

=item dbh

The live C<DBI> database handle.

=item db_name

Name of the database this dialect is connected to.

=back

=cut

=pod

=head1 PUBLIC METHODS

=over 4

=item $field = $dialect->dsn_socket_field

Name of the DSN field used to specify a unix socket. Defaults to C<host>.

=item $field = $dialect->dsn_dbname_field

Name of the DSN field used to specify the database name. Defaults to
C<dbname>; the MySQL family overrides this with C<database>.

=item $name = $dialect->dialect_name

Short name of the dialect, derived from the class name.

=item $value = $dialect->quote_binary_data

DBI bind type/attribute used to quote binary data.

=item $bool = $dialect->supports_returning_update

=item $bool = $dialect->supports_returning_insert

=item $bool = $dialect->supports_returning_delete

True if the dialect supports a C<RETURNING> clause on the relevant statement.

=item $stype = $dialect->supports_type($type)

Returns the database-native type name if the dialect supports the given
logical type, otherwise nothing.

=item $bool = $dialect->cas_count_reliable(\%attrs)

True if a connection built with the given attributes reports the affected-row
count that compare-and-set needs (rows matched, not rows changed). The base is
always true; the MySQL family returns false when the found-rows flag was turned
off.

=cut

# {{{ Feature flags and simple accessors

sub dsn_socket_field { 'host' }
sub dsn_dbname_field { 'dbname' }

sub quote_binary_data         { my $self = shift; DBI::SQL_BINARY() }
sub supports_returning_update { 0 }
sub supports_returning_insert { 0 }
sub supports_returning_delete { 0 }

sub supports_type { my $self = shift; return undef }

sub cas_count_reliable { return 1 }

sub datetime_formatter { my $self = shift; croak "No datetime formatter is defined for the '" . $self->dialect_name . "' dialect" }

sub dialect_name {
    my $self_or_class = shift;
    my $class = blessed($self_or_class) || $self_or_class;
    $class =~ s/^DBIx::QuickORM::Dialect:://;
    $class =~ s/::.*$//g;
    return $class;
}

# }}} Feature flags and simple accessors

=pod

=item $driver = $dialect->dbi_driver

The C<DBD::*> driver class for this dialect. Stub; subclasses override.

=item $version = $dialect->db_version

The server/engine version. Stub; subclasses override.

=cut

sub dbi_driver { my $self = shift; confess "Not Implemented" }
sub db_version { my $self = shift; confess "Not Implemented" }

=pod

=item $dialect->start_txn(%params)

=item $dialect->commit_txn(%params)

=item $dialect->rollback_txn(%params)

=item $dialect->create_savepoint(%params)

=item $dialect->commit_savepoint(%params)

=item $dialect->rollback_savepoint(%params)

Transaction and savepoint control. Stubs; subclasses override.

=cut

sub start_txn          { my $self = shift; croak "$self->start_txn() is not implemented" }
sub commit_txn         { my $self = shift; croak "$self->commit_txn() is not implemented" }
sub rollback_txn       { my $self = shift; croak "$self->rollback_txn() is not implemented" }
sub create_savepoint   { my $self = shift; croak "$self->create_savepoint() is not implemented" }
sub commit_savepoint   { my $self = shift; croak "$self->commit_savepoint() is not implemented" }
sub rollback_savepoint { my $self = shift; croak "$self->rollback_savepoint() is not implemented" }

=pod

=item $bool = $dialect->async_supported

=item $bool = $dialect->async_cancel_supported

Async feature flags. False by default; dialects with async support override.

=item $dialect->async_prepare_args(%params)

=item $bool = $dialect->async_ready(%params)

=item $result = $dialect->async_result(%params)

=item $dialect->async_cancel(%params)

Async query lifecycle. Stubs that croak; dialects with async support
override.

=cut

sub async_supported        { 0 }
sub async_cancel_supported { 0 }

sub async_prepare_args { my $self = shift; croak "$self->async_prepare_args() is not implemented" }
sub async_ready        { my $self = shift; croak "$self->async_ready() is not implemented" }
sub async_result       { my $self = shift; croak "$self->async_result() is not implemented" }
sub async_cancel       { my $self = shift; croak "$self->async_cancel() is not implemented" }

=pod

=item $bool = $dialect->in_txn(%params)

True if a transaction is currently in progress on the handle (the C<dbh>
parameter, or the dialect's own handle).

=cut

sub in_txn {
    my $self = shift;
    my %params = @_;
    my $dbh = $params{dbh} // $self->dbh;

    return 1 if $dbh->{BegunWork};
    return 0 if $dbh->{AutoCommit};
    return 1;
}

=pod

=item $dialect->init

Validates that C<dbh> and C<db_name> were provided.

=cut

sub init {
    my $self = shift;

    croak "A 'dbh' is required"      unless $self->{+DBH};
    croak "A 'db_name' is required" unless $self->{+DB_NAME};
}

=pod

=item $dsn = $dialect->dsn($db)

Builds a DSN string from a database config object, loading the driver as
needed.

=cut

sub dsn {
    my $self_or_class = shift;
    my ($db) = @_;

    my $driver = $db->dbi_driver // $self_or_class->dbi_driver;
    load_class($driver) or croak "Could not load '$driver': $@";
    my $dsn_driver = $driver;
    $dsn_driver =~ s/^DBD:://;

    my $db_name = $db->db_name;
    my $dbname_field = $self_or_class->dsn_dbname_field($driver);
    my $dsn = "dbi:${dsn_driver}:${dbname_field}=${db_name};";

    if (my $socket = $db->socket) {
        $dsn .= $self_or_class->dsn_socket_field($driver) . "=$socket";
    }
    elsif (my $host = $db->host) {
        $dsn .= "host=$host;";
        if (my $port = $db->port) {
            $dsn .= "port=$port;";
        }
    }
    else {
        croak "Cannot construct dsn without a host or socket";
    }

    return $dsn;
}

=pod

=item $sql = $dialect->upsert_statement($pk)

Returns the SQL fragment implementing an upsert keyed on the given primary
key columns. Column names are quoted so reserved-word or mixed-case columns
work.

=cut

sub upsert_statement {
    my $self = shift;
    my ($pk) = @_;
    my $dbh = $self->dbh;
    return "ON CONFLICT(" . join(", " => map { $dbh->quote_identifier($_) } @$pk) . ") DO UPDATE SET";
}

###############################################################################
# {{{ Schema Builder Code
###############################################################################

=pod

=item $schema = $dialect->build_schema_from_db(%params)

Introspects the live database and returns a L<DBIx::QuickORM::Schema>.
Requires an C<autofill> object. After all tables are built it runs the
autofill C<tables> hook with the complete name-to-table hashref under the
C<tables> key, giving callbacks one place to inspect or adjust the full set.

=cut

sub build_schema_from_db {
    my $self = shift;
    my %params = @_;

    croak "No autofill object provided" unless $params{autofill};

    my $dbh = $self->dbh;

    my $tables = $self->build_tables_from_db(%params);

    $params{autofill}->hook(tables => {tables => $tables});

    return DBIx::QuickORM::Schema->new(
        tables    => $tables,
        row_class => $params{row_class},
    );
}

=pod

=item $tables = $dialect->build_tables_from_db(%params)

=item ($pk, $unique, $links) = $dialect->build_table_keys_from_db($table, %params)

=item $columns = $dialect->build_columns_from_db($table, %params)

=item $indexes = $dialect->build_indexes_from_db($table, %params)

Per-table introspection helpers. Stubs; subclasses override.

=cut

sub build_tables_from_db     { my $self = shift; confess "Not Implemented" }
sub build_table_keys_from_db { my $self = shift; confess "Not Implemented" }
sub build_columns_from_db    { my $self = shift; confess "Not Implemented" }
sub build_indexes_from_db    { my $self = shift; confess "Not Implemented" }

=pod

=back

=cut

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
