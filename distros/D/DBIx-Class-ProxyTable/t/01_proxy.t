use strict;
use warnings;
use Test::Declare;

use lib './t';
use ProxyTest;

plan tests => blocks;

{
    my $sql = q{
        CREATE TABLE log (
            id     INT,
            body   TEXT
        );
    };
    my $db_file = '/tmp/dbic_proxy_test.db';

    my $schema;
    sub _connect {
        $schema = ProxyTest->connect("dbi:SQLite:$db_file");
    }
    sub setup_database {
        _connect;
        $schema->storage->dbh->do($sql);
    }
    sub drop_database {
        unlink $db_file;
    }
    sub _rs {
        $schema->resultset('Log');
    }
    sub _get_data {
        my $log = shift;
        my %expected_data = map { $_ => $log->get_column($_) } $log->columns;
        return \%expected_data;
    }
    sub insert_data {
        my $log = _rs->proxy(shift)->create(shift);
        return _get_data($log);
    }
    sub expected {
        my $log = _rs->proxy(shift)->single;
        return _get_data($log);
    }
}

describe 'proxy test' => run {
    init {
        setup_database;
    };
    test 'insert to log2 table?' => run {
        is_deeply insert_data( log2 => { id => 1  , body => 'foo' }), expected('log2');
    };
    test 'insert to log3 table?' => run {
        is_deeply insert_data( log3 => { id => 100, body => 'bar' }), expected('log3');
    };
    cleanup {
        drop_database;
    };
};

