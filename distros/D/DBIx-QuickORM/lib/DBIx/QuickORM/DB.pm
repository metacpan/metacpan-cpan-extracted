package DBIx::QuickORM::DB;
use strict;
use warnings;

our $VERSION = '0.000001';

use Carp qw/confess croak/;
use List::Util qw/first/;
use Scalar::Util qw/blessed/;
use DBIx::QuickORM::Util qw/alias/;
use Role::Tiny::With qw/with/;

require DBIx::QuickORM::GlobalLookup;
require DBIx::QuickORM::Connection;
require DBIx::QuickORM::Util::SchemaBuilder;
require DateTime;

use DBIx::QuickORM::Util::HashBase qw{
    +connect
    <attributes
    <db_name
    +dsn
    <host
    <name
    <pid
    <port
    <socket
    <user
    password
    <locator
    +sql_spec
    <created
};

with 'DBIx::QuickORM::Role::HasSQLSpec';

sub in_txn             { $_[1]->{BegunWork} ? 1 : $_[1]->{AutoCommit} ? 0 : 1 }
sub start_txn          { croak "$_[0]->start_txn() is not implemented" }
sub commit_txn         { croak "$_[0]->commit_txn() is not implemented" }
sub rollback_txn       { croak "$_[0]->rollback_txn() is not implemented" }
sub create_savepoint   { croak "$_[0]->create_savepoint() is not implemented" }
sub commit_savepoint   { croak "$_[0]->commit_savepoint() is not implemented" }
sub rollback_savepoint { croak "$_[0]->rollback_savepoint() is not implemented" }

sub dbi_driver { croak "$_[0]->dbi_driver() is not implemented" }
sub datetime_formatter { 'DateTime' }

sub tables      { croak "$_[0]->tables() is not implemented" }
sub table       { croak "$_[0]->table() is not implemented" }
sub column_type { croak "$_[0]->column_type() is not implemented" }
sub columns     { croak "$_[0]->columns() is not implemented" }
sub db_keys     { croak "$_[0]->db_keys() is not implemented" }
sub db_version  { croak "$_[0]->db_version() is not implemented" }
sub indexes     { croak "$_[0]->indexes() is not implemented" }

sub load_schema_sql { croak "$_[0]->load_schema_sql() is not implemented" }

sub create_temp_view  { croak "$_[0]->create_temp_view() is not implemented" }
sub create_temp_table { croak "$_[0]->create_temp_table() is not implemented" }
sub drop_temp_view    { croak "$_[0]->drop_temp_table() is not implemented" }
sub drop_temp_table   { croak "$_[0]->drop_temp_table() is not implemented" }

sub quote_binary_data                 { 1 }
sub quote_index_columns               { 1 }
sub generate_schema_sql_header        { () }
sub generate_schema_sql_footer        { () }
sub generate_schema_sql_column_serial { croak "$_[0]->generate_schema_sql_column_serial() is not implemented" }

sub sql_spec_keys {}

sub temp_table_supported { 0 }
sub temp_view_supported  { 0 }

sub supports_uuid { () }
sub supports_json { () }
sub supports_datetime { 'DATETIME' }

sub supports_async  { 0 }
sub async_query_arg { croak "$_[0]->async_query_arg() is not implemented" }
sub async_ready     { croak "$_[0]->async_ready() is not implemented" }
sub async_result    { croak "$_[0]->async_result() is not implemented" }
sub async_cancel    { croak "$_[0]->async_cancel() is not implemented" }

sub insert_returning_supported { 0 }
sub update_returning_supported { 0 }

sub ping { $_[1]->ping }

sub driver_name {
    my $self_or_class = shift;
    my $class = blessed($self_or_class) || $self_or_class;
    $class =~ s/^DBIx::QuickORM::DB:://;
    return $class;
}

sub init {
    my $self = shift;

    delete $self->{+NAME} unless defined $self->{+NAME};

    croak "${ \__PACKAGE__ } cannot be used directly, use a subclass" if blessed($self) eq __PACKAGE__;

    $self->{+ATTRIBUTES} //= {};

    $self->{+ATTRIBUTES}->{RaiseError}          //= 1;
    $self->{+ATTRIBUTES}->{PrintError}          //= 1;
    $self->{+ATTRIBUTES}->{AutoCommit}          //= 1;
    $self->{+ATTRIBUTES}->{AutoInactiveDestroy} //= 1;

    croak "Cannot provide both a socket and a host" if $self->{+SOCKET} && $self->{+HOST};

    $self->{+LOCATOR} = DBIx::QuickORM::GlobalLookup->register($self);
}

sub dsn_socket_field { 'host' };

