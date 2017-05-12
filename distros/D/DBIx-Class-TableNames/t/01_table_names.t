use strict;
use warnings;
use Test::Declare;

use lib './t';
use TableNamesTest;

plan tests => blocks;

{
    my $table_base = q{
        CREATE TABLE __TABLE_NAME__ (
            id     INT,
            body   TEXT
        );
    };
    my $schema;
    my $db_file = '/tmp/dbic_table_names_test.db';
    sub _connect {
        $schema = TableNamesTest->connect("dbi:SQLite:$db_file");
    }
    sub setup_database {
        _connect;
        for my $table_name ( qw/foo bar/ ) {
            (my $create_table = $table_base) =~ s/__TABLE_NAME__/$table_name/;
            $schema->storage->dbh->do($create_table);
        }
    }
    sub drop_database {
        unlink $db_file;
    }
    sub table_names {
        my @tables = $schema->table_names(shift);
        return \@tables;
    }
}
describe 'TableNames test' => run {
    init {
        setup_database;
    };
    test 'no specification' => run {
        is_deeply table_names , [qw/bar foo/];
    };
    test 'specific table name' => run {
        is_deeply table_names('foo'), [qw/foo/];
    };
    test 'like case' => run {
        is_deeply table_names('f%'), [qw/foo/];
    };
    cleanup {
        drop_database;
    }
};

