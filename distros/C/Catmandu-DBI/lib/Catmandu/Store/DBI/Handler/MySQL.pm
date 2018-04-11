package Catmandu::Store::DBI::Handler::MySQL;

use Catmandu::Sane;
use Moo;
use namespace::clean;

our $VERSION = "0.0702";

with 'Catmandu::Store::DBI::Handler';

# text types are case-insensitive in MySQL
sub _column_sql {
    my ($self, $map, $bag) = @_;
    my $col = $map->{column};
    my $dbh = $bag->store->dbh;
    my $sql = $dbh->quote_identifier($col) . " ";
    if ($map->{type} eq 'string' && $map->{unique}) {
        $sql .= 'VARCHAR(255) BINARY';
    }
    elsif ($map->{type} eq 'string') {
        $sql .= 'TEXT BINARY';
    }
    elsif ($map->{type} eq 'integer') {
        $sql .= 'INTEGER';
    }
    elsif ($map->{type} eq 'binary') {
        $sql .= 'LONGBLOB';
    }
    elsif ($map->{type} eq 'datetime') {
        $sql .= 'DATETIME';
    }
    elsif ($map->{type} eq 'datetime_milli') {
        if ($dbh->{mysql_clientversion} < 50640) {
            Catmandu::NotImplemented->throw(
                "DATETIME(3) only for MySQL > 5.6.4");
        }
        $sql .= 'DATETIME(3)';
    }
    if ($map->{unique}) {
        $sql .= " UNIQUE";
    }
    if ($map->{required}) {
        $sql .= " NOT NULL";
    }
    if (!$map->{unique} && $map->{index}) {
        if ($map->{type} eq 'string') {
            $sql .= ", INDEX($col(255))";
        }
        else {
            $sql .= ", INDEX($col)";
        }
    }
    $sql;
}

sub create_table {
    my ($self, $bag) = @_;
    my $mapping = $bag->mapping;
    my $dbh     = $bag->store->dbh;
    my $q_name  = $dbh->quote_identifier($bag->name);
    my $sql
        = "CREATE TABLE IF NOT EXISTS $q_name("
        . join(',', map {$self->_column_sql($_, $bag)} values %$mapping)
        . ")";
    $dbh->do($sql) or Catmandu::Error->throw($dbh->errstr);
}

sub add_row {
    my ($self, $bag, $row) = @_;
    my $dbh    = $bag->store->dbh;
    my @cols   = keys %$row;
    my @q_cols = map {$dbh->quote_identifier($_)} @cols;
    my @vals   = values %$row;
    my $q_name = $dbh->quote_identifier($bag->name);
    my $sql
        = "INSERT INTO $q_name("
        . join(',', @q_cols)
        . ") VALUES("
        . join(',', ('?') x @q_cols)
        . ") ON DUPLICATE KEY UPDATE "
        . join(',', map {"$_=VALUES($_)"} @q_cols);

    my $sth = $dbh->prepare_cached($sql)
        or Catmandu::Error->throw($dbh->errstr);
    $sth->execute(@vals) or Catmandu::Error->throw($sth->errstr);
    $sth->finish;
}

1;
