use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More;
use t::Util;
use DBIx::Tracer;

my $dbh = t::Util->new_dbh;

my @res = capture {
    $dbh->do('SELECT * FROM sqlite_master WHERE name = ?', undef, 'foo');
};

is 0+@res, 1;
like $res[0]->{sql}, qr/SELECT \* FROM sqlite_master WHERE name = \?/, 'SQL';
is_deeply $res[0]->{bind_params}, ['foo'], 'bind';

done_testing;
