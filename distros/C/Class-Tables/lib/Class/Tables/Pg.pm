package Class::Tables::Pg;
use vars '$VERSION';
$VERSION = "0.28";

sub map_tables {
    my ($self, $dbh) = @_;

    my (@tables, %map);

    my $q = $dbh->prepare("select tablename from pg_tables where schemaname='public'");
    $q->execute or die "Error listing tables";

    while ( my ($table) = $q->fetchrow_array ) {
        push @tables, $table;
    }
    $q->finish;

    for my $table (@tables) {
        $q = $dbh->prepare(q{
            SELECT a.attnum, a.attname AS field, t.typname AS type,
                   a.attlen AS length, a.atttypmod AS lengthvar,
                   a.attnotnull AS notnull
            FROM pg_class c, pg_attribute a, pg_type t
            WHERE c.relname = ? and a.attnum > 0
                  and a.attrelid = c.oid and a.atttypid = t.oid
                ORDER BY a.attnum
        });
        $q->execute($table) or die "Error describing table $table";
            
        while ( my $hr = $q->fetchrow_hashref ) {
            my ($col, $type) = @$hr{qw/field type/};

            $map{$table}{cols}{$col} = { primary => 0, type => $type };
            push @{ $map{$table}{col_order} }, $col;
        }
        $q->finish;
    }

    return \%map;
}

sub insert_id {
    my ($class, $dbh, $table, $id_col) = @_;

#    return $dbh->{pg_oid_status} if $id_col eq 'oid';
    
    my $sth = $dbh->prepare("select currval('${table}_${id_col}_seq')");
    $sth->execute;
    
    my ($id) = $sth->fetchrow_array;
    $sth->finish;
    return $id;
}

1;
