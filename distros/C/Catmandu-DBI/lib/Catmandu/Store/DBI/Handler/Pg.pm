package Catmandu::Store::DBI::Handler::Pg;

use Catmandu::Sane;
use DBD::Pg ();
use Moo;
use namespace::clean;

our $VERSION = "0.0701";

with 'Catmandu::Store::DBI::Handler';

sub _column_sql {
    my ($self, $map, $bag) = @_;
    my $col = $map->{column};
    my $dbh = $bag->store->dbh;
    my $sql = $dbh->quote_identifier($col) . " ";
    if ($map->{type} eq 'string') {
        $sql .= 'TEXT';
    }
    elsif ($map->{type} eq 'integer') {
        $sql .= 'INTEGER';
    }
    elsif ($map->{type} eq 'binary') {
        $sql .= 'BYTEA';
    }
    elsif ($map->{type} eq 'datetime') {
        $sql .= 'TIMESTAMP(0)';
    }
    elsif ($map->{type} eq 'datetime_milli') {
        $sql .= 'TIMESTAMP(3)';
    }
    if ($map->{array}) {
        $sql .= '[]';
    }
    if ($map->{unique}) {
        $sql .= " UNIQUE";
    }
    if ($map->{required}) {
        $sql .= " NOT NULL";
    }
    $sql;
}

sub _create_index_sql {
    my ($self, $bag, $map) = @_;
    my $name  = $bag->name;
    my $col   = $map->{column};
    my $dbh   = $bag->store->dbh;
    my $q_col = $dbh->quote_identifier($col);
    my $sql   = <<SQL;
DO \$\$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = '${name}_${col}_idx'
    AND    n.nspname = 'public'
    ) THEN

    CREATE INDEX ${name}_${col}_idx ON public.${name} (${q_col});
END IF;

END\$\$;
SQL
}

sub create_table {
    my ($self, $bag) = @_;
    my $mapping = $bag->mapping;
    my $name    = $bag->name;
    my $dbh     = $bag->store->dbh;
    my $q_name  = $dbh->quote_identifier($name);

    my $sql
        = "CREATE TABLE IF NOT EXISTS $q_name("
        . join(',', map {$self->_column_sql($_, $bag)} values %$mapping)
        . ");";

    for my $map (values %$mapping) {
        next if $map->{unique} || !$map->{index};
        $sql .= $self->_create_index_sql($bag, $map);
    }

    local $SIG{__WARN__} = sub {
        my $msg = $_[0];
        if ($msg !~ /^NOTICE:  relation "$name" already exists/) {
            warn $msg;
        }
    };
    $dbh->do($sql) or Catmandu::Error->throw($dbh->errstr);
}

# see
# http://stackoverflow.com/questions/15840922/where-not-exists-in-postgresql-gives-syntax-error
# and
# https://rt.cpan.org/Public/Bug/Display.html?id=13180
sub add_row {
    my ($self, $bag, $row) = @_;
    my $mapping  = $bag->mapping;
    my $dbh      = $bag->store->dbh;
    my $id_col   = $mapping->{_id}{column};
    my $q_id_col = $dbh->quote_identifier($id_col);
    my %binary_cols;
    for my $map (values %$mapping) {
        $binary_cols{$map->{column}} = 1 if $map->{type} eq 'binary';
    }
    my $id     = $row->{$id_col};
    my @cols   = keys %$row;
    my @q_cols = map {$dbh->quote_identifier($_)} @cols;
    my @vals   = values %$row;
    my $name   = $bag->name;
    my $q_name = $dbh->quote_identifier($name);
    my $insert_sql
        = "INSERT INTO $q_name("
        . join(',', @q_cols)
        . ") SELECT "
        . join(',', ('?') x @cols)
        . " WHERE NOT EXISTS (SELECT 1 FROM $q_name WHERE $q_id_col=?)";
    my $update_sql
        = "UPDATE $q_name SET "
        . join(',', map {"$_=?"} @q_cols)
        . " WHERE $q_id_col=?";

    my $sth = $dbh->prepare_cached($update_sql)
        or Catmandu::Error->throw($dbh->errstr);
    my $i = 0;
    for (; $i < @cols; $i++) {
        my $col = $cols[$i];
        my $val = $vals[$i];
        if ($binary_cols{$col}) {
            $sth->bind_param($i + 1, $val, {pg_type => DBD::Pg->PG_BYTEA});
        }
        else {
            $sth->bind_param($i + 1, $val);
        }
    }
    $sth->bind_param($i + 1, $id);
    $sth->execute or Catmandu::Error->throw($sth->errstr);

    unless ($sth->rows) {
        $sth->finish;
        $sth = $dbh->prepare_cached($insert_sql)
            or Catmandu::Error->throw($dbh->errstr);
        my $i = 0;
        for (; $i < @cols; $i++) {
            my $col = $cols[$i];
            my $val = $vals[$i];
            if ($binary_cols{$col}) {
                $sth->bind_param($i + 1, $val,
                    {pg_type => DBD::Pg->PG_BYTEA});
            }
            else {
                $sth->bind_param($i + 1, $val);
            }
        }
        $sth->bind_param($i + 1, $id);
        $sth->execute or Catmandu::Error->throw($sth->errstr);
    }
    $sth->finish;
}

1;
