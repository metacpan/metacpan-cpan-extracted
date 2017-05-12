use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More;
use t::Util;
use DBIx::QueryLog;

my $dbh = t::Util->new_dbh;

for my $method (qw/selectrow_array selectrow_arrayref selectall_arrayref/) {
    subtest $method => sub {
        my $res = capture {
            $dbh->$method(
                'SELECT * FROM sqlite_master WHERE name = ?', undef, 'foo',
            );
        };

        like $res, qr/SELECT \* FROM sqlite_master WHERE name = 'foo'/, 'SQL';
        done_testing;
    };
}

done_testing;
