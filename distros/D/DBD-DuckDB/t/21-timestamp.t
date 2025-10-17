#perl -T

use strict;
use warnings;

use Test::More;
use Time::Piece;

use lib 't/lib';
use DuckDBTest;

my $dbh = connect_ok;


SCOPE: {

    my $sql = <<'END_SQL';
SELECT
    timezone('America/Denver', TIMESTAMP '2001-02-16 20:38:40') AS aware1,
    timezone('America/Denver', TIMESTAMPTZ '2001-02-16 04:38:40') AS naive1,
    timezone('UTC', TIMESTAMP '2001-02-16 20:38:40+00:00') AS aware2,
    timezone('UTC', TIMESTAMPTZ '2001-02-16 04:38:40 Europe/Berlin') AS naive2
END_SQL

    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my $row = $sth->fetchrow_hashref;

TODO: {

        local $TODO = 'Fail in CI';

        is $row->{aware1}, '2001-02-17T04:38:40';
        is $row->{naive1}, '2001-02-15T20:38:40';
        is $row->{aware2}, '2001-02-16T21:38:40';
        is $row->{naive2}, '2001-02-16T03:38:40';
    }

}


SCOPE: {

    my $sth = $dbh->prepare(q{SELECT '-infinity'::TIMESTAMP, 'epoch'::TIMESTAMP, 'infinity'::TIMESTAMP;});
    $sth->execute;

    my $row = $sth->fetchrow_arrayref;

    is $row->[0], gmtime(-9223372036854)->datetime, '-infinity';
    is $row->[1], gmtime(0)->datetime,              'epoch';
    is $row->[2], gmtime(9223372036854)->datetime,  'infinity';

}

done_testing;
