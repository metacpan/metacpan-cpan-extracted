package Util;
use strict;
use warnings;
use DBI;

sub prepare {
    my ($package, $mysqld) = @_;

    my $dbh = DBI->connect( $mysqld->dsn )
        or die $DBI::errstr;

    my $create_table = 'CREATE TABLE t1 (user_id INTEGER UNSIGNED NOT NULL)';
    $dbh->do( $create_table );

    my $insert = 'INSERT t1 VALUES (1)';
    $dbh->do( $insert );
}

1;
