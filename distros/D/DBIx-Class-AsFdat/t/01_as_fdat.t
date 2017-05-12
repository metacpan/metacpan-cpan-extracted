use strict;
use warnings;
use Test::Declare;

use lib './t';
use FdatTest;

plan tests => blocks;

{
    my $schema;
    sub _connect {
        $schema ||= FdatTest->connect('dbi:SQLite:');
        $schema;
    }
    sub _schema {
        _connect
    }
    sub _rs {
        _schema->resultset('Foo');
    }
    sub setup_database {
        _schema->storage->dbh->do(q{
            CREATE TABLE foo (
                id     INT,
                body   TEXT,
                date   TEXT
            );
        });
    }
}

describe 'as_fdat test' => run {
    init {
        setup_database;
        _rs->create(
            {
                id   => 1,
                body => 'as_fdat_test',
                date => '2008-11-10',
            }
        );
    };
    test 'set stash data to schema' => run {
        my $fdat = _rs->single->as_fdat;
        my $datetime = delete $fdat->{date};

        isa_ok $datetime, 'DateTime';
        is_deeply $fdat, +{
            id          => 1,
            body        => 'as_fdat_test',
            date_year   => 2008,
            date_month  => 11,
            date_day    => 10,
            date_hour   => 0,
            date_minute => 0,
            date_second => 0,
        };
    };
};