sub dsn {
    my $self = shift;
    return $self->{+DSN} if $self->{+DSN};

    my $driver = $self->dbi_driver;
    $driver =~ s/^DBD:://;

    my $db_name = $self->db_name;

    my $dsn = "dbi:${driver}:dbname=${db_name};";

    if (my $socket = $self->socket) {
        $dsn .= $self->dsn_socket_field . "=$socket";
    }
    elsif (my $host = $self->host) {
        $dsn .= "host=$host;";
        if (my $port = $self->port) {
            $dsn .= "port=$port;";
        }
    }
    else {
        croak "Cannot construct dsn without a host or socket";
    }

    return $self->{+DSN} = $dsn;
}

sub connect {
    my $self = shift;
    my (%params) = @_;

    my $dbh;
    eval {
        if ($self->{+CONNECT}) {
            $dbh = $self->{+CONNECT}->();
        }
        else {
            require DBI;
            $dbh = DBI->connect($self->dsn, $self->user, $self->password, $self->attributes // {AutoInactiveDestroy => 1, AutoCommit => 1});
        }

        1;
    } or confess $@;

    $dbh->{AutoInactiveDestroy} = 1;

    return $dbh if $params{dbh_only};

    return DBIx::QuickORM::Connection->new(
        dbh => $dbh,
        db  => $self,
    );
}

sub table_dep_cmp {
    my $class_or_self = shift;
    my ($a, $b) = @_;

    my $out = 0;

    my $a_first = -1;
    my $b_first = 1;

    my $a_name = $a->name;
    my $b_name = $b->name;

    my $a_deps = $a->deps;
    my $b_deps = $b->deps;

    die "Circular dependency detected in tables '$a_name' and '$b_name'"
        if $a_deps->{$b_name} && $b_deps->{$a_name};

    $out ||= $a_first if $b_deps->{$a_name};
    $out ||= $b_first if $a_deps->{$b_name};
    $out ||= $b_name cmp $a_name;

    return $out;
}

sub generate_schema_sql {
    my $class_or_self = shift;
    my %params        = @_;

    my $schema  = $params{schema} or croak "'schema' must be provided";
    my $specs   = $params{sql_spec};

    if (blessed($class_or_self)) {
        $specs   //= $class_or_self->{+SQL_SPEC};
    }

    my @out;

    push @out => $class_or_self->_generate_schema_sql_header(%params, sql_spec => $specs, schema => $schema);

    for my $t (sort { $class_or_self->table_dep_cmp($a, $b) } $schema->tables) {
        my $tname = $t->name;

        push @out => $class_or_self->generate_schema_sql_table(%params, table => $t, schema => $schema);
        push @out => $class_or_self->generate_schema_sql_indexes_for_table(%params, table => $t, schema => $schema);
    }

    push @out => $class_or_self->_generate_schema_sql_footer(%params, sql_spec => $specs, schema => $schema);

    return join "\n" => @out;
}

sub _generate_schema_sql_header {
    my $class_or_self = shift;
    my %params        = @_;

    my $specs   = $params{sql_spec} or return;
    my $schema  = $params{schema};

    my @out;

    if (my $val = $specs->get_spec('pre_header_sql', $class_or_self->sql_spec_keys)) { push @out => $val }
    push @out => $class_or_self->generate_schema_sql_header(%params);
    if (my $val = $specs->get_spec('post_header_sql', $class_or_self->sql_spec_keys)) { push @out => $val }

    return @out;
}

sub _generate_schema_sql_footer {
    my $class_or_self = shift;
    my %params        = @_;

    my $specs   = $params{sql_spec} or return;
    my $schema  = $params{schema};

    my @out;

    if (my $val = $specs->get_spec('pre_footer_sql', $class_or_self->sql_spec_keys)) { push @out => $val }
    push @out => $class_or_self->generate_schema_sql_footer(%params);
    if (my $val = $specs->get_spec('post_footer_sql', $class_or_self->sql_spec_keys)) { push @out => $val }

    return @out;
}

sub generate_schema_sql_table {
    my $class_or_self = shift;
    my %params        = @_;

    my $table   = $params{table} or croak "A table is required";
    my $schema  = $params{schema};

    my $specs = $table->sql_spec;

    if (my $sql = $specs->get_spec(table_sql =>  $class_or_self->sql_spec_keys)) {
        return $sql;
    };

    my $table_name = $table->name;

    my @out;

    my @columns = sort {$a->{primary_key} ? -1 : $b->{primary_key} ? 1 : $a->{order} <=> $b->{order}} values %{$table->columns};

    for my $col (@columns) {
        push @out => $class_or_self->generate_schema_sql_column_sql(column => $col, %params);
    }

    my %uniq_seen;
    if (my $pk = $table->primary_key) {
        $uniq_seen{join(', ' => @$pk)}++;
        push @out => $class_or_self->generate_schema_sql_primary_key(key => $pk, columns => \@columns);
    }

    for my $uniq (values %{$table->unique // {}}) {
        next if $uniq_seen{join(', ' => @$uniq)}++;
        push @out => $class_or_self->generate_schema_sql_unique(@$uniq);
    }

    my @rels;
    for my $rel (values %{$table->relations // {}}) {
        push @rels => $class_or_self->generate_schema_sql_foreign_key(relation => $rel, %params);
    }

    my %seen;
    push @out => grep { !$seen{$_}++ } @rels;

    return (
        "CREATE TABLE $table_name(",
        (join ",\n" => map { "    $_" } @out),
        ");",
    );
}

sub generate_schema_sql_column_sql {
    my $class_or_self = shift;
    my %params        = @_;

    my $col = $params{column} or croak "column is required";

    my $specs = $col->sql_spec;
    $params{sql_spec} = $specs;

    if (my $sql = $specs->get_spec(column_sql =>  $class_or_self->sql_spec_keys)) {
        return $sql;
    };

    my $name = $col->name or croak "Columns must have names";

    my $type    = $class_or_self->generate_schema_sql_column_type(%params);
    my $null    = $class_or_self->generate_schema_sql_column_null(%params);
    my $default = $class_or_self->generate_schema_sql_column_default(%params);
    my $serial  = $class_or_self->generate_schema_sql_column_serial(%params);

    return join ' ' => $name, $type, grep { $_ } $null, $serial, $default;
}

sub generate_schema_sql_foreign_key {
    my $class_or_self = shift;
    my %params = @_;

    my $rel   = $params{relation};
    my $table = $params{table};

    # Only do this for relations where this table only finds 1 other object
    return unless $rel->gets_one;

    # Self-reference conditions
    my $tb_name = $table->name;
    return if $rel->table eq $tb_name;

    my $out = 'FOREIGN KEY(' . join(', ' => $rel->local_columns) . ') REFERENCES ' . $rel->table . '(' . join(', ' => $rel->foreign_columns) . ')';

    if (my $od = $rel->on_delete) {
        $out .= " ON DELETE $od";
    }

    return $out;
}

sub generate_schema_sql_primary_key {
    my $class_or_self = shift;
    my %params        = @_;
    my $key           = $params{key};
    my $cols          = $params{columns};

    return unless $key && @$key;
    return "PRIMARY KEY(" . join(', ' => @$key) . ")";
}

sub generate_schema_sql_unique {
    my $class_or_self = shift;
    my @cols = @_;
    return unless @cols;
    return "UNIQUE(" . join(', ' => @cols) . ")";
}

sub generate_schema_sql_column_null {
    my $class_or_self = shift;
    my %params = @_;

    my $col = $params{column};

    my $nullable = $col->nullable // 1;

    return "" if $nullable;
    return "NOT NULL";
}

sub generate_schema_sql_indexes_for_table {
    my $class_or_self = shift;
    my %params        = @_;

    my $table   = $params{table} or croak "A table is required";
    my $schema  = $params{schema};

    my @out;

    my $table_name = $table->name;
    for my $idx (values %{$table->indexes}) {
        my @names = @{$idx->{columns}};
        @names = map { "`$_`" } @names if $class_or_self->quote_index_columns;
        push @out => "CREATE INDEX $idx->{name} ON $table_name(" . join(', ' => @names) . ");";
    }

    return @out;
}

sub normalize_sql_type { $_[1] }

sub generate_schema_sql_column_type {
    my $class_or_self = shift;
    my %params        = @_;

    my $specs = $params{sql_spec};

    my $col = $params{column};
    my $t = $params{table}->name;
    my $c = $col->name;

    my $type = $col->sql_type($class_or_self->sql_spec_keys);

    if (my $s = $col->serial) {
        $type //= $class_or_self->serial_type($s);
    }

    if (my $cf = $col->conflate) {
        $type //= $cf->qorm_sql_type(%params) if $cf->can('qorm_sql_type');
    }

    if (ref($type) eq 'SCALAR') {
        $type = $$type;
    }
    else {
        $type = $class_or_self->normalize_sql_type($type, %params);
    }

    croak "No 'type' key found in SQL specs for column $c in table $t, and it is not serial"
        unless $type;

    return $type;
}

sub serial_type {
    my $self = shift;
    my ($size) = @_;
    return 'INTEGER' if "$size" eq "1";
    return "${size}INT";
}

sub generate_schema_sql_column_default {
    my $class_or_self = shift;
    my %params        = @_;

    my $specs = $params{sql_spec};

    return $specs->get_spec(default => $class_or_self->sql_spec_keys);
}

1;
