use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More 0.96;
use t::Util;
use DBIx::Tracer;

my $dbh = t::Util->new_dbh;

subtest 'simple' => sub {
    my @res = capture {
        $dbh->do('SELECT * FROM sqlite_master WHERE name = ?', undef, 'foo');
    };

    is 0+@res, 1;
    like $res[0]->{sql}, qr/SELECT \* FROM sqlite_master WHERE name = \?/, 'SQL';
};

subtest 'bind_param' => sub {
    my @res = capture {
        my $sth = $dbh->prepare('SELECT * FROM sqlite_master WHERE name = ?');
        $sth->bind_param(1, 'foo');
        $sth->execute;
    };

    is 0+@res, 1 or die "WTF";
    like $res[0]->{sql}, qr/SELECT \* FROM sqlite_master WHERE name = \?/, 'SQL';
    is_deeply $res[0]->{bind_params}, ['foo'], 'SQL';
};

done_testing;
