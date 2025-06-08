package DBIx::QuickORM::Dialect;
use strict;
use warnings;

use Carp qw/croak confess/;
use Scalar::Util qw/blessed/;
use DBI();

our $VERSION = '0.000011';

use DBIx::QuickORM::Util qw/load_class find_modules/;

use DBIx::QuickORM::Util::HashBase qw{
    <dbh
    <db_name
};

sub dsn_socket_field { 'host' }

sub dbi_driver { confess "Not Implemented" }
sub db_version { confess "Not Implemented" }

sub start_txn          { croak "$_[0]->start_txn() is not implemented" }
sub commit_txn         { croak "$_[0]->commit_txn() is not implemented" }
sub rollback_txn       { croak "$_[0]->rollback_txn() is not implemented" }
sub create_savepoint   { croak "$_[0]->create_savepoint() is not implemented" }
sub commit_savepoint   { croak "$_[0]->commit_savepoint() is not implemented" }
sub rollback_savepoint { croak "$_[0]->rollback_savepoint() is not implemented" }

sub quote_binary_data         { DBI::SQL_BINARY() }
sub supports_returning_update { 0 }
sub supports_returning_insert { 0 }
sub supports_returning_delete { 0 }
sub supports_type { }

sub in_txn {
    my $self = shift;
    my %params = @_;
    my $dbh = $params{dbh} // $self->dbh;

    return 1 if $dbh->{BegunWork};
    return 0 if $dbh->{AutoCommit};
    return 1;
}

sub dialect_name {
    my $self_or_class = shift;
    my $class = blessed($self_or_class) || $self_or_class;
    $class =~ s/^DBIx::QuickORM::Dialect:://;
    $class =~ s/::.*$//g;
    return $class;
}

sub init {
    my $self = shift;

    croak "A 'dbh' is required"      unless $self->{+DBH};
    croak "A 'db_name' is arequired" unless $self->{+DB_NAME};
}

sub dsn {
    my $self_or_class = shift;
    my ($db) = @_;

    my $driver = $db->dbi_driver // $self_or_class->dbi_driver;
    load_class($driver) or croak "Could not load '$driver': $@";
    my $dsn_driver = $driver;
    $dsn_driver =~ s/^DBD:://;

    my $db_name = $db->db_name;
    my $dsn = "dbi:${dsn_driver}:dbname=${db_name};";

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

###############################################################################
# {{{ Schema Builder Code
###############################################################################

sub build_schema_from_db {
    my $self = shift;
    my %params = @_;

    croak "No autofill object provided" unless $params{autofill};

    my $dbh = $self->dbh;

    my $tables = $self->build_tables_from_db(%params);

    $params{autofill}->hook(tables => $tables);

    return DBIx::QuickORM::Schema->new(
        tables    => $tables,
        row_class => $params{row_class},
    );
}

sub build_tables_from_db     { confess "Not Implemented" }
sub build_table_keys_from_db { confess "Not Implemented" }
sub build_columns_from_db    { confess "Not Implemented" }
sub build_indexes_from_db    { confess "Not Implemented" }

###############################################################################
# }}} Schema Builder Code
###############################################################################

###############################################################################
# {{{ SQL Builder Code
###############################################################################

sub build_sql_from_schema {
    my $self = shift;
    my ($schema, %params) = @_;

    my @sections;

    push @sections => @{$params{prefix} // []};
    push @sections => $self->build_table_sql_from_schema(@_);
    push @sections => @{$params{postfix} // []};

    return join "\n" => @sections;
}

sub build_table_sql_from_schema { confess "Not Implemented" }

###############################################################################
# }}} SQL Builder Code
###############################################################################

1;
