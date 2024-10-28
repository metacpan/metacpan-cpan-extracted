package DBIx::QuickORM::DB::SQLite;
use strict;
use warnings;

our $VERSION = '0.000004';

use Carp qw/croak/;
use DBD::SQLite;
use DateTime::Format::SQLite;

use parent 'DBIx::QuickORM::DB';
use DBIx::QuickORM::Util::HashBase;

sub dbi_driver { 'DBD::SQLite' }
sub datetime_formatter { 'DateTime::Format::SQLite' }

sub sql_spec_keys { 'sqlite' }

sub temp_table_supported { 1 }
sub temp_view_supported  { 1 }
sub quote_index_columns  { 1 }

sub update_returning_supported { 1 }
sub insert_returning_supported { 1 }

sub start_txn    { $_[1]->begin_work }
sub commit_txn   { $_[1]->commit }
sub rollback_txn { $_[1]->rollback }

sub create_savepoint   { $_[1]->do("SAVEPOINT $_[2]") }
sub commit_savepoint   { $_[1]->do("RELEASE SAVEPOINT $_[2]") }
sub rollback_savepoint { $_[1]->do("ROLLBACK TO SAVEPOINT $_[2]") }

sub load_schema_sql {
    my $self = shift;
    my ($dbh, $sql) = @_;
    $dbh->do($_) or die "Error loading schema" for split /;/, $sql;
}

# sqlite does not have actual UUID type, using type 'UUID' just stores it with
# string affinity. Returning empty here will result in BINARY(16) type being
# used.
sub supports_uuid { () }
sub supports_datetime { 'DATETIME(6)' }
sub supports_async  { 0 }

sub supports_json {
    my $self = shift;
    my ($dbh) = @_;

    return 'JSONB' unless $dbh;

    my $ver = $self->db_version($dbh);

    my ($maj, $min) = split /\./, $ver;
    return 'JSONB' if $maj > 3 || ($maj == 3 && $min >= 45);

    return ();
}

sub serial_type { 'INTEGER' }

my %NORMALIZED_TYPES = (
    INT          => 'INTEGER',
    BYTEA        => 'BLOB',
    BIGINTEGER   => 'BIGINT',
    SMALLINTEGER => 'SMALLINT',
    TINYINTEGER  => 'TINYINT',
    SERIAL       => 'INTEGER',
    BIGSERIAL    => 'BIGINT',
    SMALLSERIAL  => 'SMALLINT',
    TINYSERIAL   => 'TINYINT',
);

sub normalize_sql_type {
    my $self = shift;
    my ($type, %params) = @_;

    $type = uc($type);
    return $NORMALIZED_TYPES{$type} // $type;
}

sub tables {
    my $self = shift;
    my ($dbh, %params) = @_;

    my @queries = (
        "SELECT name, type, 0 FROM sqlite_schema      WHERE type IN ('table', 'view')",
        "SELECT name, type, 1 FROM sqlite_temp_schema WHERE type IN ('table', 'view')",
    );

    my @out;

    for my $q (@queries) {
        my $sth = $dbh->prepare($q);
        $sth->execute();

        while (my ($table, $type, $temp) = $sth->fetchrow_array) {
            next if $table =~ m/^sqlite_/;

            if ($params{details}) {
                push @out => {name => $table, type => $type, temp => $temp};
            }
            else {
                push @out => $table;
            }
        }
    }

    return @out;
}

sub table {
    my $self = shift;
    my ($dbh, $name, %params) = @_;

    my @queries = (
        "SELECT name, type, 0 FROM sqlite_schema      WHERE type IN ('table', 'view') AND name = ?",
        "SELECT name, type, 1 FROM sqlite_temp_schema WHERE type IN ('table', 'view') AND name = ?",
    );

    my @out;

    for my $q (@queries) {
        my $sth = $dbh->prepare($q);
        $sth->execute($name);

        while (my ($table, $type, $temp) = $sth->fetchrow_array) {
            return {name => $table, type => $type, temp => $temp};
        }
    }
}

sub indexes {
    my $self = shift;
    my ($dbh, $table) = @_;

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
        my $idx = $out{$name} //= {name => $name, unique => $u ? 1 : 0, columns => []};
        push @{$idx->{columns}} => $col;
    }

    if (my @pk = $self->_primary_key($dbh, $table)) {
        $out{':pk'} = {name => ':pk', unique => 1, columns => \@pk};
    }

    return values %out;
}

