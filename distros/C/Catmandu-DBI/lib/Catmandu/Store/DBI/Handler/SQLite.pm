package Catmandu::Store::DBI::Handler::SQLite;

use Catmandu::Sane;
use Moo;
use namespace::clean;

our $VERSION = "0.0511";

with 'Catmandu::Store::DBI::Handler';

sub _column_sql {
    my ($self, $map,$bag) = @_;
    my $col = $map->{column};
    my $dbh = $bag->store->dbh;
    my $sql = $dbh->quote_identifier($col)." ";
    if ($map->{type} eq 'string') {
        $sql .= 'TEXT';
    } elsif ($map->{type} eq 'integer') {
        $sql .= 'INTEGER';
    } elsif ($map->{type} eq 'binary') {
        $sql .= 'BLOB';
    } elsif ($map->{type} eq 'datetime') {
        $sql .= 'TEXT';
    }
    if ($map->{unique}) {
        $sql .= " UNIQUE";
    }
    if ($map->{required}) {
        $sql .= " NOT NULL";
    }
    $sql;
}

sub create_table {
    my ($self, $bag) = @_;
    my $mapping = $bag->mapping;
    my $dbh = $bag->store->dbh;
    my $name = $bag->name;
    my $q_name = $dbh->quote_identifier($name);

    my $sql = "CREATE TABLE IF NOT EXISTS $q_name(".
        join(',', map { $self->_column_sql($_,$bag) } values %$mapping).")";

    $dbh->do($sql)
        or Catmandu::Error->throw($dbh->errstr);

    for my $map (values %$mapping) {
        next if $map->{unique} || !$map->{index};
        my $col = $map->{column};
        my $q_col = $dbh->quote_identifier($col);
        my $q_idx = $dbh->quote_identifier("${name}_${col}_idx");
        my $idx_sql = "CREATE INDEX IF NOT EXISTS ${q_idx} ON $q_name($q_col)";
        $dbh->do($idx_sql)
            or Catmandu::Error->throw($dbh->errstr);
    }
}

sub add_row {
    my ($self, $bag, $row) = @_;
    my $dbh = $bag->store->dbh;
    my @cols = keys %$row;
    my @q_cols = map { $dbh->quote_identifier($_) } @cols;
    my @values = values %$row;
    my $q_name = $dbh->quote_identifier($bag->name);
    my $sql = "INSERT OR REPLACE INTO $q_name(".
        join(',', @q_cols).") VALUES(".join(',', ('?') x @cols).")";

    my $sth = $dbh->prepare_cached($sql)
        or Catmandu::Error->throw($dbh->errstr);
    $sth->execute(@values) or Catmandu::Error->throw($sth->errstr);
    $sth->finish;
}

1;

