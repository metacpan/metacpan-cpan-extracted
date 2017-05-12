use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More;
use t::Util;
use DBIx::QueryLog;

my $dbh = t::Util->new_dbh;

my $res = capture {
    my $sth = $dbh->prepare('SELECT * FROM sqlite_master WHERE name = ? OR name = ?');
    $sth->bind_param(1, 'foo');
    $sth->bind_param(2, 'hoge');
    $sth->execute;
};

like $res, qr/SELECT \* FROM sqlite_master WHERE name = 'foo' OR name = 'hoge'/, 'SQL';

done_testing;