sub column_type {
    my $self = shift;
    my ($dbh, $cache, $table, $column) = @_;

    croak "A table name is required" unless $table;
    croak "A column name is required" unless $column;

    return $cache->{$table}->{$column} if $cache->{$table}->{$column};

    my $sth = $dbh->prepare("SELECT type FROM pragma_table_info(?) WHERE name = ?");
    $sth->execute($table, $column);

    my ($sql_type) = $sth->fetchrow_array;
    my $data_type = $sql_type;
    $data_type =~ s/\(.*$//;

    my $is_dt = $self->_is_datetime($sql_type) // $self->_is_datetime($data_type);

    return $cache->{$table}->{$column} = {data_type => $data_type, sql_type => $sql_type, name => $column, is_datetime => $is_dt};
}

my %_IS_DATETIME = (
    date        => 1,
    datetime    => 1,
    time        => 1,
    timestamp   => 1,
    timestamptz => 1,
    year        => 1,
);

sub _is_datetime {
    my $self = shift;
    my ($type) = @_;

    $type = lc($type);

    return 1 if $_IS_DATETIME{$type};
    return 1 if $type =~ m/(time|date|stamp|year)/i;
    return 0;
}

sub columns {
    my $self = shift;
    my ($dbh, $cache, $table) = @_;

    croak "A table name is required" unless $table;

    my $sth = $dbh->prepare("SELECT name, type AS sql_type FROM pragma_table_info(?)");

    $sth->execute($table);

    my @out;
    while (my $col = $sth->fetchrow_hashref) {
        $col->{data_type} = $col->{sql_type};
        $col->{data_type} =~ s/\(.*$//;
        $col->{is_datetime} = $self->_is_datetime($col->{sql_type}) // $self->_is_datetime($col->{data_type});
        $cache->{$table}->{$col->{name}} //= { %$col };
        push @out => $col;
    }

    return @out;
}

sub db_version {
    my $self = shift;
    my ($dbh) = @_;

    my $sth = $dbh->prepare("SELECT sqlite_version()");
    $sth->execute();

    my ($ver) = $sth->fetchrow_array;
    return $ver;
}

sub db_keys {
    my $self = shift;
    my ($dbh, $table) = @_;

    croak "A table name is required" unless $table;

    my %out;

    my $sth = $dbh->prepare(<<"    EOT");
        SELECT il.name AS grp,
               origin  AS type,
               ii.name AS column
         FROM pragma_index_list(?)       AS il,
              pragma_index_info(il.name) AS ii
     ORDER BY seq, il.name, seqno, cid
    EOT

    $sth->execute($table);

    my %index;
    while (my $row = $sth->fetchrow_hashref()) {
        my $idx = $index{$row->{grp}} //= {};
        $idx->{type} = $row->{type};
        push @{$idx->{cols} //= []} => $row->{column};
    }

    for my $idx (values %index) {
        push @{$out{unique} //= []} => $idx->{cols};
        $out{pk} = $idx->{cols} if $idx->{type} eq 'pk';
    }

    unless ($out{pk} && @{$out{pk}}) {
        my @found = $self->_primary_key($dbh, $table);

        if (@found) {
            $out{pk} = \@found;
            push @{$out{unique} //= []} => \@found;
        }
        else {
            delete $out{pk};
        }
    }

    %index = ();
    $sth = $dbh->prepare("SELECT `id`, `table`, `from`, `to` FROM pragma_foreign_key_list(?) order by id, seq");
    $sth->execute($table);
    while (my $row = $sth->fetchrow_hashref()) {
        my $idx = $index{$row->{id}} //= {};

        push @{$idx->{columns} //= []} => $row->{from};

        $idx->{foreign_table} //= $row->{table};
        push @{$idx->{foreign_columns} //= []} => $row->{to};
    }

    $out{fk} = [values %index] if keys %index;

    return \%out;
}

sub _primary_key {
    my $self = shift;
    my ($dbh, $table) = @_;

    my $sth = $dbh->prepare("SELECT name FROM pragma_table_info(?) WHERE pk > 0 ORDER BY pk ASC");
    $sth->execute($table);

    my @out;
    while (my $row = $sth->fetchrow_hashref()) {
        push @out => $row->{name};
    }

    return @out;
}

sub generate_schema_sql_column_serial {
    my $class_or_self = shift;
    my %params        = @_;

    my $col = $params{column};

    return unless $col->serial;
    return 'PRIMARY KEY AUTOINCREMENT';
}

sub generate_schema_sql_primary_key {
    my $class_or_self = shift;
    my %params        = @_;
    my $key           = $params{key};
    my $cols          = $params{columns};

    return unless $key && @$key;

    if (@$key == 1) {
        my ($key_col) = grep { $_->{name} eq $key->[0] } @$cols;
        return if $key_col->serial;
    }

    return "PRIMARY KEY(" . join(', ' => @$key) . ")";
}

sub dsn {
    my $self = shift;
    return $self->{+DSN} if $self->{+DSN};

    my $driver = $self->dbi_driver;
    $driver =~ s/^DBD:://;

    my $db_name = $self->db_name;

    my $dsn = "dbi:${driver}:dbname=${db_name}";

    return $self->{+DSN} = $dsn;
}


1;
