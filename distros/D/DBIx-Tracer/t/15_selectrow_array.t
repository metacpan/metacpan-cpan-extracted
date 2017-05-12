use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More;
use t::Util;
use DBIx::Tracer;

my $dbh = t::Util->new_dbh;

for my $method (qw/selectrow_array selectrow_arrayref selectall_arrayref/) {
    subtest $method => sub {
        my @res = capture {
            $dbh->$method(
                'SELECT * FROM sqlite_master WHERE name = ?', undef, 'foo',
            );
        };

        is 0+@res, 1;
        like $res[0]->{sql}, qr/SELECT \* FROM sqlite_master WHERE name = ?/, 'SQL';
        is_deeply $res[0]->{bind_params}, ['foo'], 'SQL';
        done_testing;
    };
}

done_testing;
