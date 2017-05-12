package Class::Tables::SQLite;
use vars '$VERSION';
$VERSION = "0.28";

sub map_tables {
    my ($self, $dbh) = @_;

    my (@tables, %map);

    my $q = $dbh->prepare("select name from sqlite_master where type='table'");
    $q->execute or die "Error listing tables";
        
    while ( my ($table) = $q->fetchrow_array ) {
        push @tables, $table;
    }
    $q->finish;

    for my $table (@tables) {
        $q = $dbh->prepare_cached("pragma table_info(?)");
        $q->execute($table) or die "Error describing table $table";

        my $seen_pk;

        while ( my $ar = $q->fetchrow_arrayref ) {
            my ($col, $type, $primary) = @$ar[1,2,5];

            $seen_pk ||= $primary;
            
            $map{$table}{cols}{$col} = { type => $type, primary => $primary };
            push @{ $map{$table}{col_order} }, $col;
        }
        $q->finish;
        
        if (not $seen_pk) {
            $map{$table}{cols}{"rowid"} = { type => "int", primary => 1 };
            push @{ $map{$table}{col_order} }, "rowid";
        }

    }

    return \%map;    
}

sub insert_id {
    my ($class, $dbh) = @_;
    $dbh->func('last_insert_rowid');
}

1;
