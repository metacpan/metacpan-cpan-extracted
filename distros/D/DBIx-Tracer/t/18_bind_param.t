use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More;
use t::Util;
use DBIx::Tracer;

my $dbh = t::Util->new_dbh;

my @res = capture {
    my $sth = $dbh->prepare('SELECT * FROM sqlite_master WHERE name = ? OR name = ?');
    $sth->bind_param(1, 'foo');
    $sth->bind_param(2, 'hoge');
    $sth->execute;
};

is(0+@res, 1);
like $res[0]->{sql}, qr/SELECT \* FROM sqlite_master WHERE name = \? OR name = \?/, 'SQL';
is_deeply $res[0]->{bind_params}, ['foo', 'hoge'];

done_testing;
