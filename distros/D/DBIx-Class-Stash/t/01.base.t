use strict;
use warnings;
use Test::Declare;

use lib './t';
use StashTest;

plan tests => blocks;

{
    my $schema;
    sub _connect {
        $schema ||= StashTest->connect('dbi:SQLite:');
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
                body   TEXT
            );
        });
    }
}

describe 'stash test' => run {
    init {
        setup_database;
    };
    test 'set stash data to schema' => run {
        _schema->stash->{stash1} = 'set to schema';
        is _schema->stash->{stash1}, 'set to schema';
        is _rs->stash->{stash1}, 'set to schema';
    };
    test 'set stash data to rs' => run {
        _rs->stash->{stash2} = 'set to rs';
        is _rs->stash->{stash2}, 'set to rs';
        is _schema->stash->{stash2}, 'set to rs';
    };
};
