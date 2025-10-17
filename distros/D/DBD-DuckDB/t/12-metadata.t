#perl -T

use strict;
use warnings;

use Test::More;
use lib 't/lib';
use DuckDBTest;

my $dbh = connect_ok;

for (my $i = 1; $i < 10; $i++) {
    ok $dbh->do("CREATE TABLE t$i (i INTEGER PRIMARY KEY, v VARCHAR)") == 0, "Create table #$i";
}

SCOPE: {
    my $table_info = $dbh->table_info;
    my @table_info = ();
    my @tables     = $dbh->tables;

    while (my $row = $table_info->fetchrow_hashref) {
        push @table_info, $dbh->quote_identifier($row->{TABLE_CAT}, $row->{TABLE_SCHEM}, $row->{TABLE_NAME});
    }

    is_deeply \@table_info, \@tables, 'Tables';
}

SCOPE: {
    my $primary_keys = $dbh->primary_key_info(undef, undef, 't1');
    my @primary_keys = $dbh->primary_key(undef, undef, 't1');
    my $row          = $primary_keys->fetchrow_hashref;

    is $row->{COLUMN_NAME}, 'i', 'Primary key';
    is_deeply @primary_keys, ('i');
}

done_testing;
