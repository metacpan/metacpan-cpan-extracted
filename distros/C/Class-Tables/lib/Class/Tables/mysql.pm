package Class::Tables::mysql;
use vars '$VERSION';
$VERSION = "0.28";

sub map_tables {
    my ($self, $dbh) = @_;

    my (@tables, %map);

    my $q = $dbh->prepare("show tables");
    $q->execute or die "Error listing tables";
        
    while ( my ($table) = $q->fetchrow_array ) {
        push @tables, $table;
    }
    $q->finish;

    for my $table (@tables) {
        $q = $dbh->prepare("describe $table");
        $q->execute or die "Error describing table $table";
            
        while ( my $hr = $q->fetchrow_hashref ) {
            my ($col, $type) = @$hr{qw/Field Type/};

            my $primary = $hr->{Key} eq "PRI" ? 1 : 0;
            
            $map{$table}{cols}{$col} = { type => $type, primary => $primary };
            push @{ $map{$table}{col_order} }, $col;
        }
        $q->finish;
    }

    return \%map;
}

sub insert_id {
    my ($class, $dbh) = @_;
    $dbh->{mysql_insertid};
}

1;
