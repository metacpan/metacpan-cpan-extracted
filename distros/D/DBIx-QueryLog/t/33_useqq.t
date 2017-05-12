use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More;
use t::Util;
use DBIx::QueryLog;

DBIx::QueryLog->useqq(1);

my $dbh = t::Util->new_dbh;
my $res = capture {
    $dbh->do("SELECT * FROM \t sqlite_master\r\n");
};

note $res;
my $expects = quotemeta q{"SELECT * FROM \t sqlite_master\r\n"};
like $res, qr/$expects/, 'sql ok';

done_testing;
