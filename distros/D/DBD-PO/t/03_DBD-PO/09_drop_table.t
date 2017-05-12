#!perl
#!perl -T

use strict;
use warnings;

use Test::DBD::PO::Defaults qw(
    $PATH $TRACE $DROP_TABLE
    trace_file_name
    $TABLE_0X $FILE_0X
);
use Test::More tests => 4 + 1;
use Test::NoWarnings;

BEGIN {
    require_ok('DBI');
}

my $dbh;

# connext
{
    $dbh = DBI->connect(
        "dbi:PO:f_dir=$PATH;po_charset=utf-8",
        undef,
        undef,
        {
            RaiseError => 1,
            PrintError => 0,
            AutoCommit => 1,
        },
    );
    isa_ok($dbh, 'DBI::db', 'connect');

    if ($TRACE) {
        open my $file, '>', trace_file_name();
        $dbh->trace(4, $file);
    }
}

# drop table
SKIP: {
    skip('drop table', 2)
        if ! $DROP_TABLE;

    my $result = $dbh->do(<<"EO_SQL");
        DROP TABLE $TABLE_0X
EO_SQL
    is($result, '-1', 'drop table');
    ok(! -e $FILE_0X, 'table file deleted');
}
