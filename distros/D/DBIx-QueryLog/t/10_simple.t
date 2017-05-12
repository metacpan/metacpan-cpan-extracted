use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More;
use t::Util;
use DBIx::QueryLog;

my $dbh = t::Util->new_dbh;

my $res = capture {
    $dbh->do('SELECT * FROM sqlite_master');
};

like $res, qr/SELECT \* FROM sqlite_master/, 'SQL';

done_testing;
