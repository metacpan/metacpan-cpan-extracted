use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More;
use t::Util;
use DBIx::QueryLog;

DBIx::QueryLog->compact(1);
DBIx::QueryLog->useqq(1);

my $dbh = t::Util->new_dbh;
my $res = capture {
    $dbh->do("    SELECT     *  FROM \n   sqlite_master WHERE type = '\\0' \r   ");
};

like $res, qr/SELECT \* FROM sqlite_master WHERE type = '\\\\0'/, 'sql ok';

done_testing;
